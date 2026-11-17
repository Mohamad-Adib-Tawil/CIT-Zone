import 'dart:async';
import 'dart:typed_data';

import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/app/router/app_router.dart';
import 'package:cit_zone/app/router/app_routes.dart';
import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/core/theme/theme_mode_controller.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_auth_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/network/api_transport_policy.dart';
import 'package:cit_zone/features/auth/data/firebase_identity_proof.dart';
import 'package:cit_zone/features/auth/data/student_session_gateway.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:cit_zone/features/auth/domain/student_session_repository.dart';
import 'package:cit_zone/features/auth/domain/student_registration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _identity = GoogleIdentity(
  idGoogle: 'google-test',
  firebaseUid: 'firebase-test',
  emailVerified: true,
  displayName: null,
  email: 'student@example.test',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  StudentSessionGateway gateway(_Api api) => StudentSessionGateway(
    api: api,
    proofSource: _Proof(),
    environment: Uri.parse('https://api.example.test/api/v1/'),
    platform: 'android',
    androidDeviceId: () async => 'android_v1_stable_test_id',
    storage: const FlutterSecureStorage(),
  );

  test(
    'lesson detail validates the server duration and saved position',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);

      final lesson = (await sessions.lesson(
        _identity,
        'lesson',
      )).getRight().toNullable();
      expect(lesson?.durationSeconds, 1620);
      expect(lesson?.positionSeconds, 760);

      api.lessonDuration = null;
      final withUnknownDuration = await sessions.lesson(_identity, 'lesson');
      expect(withUnknownDuration.isRight(), isTrue);
      expect(
        withUnknownDuration.getRight().toNullable()?.durationSeconds,
        isNull,
      );

      api.lessonPosition = -1;
      final invalid = await sessions.lesson(_identity, 'lesson');
      expect(
        invalid.getLeft().toNullable(),
        StudentSessionFailure.invalidResponse,
      );
    },
  );

  test(
    'unread notifications accept zero and reject malformed counts',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);
      expect(
        (await sessions.unreadNotificationCount(_identity))
            .getRight()
            .toNullable(),
        0,
      );
      expect(api.requests.last.path, 'me/notifications/unread-count');
      for (final count in [-1, '5', null]) {
        api.unreadCount = count;
        final result = await sessions.unreadNotificationCount(_identity);
        expect(
          result.getLeft().toNullable(),
          StudentSessionFailure.invalidResponse,
        );
      }
    },
  );

  test('leaving a support thread cancels its authorized request', () async {
    final api = _Api()
      ..ticketReadStarted = Completer<ApiCancellationToken?>()
      ..pendingTicketRead = Completer<void>();
    final sessions = gateway(api);
    await sessions.start(_identity);
    final ended = Completer<void>();
    final pending = sessions.supportTicket(
      _identity,
      'ticket',
      whenCanceled: ended.future,
    );
    final token = await api.ticketReadStarted!.future;
    expect(token?.isCanceled, isFalse);
    ended.complete();
    await token!.whenCanceled;
    api.pendingTicketRead!.complete();
    expect(
      (await pending).getLeft().toNullable(),
      StudentSessionFailure.unavailable,
    );
  });

  test('subscriptions use the server state and dates', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    final result = await sessions.subscriptions(_identity);
    final subscription = result.getRight().toNullable()?.single;
    expect(subscription?.scope, 'course');
    expect(subscription?.state.name, 'expired');
    expect(subscription?.expiresAt, DateTime.utc(2026, 11, 10));
    expect(api.requests.last.path, 'me/subscriptions');
  });

  test(
    'academic download accepts only a fresh HTTPS link and maps denial',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);
      final valid = await sessions.academicFileDownload(_identity, 'file');
      expect(valid.getRight().toNullable()?.host, 'storage.example.test');
      api.downloadUrl = 'http://storage.example.test/file.pdf';
      final insecure = await sessions.academicFileDownload(_identity, 'file');
      expect(
        insecure.getLeft().toNullable(),
        StudentSessionFailure.invalidResponse,
      );
      api.downloadUrl = null;
      final denied = await sessions.academicFileDownload(_identity, 'file');
      expect(
        denied.getLeft().toNullable(),
        StudentSessionFailure.learningDataDenied,
      );
    },
  );

  test(
    'an academic download keeps the result of a successful access renewal',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);
      api.rejectedAccess = 'Bearer access-1';

      final result = await sessions.academicFileDownload(_identity, 'file');

      expect(result.getRight().toNullable()?.host, 'storage.example.test');
      expect(
        api.requests.where((request) => request.path == 'auth/refresh'),
        hasLength(1),
      );
      expect(
        api.requests.where((request) => request.path == 'files/file/download'),
        hasLength(2),
      );
    },
  );

  test('opening a restricted viewer preserves the session denial', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    for (final (code, failure) in [
      ('ACCOUNT_SUSPENDED', StudentFileViewFailure.accountSuspended),
      ('DEVICE_NOT_AUTHORIZED', StudentFileViewFailure.deviceUnauthorized),
    ]) {
      api.viewerDenial = code;
      final viewer = sessions.fileViewer(_identity, 'file');
      expect((await viewer.page(1)).getLeft().toNullable(), failure);
      viewer.close();
    }
    expect(api.requests.any((request) => request.acceptImage), isFalse);
  });

  test('closing the viewer discards a late image response', () async {
    final api = _Api()
      ..pageStarted = Completer<void>()
      ..pendingPage = Completer<void>();
    final sessions = gateway(api);
    await sessions.start(_identity);
    final viewer = sessions.fileViewer(_identity, 'file');
    final pending = viewer.page(1);
    await api.pageStarted!.future;
    viewer.close();
    api.pendingPage!.complete();
    expect((await pending).isLeft(), isTrue);
  });

  for (final signOut in [false, true]) {
    test(
      'a pending image respects the viewer session after signOut=$signOut',
      () async {
        final api = _Api()
          ..pageStarted = Completer<void>()
          ..pendingPage = Completer<void>();
        final sessions = gateway(api);
        await sessions.start(_identity);
        final viewer = sessions.fileViewer(_identity, 'file');
        addTearDown(viewer.close);
        final pending = viewer.page(1);
        await api.pageStarted!.future;

        if (signOut) {
          expect((await sessions.end(_identity)).isRight(), isTrue);
          expect((await sessions.start(_identity)).isRight(), isTrue);
        } else {
          api.rejectedAccess = 'Bearer access-1';
          expect((await sessions.read(_identity)).isRight(), isTrue);
          expect(
            api.requests.where((request) => request.path == 'auth/refresh'),
            hasLength(1),
          );
        }

        api.pendingPage!.complete();
        final result = await pending;
        if (signOut) {
          expect(result.isLeft(), isTrue);
          expect((await viewer.page(2)).isLeft(), isTrue);
        } else {
          expect(result.getRight().toNullable()?.bytes, [1, 2, 3]);
        }
      },
    );
  }

  test('file viewer reuses the view session and closes it locally', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    final viewer = sessions.fileViewer(_identity, 'file');
    expect((await viewer.page(1)).getRight().toNullable()?.totalPages, 3);
    expect((await viewer.page(2)).getRight().toNullable()?.bytes, [1, 2, 3]);
    final calls = api.requests
        .where((request) => request.path.startsWith('files/'))
        .toList();
    expect(calls.map((request) => request.path), [
      'files/file/view-session',
      'files/file/pages/1',
      'files/file/pages/2',
    ]);
    expect(calls.last.headers, {'X-View-Token': 'test-view-token'});
    viewer.close();
    expect((await viewer.page(3)).isLeft(), isTrue);
    expect(api.requests.last.path, 'files/file/pages/2');
  });

  test('reads the registered device and accepts an exempt account', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    api.deviceResponse = {
      'status': 'authorized',
      'device': {
        'id': 'private-id',
        'name': 'اسم الجهاز',
        'platform': 'android',
        'registeredAt': '2026-11-14T12:00:00Z',
      },
    };
    final device = (await sessions.device(_identity)).getRight().toNullable();
    expect(device?.name, 'اسم الجهاز');
    expect(device?.status.name, 'authorized');
    expect(device?.registeredAt, DateTime.utc(2026, 11, 14, 12));
    expect(api.requests.last.method, 'GET');

    api.deviceResponse = null;
    final exempt = (await sessions.device(_identity)).getRight().toNullable();
    expect(exempt?.status.name, 'notApplicable');
    expect(exempt?.name, isNull);
  });

  test('Android reuses its platform ID after local storage is lost', () async {
    final first = _Api();
    await gateway(first).start(_identity);
    FlutterSecureStorage.setMockInitialValues({});
    final reinstalled = _Api();
    await gateway(reinstalled).start(_identity);

    for (final api in [first, reinstalled]) {
      expect((api.requests.first.jsonBody as Map)['device'], {
        'id': 'android_v1_stable_test_id',
        'platform': 'android',
      });
    }
  });

  test('Android preserves an existing legacy binding when upgrading', () async {
    const storage = FlutterSecureStorage();
    const namespace = 'aHR0cHM6Ly9hcGkuZXhhbXBsZS50ZXN0L2FwaS92MS8=';
    await storage.write(key: 'device_v1_$namespace', value: 'legacy-id');
    final api = _Api();
    await gateway(api).start(_identity);
    expect((api.requests.first.jsonBody as Map)['device'], {
      'id': 'legacy-id',
      'platform': 'android',
    });
  });

  test('Android with no identifier cannot create a random binding', () async {
    final api = _Api();
    final session = StudentSessionGateway(
      api: api,
      proofSource: _Proof(),
      environment: Uri.parse('https://api.example.test/api/v1/'),
      platform: 'android',
      androidDeviceId: () async => null,
      storage: const FlutterSecureStorage(),
    );
    expect(
      await session.start(_identity),
      isA<Left<StudentSessionFailure, StudentSession>>().having(
        (result) => result.value,
        'failure',
        StudentSessionFailure.unavailable,
      ),
    );
    expect(api.requests, isEmpty);
  });

  test('exchanges, rotates on restart, and revokes the latest token', () async {
    final api = _Api();
    expect(
      await gateway(api).restore(_identity),
      isA<Right<StudentSessionFailure, StudentSession?>>().having(
        (r) => r.value,
        'session',
        isNull,
      ),
    );
    await gateway(api).start(_identity);
    expect(
      await gateway(api).restore(_identity),
      isA<Right<StudentSessionFailure, StudentSession?>>().having(
        (r) => r.value?.next,
        'next',
        StudentNextStep.chooseUsageType,
      ),
    );
    await gateway(api).end(_identity);
    expect(
      await gateway(api).restore(_identity),
      isA<Right<StudentSessionFailure, StudentSession?>>().having(
        (r) => r.value,
        'session',
        isNull,
      ),
    );

    expect(api.requests.map((r) => r.path), [
      'auth/google',
      'me/session-state',
      'auth/refresh',
      'me/session-state',
      'auth/logout',
    ]);
    expect(api.requests.first.jsonBody, {
      'idToken': 'firebase-test-proof',
      'device': {'id': isA<String>(), 'platform': 'android'},
    });
    expect(api.requests[1].headers['Authorization'], 'Bearer access-1');
    expect(api.requests[2].jsonBody, {'refreshToken': _refresh(1)});
    expect(api.requests[3].headers['Authorization'], 'Bearer access-2');
    expect(api.requests[4].jsonBody, {'refreshToken': _refresh(2)});
    final device = (api.requests.first.jsonBody as Map)['device'];
    await gateway(api).start(_identity);
    expect((api.requests[5].jsonBody as Map)['device'], device);
  });

  test('concurrent expired reads share one rotation and retry once', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    api.rejectedAccess = 'Bearer access-1';
    final results = await Future.wait([
      sessions.subscriptions(_identity),
      sessions.subscriptions(_identity),
    ]);
    expect(results.every((result) => result.isRight()), isTrue);
    expect(api.requests.where((r) => r.path == 'auth/refresh'), hasLength(1));
    expect(
      api.requests
          .where((r) => r.path == 'me/subscriptions')
          .map((r) => r.headers['Authorization']),
      [
        'Bearer access-1',
        'Bearer access-1',
        'Bearer access-2',
        'Bearer access-2',
      ],
    );
  });

  test(
    'a read rejected during local rotation waits for the new session',
    () async {
      final api = _Api()
        ..refreshStarted = Completer<void>()
        ..pendingRefresh = Completer<void>();
      final sessions = gateway(api);
      await sessions.start(_identity);
      api.rejectedAccess = 'Bearer access-1';
      final first = sessions.subscriptions(_identity);
      await api.refreshStarted!.future;
      api.accessFailure = 'SESSION_REVOKED';
      final second = sessions.subscriptions(_identity);
      api.pendingRefresh!.complete();

      expect((await first).isRight(), isTrue);
      expect((await second).isRight(), isTrue);
      expect(api.requests.where((r) => r.path == 'auth/refresh'), hasLength(1));
    },
  );

  test('a rejected rotation returns expiry to all pending reads', () async {
    final api = _Api()..rejectRefresh = true;
    final sessions = gateway(api);
    await sessions.start(_identity);
    api.rejectedAccess = 'Bearer access-1';

    final results = await Future.wait([
      sessions.subscriptions(_identity),
      sessions.subscriptions(_identity),
    ]);
    for (final result in results) {
      expect(result.getLeft().toNullable(), StudentSessionFailure.expired);
    }
    expect(api.requests.where((r) => r.path == 'auth/refresh'), hasLength(1));
    expect((await sessions.restore(_identity)).getRight().toNullable(), isNull);
  });

  test('an expired write and a revoked read do not retry', () async {
    final api = _Api();
    final sessions = gateway(api);
    await sessions.start(_identity);
    api.rejectedAccess = 'Bearer access-1';
    final write = await sessions.updateProfile(
      _identity,
      officialName: 'اسم جديد',
    );
    expect(write.getLeft().toNullable(), StudentSessionFailure.expired);
    expect(api.requests.where((r) => r.method == 'PATCH'), hasLength(1));
    api.accessFailure = 'SESSION_REVOKED';
    final read = await sessions.subscriptions(_identity);
    expect(read.getLeft().toNullable(), StudentSessionFailure.expired);
    expect(api.requests.where((r) => r.path == 'auth/refresh'), isEmpty);
  });

  test(
    'logout during rotation revokes the new token without retrying the read',
    () async {
      final api = _Api()
        ..refreshStarted = Completer<void>()
        ..pendingRefresh = Completer<void>();
      final sessions = gateway(api);
      await sessions.start(_identity);
      api.rejectedAccess = 'Bearer access-1';
      final read = sessions.subscriptions(_identity);
      await api.refreshStarted!.future;
      final logout = sessions.end(_identity);
      api.pendingRefresh!.complete();

      expect(
        (await read).getLeft().toNullable(),
        StudentSessionFailure.expired,
      );
      expect((await logout).isRight(), isTrue);
      expect(api.requests.last.path, 'auth/logout');
      expect(api.requests.last.jsonBody, {'refreshToken': _refresh(2)});
      expect(
        api.requests.where((r) => r.path == 'me/subscriptions'),
        hasLength(1),
      );
      expect(
        (await sessions.restore(_identity)).getRight().toNullable(),
        isNull,
      );
    },
  );

  test('clears a rejected refresh without retrying the write', () async {
    final api = _Api();
    await gateway(api).start(_identity);
    api.rejectRefresh = true;
    expect(
      await gateway(api).restore(_identity),
      isA<Right<StudentSessionFailure, StudentSession?>>().having(
        (r) => r.value,
        'session',
        isNull,
      ),
    );
    expect(
      await gateway(api).restore(_identity),
      isA<Right<StudentSessionFailure, StudentSession?>>().having(
        (r) => r.value,
        'session',
        isNull,
      ),
    );
    expect(
      api.requests.where((request) => request.path == 'auth/refresh'),
      hasLength(1),
    );
  });
  for (final type in StudentUsageType.values) {
    test(
      'saves ${type.name}, then re-reads the authoritative destination',
      () async {
        final api = _Api();
        final session = gateway(api);
        await session.start(_identity);
        final result = await session.setUsageType(_identity, type);
        expect(
          result,
          isA<Right<StudentSessionFailure, StudentSession>>().having(
            (r) => r.value.next,
            'next',
            StudentNextStep.completeBasicInfo,
          ),
        );
        final restarted = await gateway(api).restore(_identity);
        expect(
          restarted,
          isA<Right<StudentSessionFailure, StudentSession?>>().having(
            (r) => r.value?.usageType,
            'usageType',
            type,
          ),
        );
        final saved = await session.setBasicInfo(
          _identity,
          officialName: 'اسم تجريبي',
          phone: '0944000000',
        );
        expect(
          saved,
          isA<Right<StudentSessionFailure, StudentSession>>().having(
            (r) => r.value.next,
            'next',
            type == StudentUsageType.institute
                ? StudentNextStep.completeRegistration
                : StudentNextStep.home,
          ),
        );
        expect(
          api.requests.where((r) => r.method == 'PUT').map((r) => r.jsonBody),
          [
            {'usageType': type.name},
            {'officialName': 'اسم تجريبي', 'phone': '0944000000'},
          ],
        );
      },
    );
  }

  test('rejects a destination outside the known server contract', () async {
    final api = _Api()..next = 'unknown';
    expect(
      await gateway(api).start(_identity),
      isA<Left<StudentSessionFailure, StudentSession>>().having(
        (r) => r.value,
        'failure',
        StudentSessionFailure.invalidResponse,
      ),
    );
  });

  testWidgets(
    'Google button routes by session, blocks direct links and deduplicates a pending save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _Api();
      final sessions = gateway(api);
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(_IdentityGateway()),
        messages: AppLocalizationsAr(),
        sessions: sessions,
      );
      final dependencies = AppDependencies(
        sessionRepository: sessions,
        configuration: AppConfiguration.parse(
          environment: AppEnvironment.parse(
            stageName: 'production',
            apiBaseUrl: '',
          ),
          debugBuild: false,
          previewFrameName: '',
        ),
      );
      final theme = ThemeModeController.inMemory();
      final routes = AppRouter(
        dependencies: dependencies,
        identityCubit: cubit,
        themeModeController: theme,
        initialLocation: AppRoutes.studentBasicInfo,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        routes.dispose();
        theme.dispose();
        await cubit.close();
        await dependencies.dispose();
      });
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp.router(
            routerConfig: routes.router,
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyWelcomeScreen), findsOneWidget);
      await tester.tap(find.text(AppLocalizationsAr().continueViaGoogle));
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyUsageTypeScreen), findsOneWidget);
      routes.router.go(AppRoutes.studentBasicInfo);
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyUsageTypeScreen), findsOneWidget);

      api.pendingUsage = Completer<void>();
      final next = find.text(AppLocalizationsAr().continueAction);
      await tester.tap(next);
      await tester.tap(next);
      expect(api.requests.where((r) => r.method == 'PUT'), hasLength(1));
      api.pendingUsage!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyBasicInfoScreen), findsOneWidget);

      api.rejectBasicInfo = true;
      final form = find.byType(HasobjyBasicInfoScreen);
      final fields = find.descendant(
        of: form,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'اسم تجريبي');
      await tester.enterText(fields.at(1), '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(form, findsOneWidget);
      expect(find.textContaining('رقم موبايل سوري'), findsOneWidget);
      expect(
        tester.widget<TextField>(fields.at(0)).controller?.text,
        'اسم تجريبي',
      );
      expect(tester.widget<TextField>(fields.at(1)).controller?.text, '123');

      api.next = 'device_unauthorized';
      await cubit.revalidateSession();
      await tester.pumpAndSettle();
      expect(find.text('هذا الحساب مرتبط بجهاز آخر'), findsOneWidget);
      await tester.ensureVisible(find.text('طلب تغيير الجهاز'));
      await tester.tap(find.text('طلب تغيير الجهاز'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'هاتفي السابق تالف');
      await tester.ensureVisible(find.text('إرسال الطلب'));
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pumpAndSettle();
      expect(find.text('طلبك قيد مراجعة الإدارة.'), findsOneWidget);
      expect(api.requests.last.jsonBody, {'reason': 'هاتفي السابق تالف'});
      routes.router.go(AppRoutes.studentUsage);
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyUsageTypeScreen), findsNothing);
      api.next = 'suspended';
      await cubit.revalidateSession();
      await tester.pumpAndSettle();
      expect(find.text('الحساب موقوف.'), findsOneWidget);

      await tester.tap(find.text(AppLocalizationsAr().signOut));
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyWelcomeScreen), findsOneWidget);
      expect(api.requests.last.path, 'auth/logout');
    },
  );

  test(
    'registration resumes saved choices and confirms via fresh session state',
    () async {
      final api = _Api()
        ..next = 'complete_registration'
        ..usageType = 'institute';
      final sessions = gateway(api);
      await sessions.start(_identity);
      final departments = (await sessions.departments(_identity))
          .getRight()
          .toNullable()!;
      expect(departments.single.years, [1, 2]);
      expect(
        await sessions.registrationSummary(_identity),
        isA<Right<StudentSessionFailure, StudentRegistrationSummary?>>().having(
          (result) => result.value,
          'summary',
          isNull,
        ),
      );
      final invalid = await sessions.saveAcademicInfo(
        _identity,
        departments.single.id,
        3,
      );
      expect(invalid.isLeft(), isTrue);
      expect(
        api.requests.where((request) => request.path == 'me/academic-info'),
        isEmpty,
      );
      final draft = await sessions.saveAcademicInfo(
        _identity,
        departments.single.id,
        2,
      );
      expect(draft.getRight().toNullable()?.semesterName, isNull);
      final restarted = gateway(api);
      await restarted.restore(_identity);
      final restored = await restarted.registrationSummary(_identity);
      expect(restored.getRight().toNullable()?.year, 2);
      final confirmed = await restarted.confirmRegistration(_identity);
      expect(confirmed.getRight().toNullable()?.next, StudentNextStep.home);
      expect(api.requests.last.path, 'me/session-state');
    },
  );

  test(
    'term confirmation and learning reads honor the server response',
    () async {
      final api = _Api()
        ..next = 'confirm_new_term'
        ..usageType = 'institute';
      final sessions = gateway(api);
      await sessions.start(_identity);
      final term = await sessions.termRegistration(_identity);
      expect(term.getRight().toNullable()?.semesterName, 'الفصل الفعلي');
      final confirmed = await sessions.confirmNewTerm(_identity);
      expect(confirmed.getRight().toNullable()?.next, StudentNextStep.home);
      final home = await sessions.home(_identity);
      expect(home.getRight().toNullable()?.subjects.single.percent, 50);
      expect(home.getRight().toNullable()?.resumeLesson?.lessonId, 'lesson');
      expect(home.getRight().toNullable()?.resumeLesson?.positionSeconds, 180);
      final courses = await sessions.courses(_identity, mine: true, page: 2);
      expect(
        courses.getRight().toNullable()?.courses.single.subscribed,
        isTrue,
      );
      expect(courses.getRight().toNullable()?.hasMore, isFalse);
      expect(api.requests.last.query, {
        'scope': 'mine',
        'page': '2',
        'limit': '20',
      });
    },
  );

  test(
    'profile patch sends only changed fields and leaves no-op saves local',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);
      final count = api.requests.length;
      expect((await sessions.updateProfile(_identity)).isRight(), isTrue);
      expect(api.requests, hasLength(count));
      final saved = await sessions.updateProfile(
        _identity,
        officialName: 'اسم جديد',
      );
      expect(saved.getRight().toNullable()?.name, 'اسم جديد');
      expect(saved.getRight().toNullable()?.phone, '+963955000002');
      final request = api.requests.last;
      expect(request.method, 'PATCH');
      expect(request.path, 'me');
      expect(request.jsonBody, {'officialName': 'اسم جديد'});
      final rejected = await sessions.updateProfile(
        _identity,
        phone: '0944000000',
      );
      expect(rejected.getLeft().toNullable(), StudentSessionFailure.phoneTaken);
    },
  );

  test(
    'profile patch distinguishes session restrictions from field errors',
    () async {
      final api = _Api();
      final sessions = gateway(api);
      await sessions.start(_identity);
      for (final (code, expected) in [
        ('ACCOUNT_SUSPENDED', StudentSessionFailure.accountSuspended),
        ('DEVICE_NOT_AUTHORIZED', StudentSessionFailure.deviceUnauthorized),
      ]) {
        api.profileDenial = code;
        final result = await sessions.updateProfile(
          _identity,
          officialName: 'اسم جديد',
        );
        expect(result.getLeft().toNullable(), expected);
      }
    },
  );

  for (final (code, next) in [
    ('ACCOUNT_SUSPENDED', StudentNextStep.suspended),
    ('DEVICE_NOT_AUTHORIZED', StudentNextStep.deviceUnauthorized),
    ('UNKNOWN_DENIAL', null),
  ]) {
    test('revalidating a session handles $code', () async {
      final api = _Api()..next = 'home';
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(_IdentityGateway()),
        messages: AppLocalizationsAr(),
        sessions: gateway(api),
      );
      addTearDown(cubit.close);
      await cubit.signIn();
      expect(
        (cubit.state as GoogleIdentityReady).session?.next,
        StudentNextStep.home,
      );

      api.sessionDenial = code;
      await cubit.revalidateSession();

      final verified = cubit.state as GoogleIdentityReady;
      expect(verified.session?.next, next);
      expect(
        verified.sessionFailure,
        next == null ? StudentSessionFailure.unavailable : null,
      );
    });
  }

  test(
    'network loss after commit retries the read without resending the choice',
    () async {
      final api = _Api();
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(_IdentityGateway()),
        messages: AppLocalizationsAr(),
        sessions: gateway(api),
      );
      addTearDown(cubit.close);
      await cubit.signIn();
      api.failNextRead = true;
      await cubit.chooseUsageType(StudentUsageType.courses);
      final failure = cubit.state as GoogleIdentityReady;
      expect(failure.session, isNull);
      expect(failure.sessionFailure, StudentSessionFailure.unavailable);
      await cubit.retrySession();
      expect(
        (cubit.state as GoogleIdentityReady).session?.next,
        StudentNextStep.completeBasicInfo,
      );
      expect(api.requests.where((r) => r.method == 'PUT'), hasLength(1));
    },
  );
}

