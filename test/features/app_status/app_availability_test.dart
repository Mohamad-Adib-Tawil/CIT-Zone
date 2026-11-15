import 'dart:async';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/features/app_status/data/api_app_availability_repository.dart';
import 'package:cit_zone/features/app_status/data/app_config_remote_data_source.dart';
import 'package:cit_zone/features/app_status/data/app_availability_decoder.dart';
import 'package:cit_zone/features/app_status/data/native_mobile_app_gateway.dart';
import 'package:cit_zone/features/app_status/domain/app_availability.dart';
import 'package:cit_zone/features/app_status/domain/app_availability_repository.dart';
import 'package:cit_zone/features/app_status/presentation/cubit/app_availability_cubit.dart';
import 'package:cit_zone/features/app_status/presentation/widgets/app_availability_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hasobjy_test_app.dart';

Map<String, dynamic> config({
  String minimum = '1.0.0',
  bool maintenance = false,
  Object? storeUrl,
}) => {
  'data': {
    'maintenance': {
      'enabled': maintenance,
      'message': maintenance ? 'صيانة خادمية' : '',
    },
    'platform': null,
    'minVersion': null,
    'storeUrl': null,
    'updateRequired': null,
    'platforms': {
      'android': {'minVersion': minimum, 'storeUrl': storeUrl},
      'ios': {'minVersion': '2.0.0', 'storeUrl': null},
    },
  },
};

