import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/debug/safe_debug_log.dart';
import '../../../core/errors/either.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_request.dart';
import '../../../core/security/secure_session_secret_store.dart';
import '../domain/google_identity.dart';
import '../domain/student_session_repository.dart';
import '../domain/student_registration.dart';
import '../domain/student_learning.dart';
import 'firebase_identity_proof.dart';

/// Coordinates the session exchange while keeping credentials out of UI state.
final class StudentSessionGateway implements StudentSessionRepository {
  StudentSessionGateway({
    required this._api,
    required this._proofSource,
    required Uri environment,
    required this._platform,
    Future<String?> Function()? androidDeviceId,
    this._storage = SecureSessionSecretStore.platformStorage,
  }) : _readAndroidDeviceId = androidDeviceId,
       _namespace = base64Url.encode(utf8.encode(environment.toString()));

  final ApiClient _api;
  final FirebaseIdentityProofSource _proofSource;
  final String _namespace;
  final String _platform;
  final FlutterSecureStorage _storage;
  final Future<String?> Function()? _readAndroidDeviceId;

  String get _deviceKey => 'device_v1_$_namespace';
  String _sessionKey(GoogleIdentity identity) =>
      'refresh_v1_${_namespace}_${base64Url.encode(utf8.encode(identity.firebaseUid))}';

  String? _access;
  String? _owner;

  @override
  Future<Either<StudentSessionFailure, StudentSession>> start(
    GoogleIdentity identity,
  ) => _capture(() async {
    if (_owner == identity.firebaseUid && _access != null) {
      return _read(identity);
    }
    if (await _refresh(identity)) return _read(identity);
    final deviceId = await _deviceBindingId();
    final proof = await _proofSource.prepareForBackend(
      expectedFirebaseUid: identity.firebaseUid,
    );
    await _accept(
      identity,
      await _api.send(
        ApiRequest(
          method: 'POST',
          path: 'auth/google',
          jsonBody: {
            'idToken': proof.idToken,
            'device': {'id': deviceId, 'platform': _platform},
          },
        ),
      ),
    );
    return _read(identity);
  });

  @override
  Future<Either<StudentSessionFailure, StudentSession?>> restore(
    GoogleIdentity identity,
  ) => _capture(() async {
    if (_owner == identity.firebaseUid && _access != null ||
        await _refresh(identity)) {
      return _read(identity);
    }
    return null;
  });

