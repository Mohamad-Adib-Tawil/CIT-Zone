import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/debug/safe_debug_log.dart';
import '../../../core/errors/either.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_cancellation_token.dart';
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
    final data = response.json['data'];
    if (data case {
      'name': String name,
      'subjects': List subjects,
      'courses': List courses,
    }) {
      return (
        name: name,
        resumeLesson: _resumeLesson(data['continueWatching']),
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

  StudentResumeLesson? _resumeLesson(Object? items) {
    if (items is! List) return null;
    for (final item in items) {
      if (item
          case {
            'lessonId': String lessonId,
            'lessonTitle': String lessonTitle,
            'subjectId': String subjectId,
            'subjectName': String subjectName,
            'positionSeconds': int positionSeconds,
            'durationSeconds': int? durationSeconds,
          }
          when positionSeconds >= 0 &&
              (durationSeconds == null || durationSeconds > 0)) {
        return (
          lessonId: lessonId,
          lessonTitle: lessonTitle,
          subjectId: subjectId,
          subjectName: subjectName,
          positionSeconds: positionSeconds,
          durationSeconds: durationSeconds,
        );
      }
    }
    return null;
  }

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
    if (details.json['data'] case {'subscribed': bool subscribed}) {
      return (
        subject: _subjectItem(details.json['data']),
        subscribed: subscribed,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, List<StudentLessonSummary>>>
  subjectLessons(GoogleIdentity identity, String id) =>
      _loadSubjectList(identity, id, 'lessons', (row) {
        if (row case {
          'title': String title,
          'locked': bool locked,
          'completed': bool completed,
        }) {
          return (
            id: switch (row['id']) {
              String id when id.isNotEmpty => id,
              _ => null,
            },
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
      });

  @override
  Future<Either<StudentSessionFailure, StudentLessonDetail>> lesson(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'lessons/${Uri.encodeComponent(id)}',
    );
    if (response.json['data'] case {
      'title': String title,
      'description': String? description,
      'locked': bool locked,
      'videoReady': bool videoReady,
      'next': final next,
    }) {
      return (
        title: title,
        description: description,
        locked: locked,
        videoReady: videoReady,
        nextId: switch (next) {
          {'id': String id} when id.isNotEmpty => id,
          _ => null,
        },
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, Uri>> academicFileDownload(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final access = _access;
    final response = await _authorized(
      identity,
      'GET',
      'files/${Uri.encodeComponent(id)}/download',
    );
    if (_owner != identity.firebaseUid || _access != access) {
      throw const ApiFailure(ApiFailureKind.unauthenticated);
    }
    if (response.json['data'] case {
      'url': String url,
      'expiresAt': String expiry,
    }) {
      final uri = Uri.tryParse(url);
      final expiresAt = DateTime.tryParse(expiry);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          !uri.hasFragment &&
          expiresAt?.isAfter(DateTime.now()) == true) {
        return uri;
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  StudentFileViewer fileViewer(GoogleIdentity identity, String id) =>
      _StudentFileViewer(
        api: _api,
        path: 'files/${Uri.encodeComponent(id)}',
        access: () => _owner == identity.firebaseUid ? _access : null,
      );

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectFile>>> subjectFiles(
    GoogleIdentity identity,
    String id,
  ) => _loadSubjectList(identity, id, 'files', (row) {
    if (row case {
      'id': String id,
      'title': String title,
      'pages': int? pages,
      'downloadable': bool downloadable,
    }) {
      return (id: id, title: title, pages: pages, downloadable: downloadable);
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, StudentAttempt>> submitExercise(
    GoogleIdentity identity,
    String id,
    String key, {
    String? code,
    String? language,
    String? choiceId,
  }) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'POST',
      'exercises/${Uri.encodeComponent(id)}/submissions',
      headers: {'Idempotency-Key': key},
      body: {'code': ?code, 'language': ?language, 'choiceId': ?choiceId},
    );
    return _attempt(response.json['data']);
  });

  @override
  Future<Either<StudentSessionFailure, StudentAttempt?>> latestExerciseAttempt(
    GoogleIdentity identity,
    String exerciseId,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'exercises/${Uri.encodeComponent(exerciseId)}/submissions',
      query: const {'page': '1', 'limit': '1'},
    );
    if (response.json['data'] case final List attempts) {
      return attempts.isEmpty ? null : _attempt(attempts.first);
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, StudentAttempt>> exerciseAttempt(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'submissions/${Uri.encodeComponent(id)}',
    );
    return _attempt(response.json['data']);
  });

  StudentAttempt _attempt(Object? data) {
    if (data case {
      'id': String id,
      'status': String status,
      'score': num? score,
      'passed': bool? passed,
    }) {
      final evaluation = data['evaluation'];
      return (
        id: id,
        status: switch (status) {
          'grading' => StudentAttemptStatus.grading,
          'graded' => StudentAttemptStatus.graded,
          'failed' => StudentAttemptStatus.failed,
          _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
        },
        score: score,
        passed: passed,
        explanation: evaluation is Map && evaluation['explanation'] is String
            ? evaluation['explanation'] as String
            : null,
        suggestedFix: evaluation is Map && evaluation['suggestedFix'] is String
            ? evaluation['suggestedFix'] as String
            : null,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentExercisePrompt>> exercise(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'exercises/${Uri.encodeComponent(id)}',
    );
    return switch (response.json['data']) {
      {
        'title': String title,
        'statement': String statement,
        'type': 'coding',
        'language': String language,
        'starterCode': String? code,
      } =>
        StudentCodingPrompt(title, statement, language, code ?? ''),
      {
        'title': String title,
        'statement': String statement,
        'type': 'multiple_choice',
        'choices': List choices,
      } =>
        StudentChoicePrompt(
          title,
          statement,
          List.unmodifiable(
            choices.map((choice) {
              if (choice case {'id': String id, 'text': String text}) {
                return (id: id, text: text);
              }
              throw const ApiFailure(ApiFailureKind.invalidResponse);
            }),
          ),
        ),
      _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
    };
  });

  @override
  Future<Either<StudentSessionFailure, List<StudentSubjectExercise>>>
  subjectExercises(GoogleIdentity identity, String id) =>
      _loadSubjectList(identity, id, 'exercises', (row) {
        if (row case {
          'id': String id,
          'title': String title,
          'state': String state,
          'bestScore': num? bestScore,
        }) {
          return (
            id: id,
            title: title,
            state: switch (state) {
              'not_attempted' => StudentExerciseState.notAttempted,
              'attempted' => StudentExerciseState.attempted,
              'grading' => StudentExerciseState.grading,
              'solved' => StudentExerciseState.solved,
              _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
            },
            bestScore: bestScore,
          );
        }
        throw const ApiFailure(ApiFailureKind.invalidResponse);
      });

  Future<Either<StudentSessionFailure, List<T>>> _loadSubjectList<T>(
    GoogleIdentity identity,
    String id,
    String resource,
    T Function(Object?) decode,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'subjects/${Uri.encodeComponent(id)}/$resource',
    );
    if (response.json['data'] case final List rows) {
      return List<T>.unmodifiable(rows.map(decode));
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, List<StudentSubscription>>>
  subscriptions(GoogleIdentity identity) => _captureLearning(() async {
    final response = await _authorized(identity, 'GET', 'me/subscriptions');
    if (response.json['data'] case final List rows) {
      return List<StudentSubscription>.unmodifiable(rows.map(_subscription));
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  StudentSubscription _subscription(Object? row) {
    if (row case {
      'scopeName': String? name,
      'scopeType': String scope,
      'state': String state,
      'startsAt': String start,
      'expiresAt': String expiry,
      'daysLeft': int daysLeft,
    }) {
      final startsAt = DateTime.tryParse(start);
      final expiresAt = DateTime.tryParse(expiry);
      if (startsAt != null && expiresAt != null && daysLeft >= 0) {
        final status = switch (state) {
          'active' => StudentSubscriptionState.active,
          'upcoming' => StudentSubscriptionState.upcoming,
          'expired' => StudentSubscriptionState.expired,
          'revoked' => StudentSubscriptionState.revoked,
          _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
        };
        return (
          name: name,
          scope: scope,
          state: status,
          startsAt: startsAt,
          expiresAt: expiresAt,
          daysLeft: daysLeft,
        );
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentTicketPage>> supportTickets(
    GoogleIdentity identity,
    int page,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'support/tickets',
      query: {'page': '$page', 'limit': '20'},
    );
    if (response.json case {
      'data': List rows,
      'meta': {'page': int page, 'limit': int limit, 'total': int total},
    }) {
      return (
        tickets: List<StudentTicket>.unmodifiable(rows.map(_supportTicket)),
        hasMore: page * limit < total,
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  StudentTicket _supportTicket(Object? row) {
    if (row case {
      'id': String id,
      'subject': String subject,
      'status': String status,
      'lastMessageAt': String? last,
      'createdAt': String created,
    }) {
      final updatedAt = DateTime.tryParse(last ?? created);
      if (updatedAt != null) {
        return (id: id, subject: subject, status: status, updatedAt: updatedAt);
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentTicketThread>> supportTicket(
    GoogleIdentity identity,
    String id,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'support/tickets/${Uri.encodeComponent(id)}',
    );
    final data = response.json['data'];
    if (data case {'messages': List messages}) {
      return (
        ticket: _supportTicket(data),
        messages: List<StudentTicketMessage>.unmodifiable(
          messages.map(_supportMessage),
        ),
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  StudentTicketMessage _supportMessage(Object? row) {
    if (row case {
      'from': String from,
      'body': String body,
      'createdAt': String date,
    }) {
      final sentAt = DateTime.tryParse(date);
      if (sentAt != null && (from == 'support' || from == 'student')) {
        return (fromSupport: from == 'support', body: body, sentAt: sentAt);
      }
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentTicket>> createSupportTicket(
    GoogleIdentity identity,
    String subject,
    String body,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'POST',
      'support/tickets',
      body: {'subject': subject, 'body': body},
    );
    return _supportTicket(response.json['data']);
  });

  @override
  Future<Either<StudentSessionFailure, StudentTicketReply>>
  replyToSupportTicket(
    GoogleIdentity identity,
    String id,
    String body,
    String idempotencyKey,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'POST',
      'support/tickets/${Uri.encodeComponent(id)}/messages',
      body: {'body': body},
      headers: {'Idempotency-Key': idempotencyKey},
    );
    if (response.json['data'] case {
      'message': final message,
      'ticket': final ticket,
    }) {
      return (
        message: _supportMessage(message),
        ticket: _supportTicket(ticket),
      );
    }
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  });

  @override
  Future<Either<StudentSessionFailure, String?>> currentDeviceRequest(
    GoogleIdentity identity,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'GET',
      'me/device-change-requests/current',
    );
    if (response.json case {'data': null}) return null;
    return _deviceRequestStatus(response);
  });

  @override
  Future<Either<StudentSessionFailure, String>> requestDeviceChange(
    GoogleIdentity identity,
    String reason,
  ) => _captureLearning(() async {
    final response = await _authorized(
      identity,
      'POST',
      'me/device-change-requests',
      body: {'reason': reason},
    );
    return _deviceRequestStatus(response);
  });

  String _deviceRequestStatus(ApiResponse response) {
    if (response.json['data'] case {'status': String status}) return status;
    throw const ApiFailure(ApiFailureKind.invalidResponse);
  }

  @override
  Future<Either<StudentSessionFailure, StudentDeviceData>> device(
    GoogleIdentity identity,
  ) => _captureLearning(() async {
    final response = await _authorized(identity, 'GET', 'me/device');
    return switch (response.json) {
      {'data': null} => (
        status: StudentDeviceStatus.notApplicable,
        name: null,
        platform: null,
        registeredAt: null,
      ),
      {'data': {'status': 'unregistered', 'device': null}} => (
        status: StudentDeviceStatus.unregistered,
        name: null,
        platform: null,
        registeredAt: null,
      ),
      {
        'data': {
          'status': final String status,
          'device': {
            'name': String? name,
            'platform': String platform,
            'registeredAt': String date,
          },
        },
      }
          when status == 'authorized' || status == 'unauthorized' =>
        (
          status: status == 'authorized'
              ? StudentDeviceStatus.authorized
              : StudentDeviceStatus.unauthorized,
          name: name,
          platform: platform,
          registeredAt: DateTime.tryParse(date),
        ),
      _ => throw const ApiFailure(ApiFailureKind.invalidResponse),
    };
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
    Map<String, String> headers = const {},
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
        headers: {...headers, 'Authorization': 'Bearer $access'},
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
        ApiFailure(code: 'TICKET_CLOSED') =>
          StudentSessionFailure.supportTicketClosed,
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

final class _StudentFileViewer implements StudentFileViewer {
  _StudentFileViewer({
    required this.api,
    required this.path,
    required this.access,
  });

  final ApiClient api;
  final String path;
  final String? Function() access;
  final _cancellation = ApiCancellationToken();
  String? _token;
  int? _pageCount;
  DateTime? _expiresAt;
  bool _loading = false;

  @override
  Future<StudentFilePage?> page(int number) async {
    final bearer = access();
    if (bearer == null || _loading || _cancellation.isCanceled || number < 1) {
      return null;
    }
    _loading = true;
    try {
      if (_token == null || _expiresAt?.isAfter(DateTime.now()) != true) {
        final response = await api.send(
          ApiRequest(
            method: 'POST',
            path: '$path/view-session',
            headers: {'Authorization': 'Bearer $bearer'},
          ),
          cancellationToken: _cancellation,
        );
        if (_cancellation.isCanceled || access() != bearer) return null;
        if (response.json['data'] case {
          'token': String token,
          'expiresAt': String expiry,
          'pages': int? pages,
        }) {
          final expiresAt = DateTime.tryParse(expiry);
          if (token.isEmpty || expiresAt == null) return null;
          _token = token;
          _expiresAt = expiresAt;
          _pageCount = pages;
        } else {
          return null;
        }
      }
      if (_cancellation.isCanceled || access() != bearer) return null;
      final response = await api.send(
        ApiRequest(
          method: 'GET',
          path: '$path/pages/$number',
          headers: {'X-View-Token': _token!},
          acceptImage: true,
        ),
        cancellationToken: _cancellation,
      );
      if (_cancellation.isCanceled || access() != bearer) return null;
      final bytes = response.imageBytes;
      return bytes == null
          ? null
          : (bytes: bytes, totalPages: response.totalPages ?? _pageCount);
    } on ApiFailure catch (failure) {
      if (failure.kind == ApiFailureKind.unauthenticated) _token = null;
      return null;
    } finally {
      _loading = false;
    }
  }

  @override
  void close() {
    _token = null;
    _cancellation.cancel();
  }
}