const info = MobileAppInfo(platform: MobilePlatform.android, version: '1.0.0');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);

  test('version comparison is numeric and ignores build metadata', () {
    expect(
      AppVersion.parse('1.10.0').compareTo(AppVersion.parse('1.9.99')),
      greaterThan(0),
    );
    expect(
      AppVersion.parse('1.0.0+42').compareTo(AppVersion.parse('1.0.0+1')),
      0,
    );
    for (final invalid in [
      '1.0',
      '1.0.0-beta',
      '-1.0.0',
      '01.0.0',
      '1.0.0\n',
    ]) {
      expect(() => AppVersion.parse(invalid), throwsFormatException);
    }
  });

  test(
    'uses current platform and rejects versions under the server minimum',
    () {
      expect(
        decodeAppAvailability(config(), info).kind,
        AppAvailabilityKind.available,
      );
      expect(
        decodeAppAvailability(config(minimum: '1.0.1'), info).kind,
        AppAvailabilityKind.updateRequired,
      );
      expect(
        decodeAppAvailability(config(minimum: '0.9.9'), info).kind,
        AppAvailabilityKind.available,
      );
      expect(
        decodeAppAvailability(
          config(),
          const MobileAppInfo(platform: MobilePlatform.ios, version: '1.9.0'),
        ).kind,
        AppAvailabilityKind.updateRequired,
      );
    },
  );

  test(
    'maintenance uses server message and blocks even a supported version',
    () {
      final value = decodeAppAvailability(config(maintenance: true), info);
      expect(value.kind, AppAvailabilityKind.maintenance);
      expect(value.message, 'صيانة خادمية');
    },
  );

  test('malformed policy never silently allows entry', () {
    final fixtures = [
      <String, dynamic>{},
      {'data': <String, dynamic>{}},
      config(minimum: 'latest'),
      config(storeUrl: 'https://evil.example/install'),
      config(storeUrl: 'https://play.google.com@evil.example/install'),
      config(storeUrl: 'javascript:alert(1)'),
      config(storeUrl: 'https://apps.apple.com/app/id123'),
      config(
        storeUrl: 'https://play.google.com/store/apps/details?id=other.app',
      ),
      config(
        storeUrl: 'https://play.google.com/store/apps/details?id=com.devmind.cit.learn&id=other.app',
      ),
      config(storeUrl: 'https://play.google.com/store/search?q=hasobjy'),
    ];
    for (final fixture in fixtures) {
      expect(() => decodeAppAvailability(fixture, info), throwsFormatException);
    }
    expect(
      decodeAppAvailability(config(minimum: '2.0.0'), info).storeUrl,
      isNull,
    );
  });

  test('store URLs must be HTTPS and use a known host', () {
    expect(
      isAppStoreUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.devmind.cit.learn',
        ),
      ),
      isTrue,
    );
    expect(
      isAppStoreUrl(Uri.parse('https://apps.apple.com/app/id123')),
      isTrue,
    );
    for (final value in [
      'http://play.google.com',
      'https://play.google.com:99/',
      'https://user@play.google.com/',
      'https://play.google.com.evil.example/',
    ]) {
      expect(isAppStoreUrl(Uri.parse(value)), isFalse);
    }
  });

  test('native adapter reads installed version and rejects bad links before channel call', () async {
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeMobileAppGateway.channel, (call) async {
          methods.add(call.method);
          return call.method == 'appInfo'
              ? {'platform': 'android', 'version': '1.2.3'}
              : true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeMobileAppGateway.channel, null),
    );
    const gateway = NativeMobileAppGateway();
    expect((await gateway.readInfo()).version, '1.2.3');
    expect(await gateway.openStore(Uri.parse('https://evil.example')), isFalse);
    expect(methods, ['appInfo']);
    expect(
      await gateway.openStore(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.devmind.cit.learn',
        ),
      ),
      isTrue,
    );
  });

  test('repository sends platform/version, decodes envelope, and maps network failures', () async {
    final client = _Client();
    final repository = ApiAppAvailabilityRepository(
      AppConfigRemoteDataSource(client),
      _Gateway(),
    );
    final result = await repository.check();
    expect(result, isA<Right<AppAvailabilityFailure, AppAvailability>>());
    expect(client.request!.path, 'app/config');
    expect(client.request!.headers, {
      'X-Platform': 'android',
      'X-App-Version': '1.0.0',
    });
    client.failure = const ApiFailure(ApiFailureKind.timeout);
    final failure =
        await repository.check()
            as Left<AppAvailabilityFailure, AppAvailability>;
    expect(failure.value, AppAvailabilityFailure.network);
  });

  test('cubit deduplicates requests and cancels on close', () async {
    final repository = _Repository();
    final cubit = AppAvailabilityCubit(repository);
    final first = cubit.check();
    final duplicate = cubit.check();
    expect(identical(first, duplicate), isTrue);
    expect(repository.calls, 1);
    await cubit.close();
    expect(repository.canceled, isTrue);
    repository.pending.complete(
      const Right(AppAvailability(AppAvailabilityKind.available)),
    );
    await first;
    expect(cubit.state, isA<AppAvailabilityLoading>());
  });

  testWidgets(
    'gate hides entry until verified, retry recovers without showing demo data',
    (tester) async {
      final repository = _Repository();
      final cubit = AppAvailabilityCubit(repository);
      var restores = 0;
      addTearDown(cubit.close);
      await tester.pumpWidget(
        arabicTestApp(
          AppAvailabilityGate(
            cubit: cubit,
            onFirstAvailable: () async {
              restores++;
            },
            child: const Text('verified entry'),
          ),
        ),
      );
      expect(find.text('verified entry'), findsNothing);
      repository.pending.complete(const Left(AppAvailabilityFailure.network));
      await tester.pumpAndSettle();
      expect(find.text('verified entry'), findsNothing);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(restores, 0);
      repository.pending = Completer();
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();
      expect(repository.calls, 2);
      repository.pending.complete(
        const Right(AppAvailability(AppAvailabilityKind.available)),
      );
      await tester.pumpAndSettle();
      expect(find.text('verified entry'), findsOneWidget);
      expect(restores, 1);
    },
  );

  testWidgets('store launch failure offers a fresh policy check', (
    tester,
  ) async {
    final repository = _Repository()..canOpenStore = false;
    final cubit = AppAvailabilityCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      arabicTestApp(
        AppAvailabilityGate(cubit: cubit, child: const Text('verified entry')),
      ),
    );
    repository.pending.complete(
      Right(
        AppAvailability(
          AppAvailabilityKind.updateRequired,
          storeUrl: Uri.parse(
            'https://play.google.com/store/apps/details?id=com.devmind.cit.learn',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحديث الآن'));
    await tester.pumpAndSettle();
    expect(repository.storeCalls, 1);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('verified entry'), findsNothing);
  });

  testWidgets('resume keeps the active screen until the server blocks it', (
    tester,
  ) async {
    final repository = _Repository();
    final cubit = AppAvailabilityCubit(repository);
    var sessionChecks = 0;
    addTearDown(cubit.close);
    await tester.pumpWidget(
      arabicTestApp(
        AppAvailabilityGate(
          cubit: cubit,
          onAvailableAfterResume: () async {
            sessionChecks++;
          },
          child: const Scaffold(body: TextField()),
        ),
      ),
    );
    repository.pending.complete(
      const Right(AppAvailability(AppAvailabilityKind.available)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'مسودة الطالب');

    repository.pending = Completer();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.calls, 2);
    expect(sessionChecks, 0);
    expect(find.text('مسودة الطالب'), findsOneWidget);

    repository.pending.complete(
      const Right(AppAvailability(AppAvailabilityKind.available)),
    );
    await tester.pumpAndSettle();
    expect(find.text('مسودة الطالب'), findsOneWidget);

    repository.pending = Completer();
    expect(sessionChecks, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    repository.pending.complete(
      const Right(AppAvailability(AppAvailabilityKind.maintenance)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(sessionChecks, 1);
  });

  for (final kind in [
    AppAvailabilityKind.maintenance,
    AppAvailabilityKind.updateRequired,
  ]) {
    testWidgets('$kind cannot expose protected entry', (tester) async {
      final repository = _Repository();
      final cubit = AppAvailabilityCubit(repository);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        arabicTestApp(
          AppAvailabilityGate(
            cubit: cubit,
            child: const Text('verified entry'),
          ),
        ),
      );
      repository.pending.complete(Right(AppAvailability(kind)));
      await tester.pumpAndSettle();
      expect(find.text('verified entry'), findsNothing);
      if (kind == AppAvailabilityKind.updateRequired) {
        expect(find.text('تحديث الآن'), findsNothing);
        repository.pending = Completer();
        await tester.tap(find.text('إعادة المحاولة'));
        await tester.pump();
        expect(repository.storeCalls, 0);
        expect(repository.calls, 2);
        expect(find.text('verified entry'), findsNothing);
        repository.pending.complete(
          const Right(AppAvailability(AppAvailabilityKind.available)),
        );
        await tester.pumpAndSettle();
        expect(find.text('verified entry'), findsOneWidget);
      }
    });
  }
}

class _Gateway implements MobileAppGateway {
  @override
  Future<MobileAppInfo> readInfo() async => info;
  @override
  Future<bool> openStore(Uri url) async => true;
}

class _Client implements ApiClient {
  ApiRequest? request;
  ApiFailure? failure;
  @override
  void close() {}
  @override
  Future<ApiResponse> send(
    ApiRequest value, {
    ApiCancellationToken? cancellationToken,
  }) async {
    request = value;
    if (failure != null) throw failure!;
    return ApiResponse(statusCode: 200, json: config(), requestId: 'test');
  }
}

class _Repository implements AppAvailabilityRepository {
  Completer<Either<AppAvailabilityFailure, AppAvailability>> pending =
      Completer();
  int calls = 0;
  int storeCalls = 0;
  bool canceled = false;
  bool canOpenStore = true;
  @override
  void cancel() => canceled = true;
  @override
  Future<Either<AppAvailabilityFailure, AppAvailability>> check() {
    calls++;
    return pending.future;
  }

  @override
  Future<bool> openStore(Uri url) async {
    storeCalls++;
    return canOpenStore;
  }
}