String _refresh(int index) => 'test-only-refresh-token-$index';

final class _Proof implements FirebaseIdentityProofSource {
  @override
  Future<FirebaseIdentityProof> prepareForBackend({
    required String expectedFirebaseUid,
  }) async {
    expect(expectedFirebaseUid, _identity.firebaseUid);
    return const FirebaseIdentityProof(
      'firebase-test-proof',
      identity: _identity,
    );
  }
}

final class _Api implements ApiClient {
  final requests = <ApiRequest>[];
  bool rejectRefresh = false;
  String? rejectedAccess;
  String accessFailure = 'TOKEN_EXPIRED';
  Completer<void>? refreshStarted;
  Completer<void>? pendingRefresh;
  int exchanges = 0;
  String next = 'choose_usage_type';
  String? usageType;
  Completer<void>? pendingUsage;
  bool failNextRead = false;
  String? sessionDenial;
  bool rejectBasicInfo = false;
  int? academicYear;
  Object? deviceResponse;
  String? profileDenial;
  Completer<ApiCancellationToken?>? ticketReadStarted;
  Completer<void>? pendingTicketRead;
  Object? unreadCount = 0;
  String? viewerDenial;
  int? lessonDuration = 1620;
  int lessonPosition = 760;
  Completer<void>? pageStarted;
  Completer<void>? pendingPage;
  String? downloadUrl = 'https://storage.example.test/file.pdf';

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    requests.add(request);
    if (rejectedAccess != null &&
        request.headers['Authorization'] == rejectedAccess) {
      throw ApiFailure(ApiFailureKind.unauthenticated, code: accessFailure);
    }
    switch (request.path) {
      case 'auth/google':
      case 'auth/refresh':
        if (request.path == 'auth/refresh') {
          refreshStarted?.complete();
          await pendingRefresh?.future;
        }
        if (request.path == 'auth/refresh' && rejectRefresh) {
          throw const ApiFailure(
            ApiFailureKind.unauthenticated,
            code: 'INVALID_REFRESH_TOKEN',
          );
        }
        exchanges++;
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'accessToken': 'access-$exchanges',
              'refreshToken': _refresh(exchanges),
            },
          },
        );
      case 'me/usage-type':
        await pendingUsage?.future;
        usageType = (request.jsonBody as Map)['usageType'] as String;
        next = 'complete_basic_info';
        return const ApiResponse(statusCode: 200, requestId: 'test', json: {});
      case 'me/basic-info':
        if (rejectBasicInfo) {
          return ApiTransportPolicy(null).decode(
            400,
            '{"error":{"code":"VALIDATION_FAILED"}}'.codeUnits,
            'test',
          );
        }
        next = usageType == 'institute' ? 'complete_registration' : 'home';
        return const ApiResponse(statusCode: 200, requestId: 'test', json: {});
      case 'academic/departments':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': [
              {
                'id': 'department',
                'name': 'قسم الاختبار',
                'years': [1, 2, 3],
              },
            ],
          },
        );
      case 'me/academic-info':
        academicYear = (request.jsonBody as Map)['year'] as int;
        expect(request.jsonBody, {'departmentId': 'department', 'year': 2});
        return const ApiResponse(statusCode: 200, requestId: 'test', json: {});
      case 'me/registration-summary':
        if (academicYear == null) {
          throw const ApiFailure(
            ApiFailureKind.validation,
            code: 'INCOMPLETE_REGISTRATION',
          );
        }
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'student': {'officialName': 'اسم تجريبي'},
              'department': {'id': 'department', 'name': 'قسم الاختبار'},
              'year': academicYear,
              'semester': null,
            },
          },
        );
      case 'me/registration/confirm':
        next = 'home';
        return const ApiResponse(statusCode: 200, requestId: 'test', json: {});
      case 'me/term-reregistration':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'department': {'name': 'القسم الفعلي'},
              'year': 2,
              'semester': {
                'name': 'الفصل الفعلي',
                'startDate': '2026-11-12',
                'endDate': '2027-02-01',
              },
              'status': 'pending',
            },
          },
        );
      case 'me/term-reregistration/confirm':
        next = 'home';
        return const ApiResponse(statusCode: 200, requestId: 'test', json: {});
      case 'home':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'name': 'اسم تجريبي',
              'continueWatching': [
                {
                  'lessonId': 'lesson',
                  'lessonTitle': 'درس',
                  'subjectId': 'subject',
                  'subjectName': 'مادة',
                  'positionSeconds': 180,
                  'durationSeconds': 900,
                },
              ],
              'subjects': [
                {
                  'id': 'subject',
                  'name': 'مادة',
                  'progress': {'total': 4, 'completed': 2, 'percent': 50},
                },
              ],
              'courses': [
                {'id': 'course', 'name': 'كورس'},
              ],
            },
          },
        );
      case 'courses':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': [
              {
                'id': 'course',
                'name': 'كورس',
                'description': null,
                'priceUsd': '15.00',
                'durationDays': 30,
                'subscribed': true,
              },
            ],
            'meta': {'page': 2, 'limit': 20, 'total': 21},
          },
        );
      case 'lessons/lesson':
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'title': 'درس الاختبار',
              'description': null,
              'locked': false,
              'videoReady': true,
              'durationSeconds': lessonDuration,
              'positionSeconds': lessonPosition,
              'next': null,
            },
          },
        );
      case 'files/file/download':
        final url = downloadUrl;
        if (url == null) throw const ApiFailure(ApiFailureKind.forbidden);
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'url': url,
              'expiresAt': DateTime.now()
                  .add(const Duration(minutes: 2))
                  .toIso8601String(),
            },
          },
        );
      case 'files/file/view-session':
        if (viewerDenial case final code?) {
          throw ApiFailure(ApiFailureKind.forbidden, code: code);
        }
        return ApiResponse(
          statusCode: 201,
          requestId: 'test',
          json: {
            'data': {
              'token': 'test-view-token',
              'expiresAt': DateTime.now()
                  .add(const Duration(minutes: 2))
                  .toIso8601String(),
              'pages': 3,
            },
          },
        );
      case 'files/file/pages/1':
      case 'files/file/pages/2':
        pageStarted?.complete();
        await pendingPage?.future;
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: const {},
          imageBytes: Uint8List.fromList([1, 2, 3]),
          totalPages: 3,
        );
      case 'me/notifications/unread-count':
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {'count': unreadCount},
          },
        );
      case 'support/tickets/ticket':
        ticketReadStarted?.complete(cancellationToken);
        await pendingTicketRead?.future;
        return const ApiResponse(statusCode: 200, json: {}, requestId: 'test');
      case 'me/subscriptions':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': [
              {
                'scopeName': 'كورس',
                'scopeType': 'course',
                'state': 'expired',
                'startsAt': '2026-10-10T00:00:00Z',
                'expiresAt': '2026-11-10T00:00:00Z',
                'daysLeft': 0,
              },
            ],
          },
        );
      case 'me/device-change-requests/current':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {'data': null},
        );
      case 'me/device-change-requests':
        return const ApiResponse(
          statusCode: 201,
          requestId: 'test',
          json: {
            'data': {'status': 'pending'},
          },
        );
      case 'me/device':
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {'data': deviceResponse},
        );
      case 'me':
        if (profileDenial case final code?) {
          throw ApiFailure(ApiFailureKind.forbidden, code: code);
        }
        final changes = request.jsonBody as Map;
        if (changes.containsKey('phone')) {
          throw const ApiFailure(ApiFailureKind.conflict, code: 'PHONE_TAKEN');
        }
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'displayName': 'طالب اختبار',
              'officialName': changes['officialName'],
              'email': 'student@example.test',
              'phone': '+963955000002',
              'department': null,
              'year': null,
            },
          },
        );
      case 'me/session-state':
        if (sessionDenial case final code?) {
          throw ApiFailure(ApiFailureKind.forbidden, code: code);
        }
        if (failNextRead) {
          failNextRead = false;
          throw const ApiFailure(ApiFailureKind.network);
        }
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {'next': next, 'usageType': usageType},
          },
        );
      case 'auth/logout':
        return const ApiResponse(statusCode: 204, requestId: 'test', json: {});
      default:
        throw StateError('Unexpected path');
    }
  }

  @override
  void close() {}
}

final class _IdentityGateway implements GoogleIdentityGateway {
  @override
  bool get isConfigured => true;

  @override
  Future<GoogleIdentity> authenticate() async => _identity;

  @override
  Future<GoogleIdentity?> restoreIdentity() async => _identity;

  @override
  Future<void> signOut() async {}
}