  Future<bool> _refresh(GoogleIdentity identity) async {
    _access = null;
    _owner = null;
    final key = _sessionKey(identity);
    final refresh = await _storage.read(key: key);
    if (refresh == null) return false;
    try {
      await _accept(
        identity,
        await _api.send(
          ApiRequest(
            method: 'POST',
            path: 'auth/refresh',
            jsonBody: {'refreshToken': refresh},
          ),
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      if (failure.code != 'INVALID_REFRESH_TOKEN' &&
          failure.code != 'SESSION_REVOKED') {
        rethrow;
      }
      await _storage.delete(key: key);
      return false;
    }
  }

  @override
  Future<Either<StudentSessionFailure, void>> end(GoogleIdentity identity) =>
      _capture(() async {
        _access = null;
        _owner = null;
        final key = _sessionKey(identity);
        final refresh = await _storage.read(key: key);
        await _storage.delete(key: key);
        if (refresh == null) return;
        try {
          await _revoke(refresh);
        } on ApiFailure catch (failure) {
          SafeDebugLog.event('Auth', 'remote logout failed', {
            'kind': failure.kind.name,
          });
        }
      });

  Future<void> _accept(GoogleIdentity identity, ApiResponse response) async {
    final data = response.json['data'];
    final access = data is Map ? data['accessToken'] : null;
    final refresh = data is Map ? data['refreshToken'] : null;
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.length < 20 ||
        refresh.length > 256) {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
    try {
      await _storage.write(key: _sessionKey(identity), value: refresh);
    } catch (_) {
      await _revoke(refresh);
      rethrow;
    }
    _owner = identity.firebaseUid;
    _access = access;
  }

  @override
  Future<Either<StudentSessionFailure, StudentSession>> read(
    GoogleIdentity identity,
  ) => _capture(() => _read(identity));

  Future<StudentSession> _read(GoogleIdentity identity) async {
    ApiResponse response;
    try {
      response = await _authorized(identity, 'GET', 'me/session-state');
    } on ApiFailure catch (failure) {
      if (failure.kind != ApiFailureKind.unauthenticated ||
          !await _refresh(identity)) {
        rethrow;
      }
      response = await _authorized(identity, 'GET', 'me/session-state');
    }
    final data = response.json['data'];
    if (data is! Map) throw const ApiFailure(ApiFailureKind.invalidResponse);
    final next = switch (data['next']) {
      'suspended' => StudentNextStep.suspended,
      'device_unauthorized' => StudentNextStep.deviceUnauthorized,
      'choose_usage_type' => StudentNextStep.chooseUsageType,
      'complete_basic_info' => StudentNextStep.completeBasicInfo,
      'complete_registration' => StudentNextStep.completeRegistration,
      'confirm_new_term' => StudentNextStep.confirmNewTerm,
      'home' => StudentNextStep.home,
      _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
    };
    final usageType = switch (data['usageType']) {
      null => null,
      'institute' => StudentUsageType.institute,
      'courses' => StudentUsageType.courses,
      _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
    };
    if (next == StudentNextStep.completeBasicInfo && usageType == null) {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
    return StudentSession(next: next, usageType: usageType);
  }

  @override
  Future<Either<StudentSessionFailure, StudentSession>> setUsageType(
    GoogleIdentity identity,
    StudentUsageType usageType,
  ) => _save(identity, 'me/usage-type', {'usageType': usageType.name});

  @override
  Future<Either<StudentSessionFailure, StudentSession>> setBasicInfo(
    GoogleIdentity identity, {
    required String officialName,
    required String phone,
  }) => _save(identity, 'me/basic-info', {
    'officialName': officialName,
    'phone': phone,
  });

  @override
  Future<Either<StudentSessionFailure, List<StudentDepartment>>> departments(
    GoogleIdentity identity,
  ) => _capture(() async {
    final result = await _authorized(identity, 'GET', 'academic/departments');
    final items = result.json['data'];
    if (items is! List) throw const ApiFailure(ApiFailureKind.invalidResponse);
    return List.unmodifiable(
      items
          .map((item) {
            if (item
                case {'id': String id, 'name': String name, 'years': List years}
                when id.isNotEmpty &&
                    name.isNotEmpty &&
                    years.isNotEmpty &&
                    years.every((year) => year is int && year > 0)) {
              return StudentDepartment(
                id,
                name,
                List<int>.unmodifiable(
                  studentProgramYears.where(years.contains),
                ),
              );
            }
            throw const ApiFailure(ApiFailureKind.invalidResponse);
          })
          .where((department) => department.years.isNotEmpty),
    );
  });

  @override
  Future<Either<StudentSessionFailure, StudentRegistrationSummary?>>
  registrationSummary(GoogleIdentity identity) => _capture(() async {
    try {
      final summary = await _registrationSummary(identity);
      return studentProgramYears.contains(summary.year) ? summary : null;
    } on ApiFailure catch (failure) {
      if (failure.code == 'INCOMPLETE_REGISTRATION' ||
          failure.code == 'ACADEMIC_INFO_INVALID') {
        return null;
      }
      rethrow;
    }
  });

  Future<StudentRegistrationSummary> _registrationSummary(
    GoogleIdentity identity,
  ) async {
    final response = await _authorized(
      identity,
      'GET',
      'me/registration-summary',
    );
    if (response.json['data'] case {
      'student': {'officialName': String name},
      'department': {'id': String departmentId, 'name': String departmentName},
      'year': int year,
      'semester': final semester,
    }) {
      final semesterName = switch (semester) {
        null => null,
        {'name': String value} => value,
        _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
      };
      return StudentRegistrationSummary(
        officialName: name,
        departmentId: departmentId,
        departmentName: departmentName,
        year: year,
        semesterName: semesterName,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentRegistrationSummary>>
  saveAcademicInfo(GoogleIdentity identity, String departmentId, int year) =>
      _capture(() async {
        if (!studentProgramYears.contains(year)) {
          throw const ApiFailure(ApiFailureKind.validation);
        }
        await _authorized(
          identity,
          'PUT',
          'me/academic-info',
          body: {'departmentId': departmentId, 'year': year},
        );
        return _registrationSummary(identity);
      });

  @override
  Future<Either<StudentSessionFailure, StudentSession>> confirmRegistration(
    GoogleIdentity identity,
  ) => _confirm(identity, 'me/registration/confirm');

  @override
  Future<Either<StudentSessionFailure, StudentSession>> confirmNewTerm(
    GoogleIdentity identity,
  ) => _confirm(identity, 'me/term-reregistration/confirm');

  Future<Either<StudentSessionFailure, StudentSession>> _confirm(
    GoogleIdentity identity,
    String path,
  ) => _capture(() async {
    try {
      await _authorized(identity, 'POST', path);
    } on ApiFailure catch (failure) {
      if (failure.kind != ApiFailureKind.unauthenticated &&
          failure.kind != ApiFailureKind.forbidden) {
        rethrow;
      }
    }
    return _read(identity);
  });

  @override
  Future<Either<StudentSessionFailure, StudentTermRegistration>>
  termRegistration(GoogleIdentity identity) =>
      _capture(() => _termRegistration(identity));

  Future<StudentTermRegistration> _termRegistration(
    GoogleIdentity identity,
  ) async {
    final response = await _authorized(
      identity,
      'GET',
      'me/term-reregistration',
    );
    if (response.json['data']
        case {
          'department': {'name': String departmentName},
          'year': int year,
          'semester': {
            'name': String semesterName,
            'startDate': String start,
            'endDate': String end,
          },
          'status': String status,
        }
        when status == 'pending' || status == 'change_requested') {
      final startDate = DateTime.tryParse(start);
      final endDate = DateTime.tryParse(end);
      if (startDate != null && endDate != null) {
        return StudentTermRegistration(
          departmentName: departmentName,
          year: year,
          semesterName: semesterName,
          startDate: startDate,
          endDate: endDate,
          changePending: status == 'change_requested',
        );
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentTermRegistration>>
  requestTermChange(GoogleIdentity identity, String description) =>
      _capture(() async {
        try {
          await _authorized(
            identity,
            'POST',
            'me/term-reregistration/change-request',
            body: {'description': description},
          );
        } on ApiFailure catch (failure) {
          if (failure.code != 'CHANGE_REQUEST_EXISTS') rethrow;
        }
        return _termRegistration(identity);
      });

  @override
  Future<Either<StudentSessionFailure, StudentHomeData>> home(
    GoogleIdentity identity,
  ) => _captureLearning(() async {
    final response = await _authorized(identity, 'GET', 'home');
    if (response.json['data'] case {
      'name': String name,
      'subjects': List subjects,
      'courses': List courses,
    }) {
      return (
        name: name,
        subjects: List<StudentSubjectItem>.unmodifiable(
          subjects.map(_subjectItem),
        ),
        courses: List<({String id, String name})>.unmodifiable(
          courses.map((item) {
            if (item case {'id': String id, 'name': String name}) {
              return (id: id, name: name);
            }
            throw const ApiFailure(ApiFailureKind.invalidResponse);
          }),
        ),
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectItem>>> subjects(
    GoogleIdentity identity, {
    required bool previous,
  }) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'subjects',
      query: {'scope': previous ? 'previous' : 'current'},
    );
    final items = response.json['data'];
    if (items is! List) throw const ApiFailure(ApiFailureKind.invalidResponse);
    return List.unmodifiable(items.map(_subjectItem));
  });

  StudentSubjectItem _subjectItem(Object? item) {
    if (item
        case {
          'id': String id,
          'name': String name,
          'progress': {
            'completed': int completed,
            'total': int total,
            'percent': int percent,
          },
        }
        when completed >= 0 &&
            completed <= total &&
            percent >= 0 &&
            percent <= 100) {
      return (
        id: id,
        name: name,
        completed: completed,
        total: total,
        percent: percent,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentCoursePageData>> courses(
    GoogleIdentity identity, {
    required bool mine,
    required int page,
  }) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'courses',
      query: {'scope': mine ? 'mine' : 'all', 'page': '$page', 'limit': '20'},
    );
    if (response.json case {
      'data': List data,
      'meta': {'page': int current, 'limit': int limit, 'total': int total},
    }) {
      return (
        courses: List<StudentCourseItem>.unmodifiable(data.map(_courseItem)),
        hasMore: current * limit < total,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, StudentCourseItem>> course(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'courses/${Uri.encodeComponent(id)}',
    );
    return _courseItem(response.json['data']);
  });

  StudentCourseItem _courseItem(Object? item) {
    if (item
        case {
          'id': String id,
          'name': String name,
          'description': final description,
          'priceUsd': String price,
          'durationDays': int days,
          'subscribed': bool subscribed,
        }
        when description == null || description is String) {
      return (
        id: id,
        name: name,
        description: description as String?,
        priceUsd: price,
        durationDays: days,
        subscribed: subscribed,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentSubjectDetails>> subject(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final path = 'subjects/${Uri.encodeComponent(id)}';
    final details = await _authorized(identity, 'GET', path);
    final lessons = await _authorized(identity, 'GET', '$path/lessons');
    if (details.json['data'] case {'subscribed': bool subscribed}) {
      final rows = lessons.json['data'];
      if (rows is List) {
        return (
          subject: _subjectItem(details.json['data']),
          subscribed: subscribed,
          lessons: List<StudentLessonSummary>.unmodifiable(
            rows.map((row) {
              if (row case {
                'title': String title,
                'locked': bool locked,
                'completed': bool completed,
              }) {
                return (
                  title: title,
                  locked: locked,
                  completed: completed,
                  position: switch (row['position']) {
                    int value when value > 0 => value,
                    _ => null,
                  },
                  durationSeconds: switch (row['durationSeconds']) {
                    int value when value > 0 => value,
                    _ => null,
                  },
                );
              }
              throw const ApiFailure(ApiFailureKind.invalidResponse);
            }),
          ),
        );
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, StudentProfileData>> profile(
    GoogleIdentity identity,
  ) => _captureLearning(() async {
    final response = await _authorized(identity, 'GET', 'me');
    if (response.json['data'] case {
      'displayName': String displayName,
      'officialName': String? officialName,
      'email': String email,
      'phone': String? phone,
      'department': final department,
      'year': int? year,
    }) {
      return (
        name: officialName ?? displayName,
        email: email,
        phone: phone,
        department: switch (department) {
          {'name': String name} => name,
          _ => null,
        },
        year: year,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, void>> updateProfile(
    GoogleIdentity identity, {
    String? officialName,
    String? phone,
  }) => _capture(() async {
    final changes = {'officialName': ?officialName, 'phone': ?phone};
    if (changes.isEmpty) return;
    await _authorized(identity, 'PATCH', 'me', body: changes);
  });

  Future<Either<StudentSessionFailure, StudentSession>> _save(
    GoogleIdentity identity,
    String path,
    Map<String, String> body,
  ) => _capture(() async {
    try {
      await _authorized(identity, 'PUT', path, body: body);
    } on ApiFailure catch (failure) {
      if (failure.kind == ApiFailureKind.unauthenticated ||
          failure.kind == ApiFailureKind.forbidden ||
          failure.code == 'USAGE_TYPE_LOCKED' ||
          failure.code == 'BASIC_INFO_LOCKED') {
        return _read(identity);
      }
      rethrow;
    }
    return _read(identity);
  });

  Future<ApiResponse> _authorized(
    GoogleIdentity identity,
    String method,
    String path, {
    Map<String, Object>? body,
    Map<String, String> query = const {},
  }) async {
    final access = _access;
    if (access == null || _owner != identity.firebaseUid) {
      throw const ApiFailure(ApiFailureKind.unauthenticated);
    }
    return _api.send(
      ApiRequest(
        method: method,
        path: path,
        query: query,
        headers: {'Authorization': 'Bearer $access'},
        jsonBody: body,
      ),
    );
  }

  Future<Either<StudentSessionFailure, T>> _captureLearning<T>(
    Future<T> Function() operation,
  ) => _capture(operation, classifyLearningDenials: true);

  Future<Either<StudentSessionFailure, T>> _capture<T>(
    Future<T> Function() operation, {
    bool classifyLearningDenials = false,
  }) async {
    try {
      return Right(await operation());
    } on ApiFailure catch (failure) {
      return Left(switch (failure) {
        ApiFailure(kind: ApiFailureKind.forbidden || ApiFailureKind.notFound)
            when classifyLearningDenials =>
          StudentSessionFailure.learningDataDenied,
        ApiFailure(code: 'PHONE_TAKEN') => StudentSessionFailure.phoneTaken,
        ApiFailure(kind: ApiFailureKind.unauthenticated) =>
          StudentSessionFailure.expired,
        ApiFailure(
          kind: ApiFailureKind.badRequest,
          code: 'VALIDATION_FAILED',
        ) ||
        ApiFailure(
          kind: ApiFailureKind.validation,
        ) => StudentSessionFailure.invalidBasicInfo,
        ApiFailure(kind: ApiFailureKind.invalidResponse) =>
          StudentSessionFailure.invalidResponse,
        _ => StudentSessionFailure.unavailable,
      });
    } catch (_) {
      return const Left(StudentSessionFailure.unavailable);
    }
  }

  Future<void> _revoke(String refresh) async {
    await _api.send(
      ApiRequest(
        method: 'POST',
        path: 'auth/logout',
        jsonBody: {'refreshToken': refresh},
      ),
    );
  }

  Future<String> _deviceBindingId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null) return existing;
    if (_platform == 'android') {
      final deviceId = await _readAndroidDeviceId?.call();
      if (deviceId == null || deviceId.isEmpty) {
        throw const ApiFailure(ApiFailureKind.configuration);
      }
      return deviceId;
    }
    final random = Random.secure();
    final value = base64Url.encode(
      List.generate(24, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _deviceKey, value: value);
    return value;
  }
}
