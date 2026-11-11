import 'dart:async';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/features/app_status/data/api_app_availability_repository.dart';
import 'package:cit_zone/features/app_status/data/app_config_remote_data_source.dart';
import 'package:cit_zone/features/app_status/domain/app_availability.dart';
import 'package:cit_zone/features/app_status/domain/app_availability_repository.dart';
import 'package:cit_zone/features/app_status/presentation/cubit/app_availability_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const _info = MobileAppInfo(platform: MobilePlatform.android, version: '1.0.0');
const _response = ApiResponse(
  statusCode: 200,
  requestId: 'test',
  json: {
    'data': {
      'maintenance': {'enabled': false, 'message': ''},
      'platforms': {
        'android': {'minVersion': '1.0.0', 'storeUrl': null},
      },
    },
  },
);

void main() {
  test(
    'all transport failures become domain failures without raw metadata',
    () async {
      for (final kind in ApiFailureKind.values) {
        final repository = _repository(
          _Client((_, _) async => throw ApiFailure(kind, code: 'private-code')),
        );
        final result = await repository.check();
        final expected = switch (kind) {
          ApiFailureKind.network ||
          ApiFailureKind.timeout => AppAvailabilityFailure.network,
          ApiFailureKind.invalidResponse =>
            AppAvailabilityFailure.invalidResponse,
          _ => AppAvailabilityFailure.unavailable,
        };
        expect(result, Left<AppAvailabilityFailure, AppAvailability>(expected));
      }
    },
  );

  test('established blocking API codes never become available', () async {
    for (final entry in {
      'APP_UPDATE_REQUIRED': AppAvailabilityKind.updateRequired,
      'MAINTENANCE': AppAvailabilityKind.maintenance,
    }.entries) {
      final result = await _repository(
        _Client(
          (_, _) async =>
              throw ApiFailure(ApiFailureKind.forbidden, code: entry.key),
        ),
      ).check();
      expect(result.match((_) => null, (value) => value.kind), entry.value);
    }
  });

  test('cancellation during native info prevents any request', () async {
    final pending = Completer<MobileAppInfo>();
    final client = _Client((_, _) async => _response);
    final repository = _repository(
      client,
      _Gateway(info: () => pending.future),
    );
    final checking = repository.check();
    repository.cancel();
    pending.complete(_info);
    expect(
      await checking,
      const Left<AppAvailabilityFailure, AppAvailability>(
        AppAvailabilityFailure.unavailable,
      ),
    );
    expect(client.calls, 0);
  });

  test('a late response after cancellation cannot allow app entry', () async {
    final sent = Completer<void>();
    final pending = Completer<ApiResponse>();
    ApiCancellationToken? token;
    final repository = _repository(
      _Client((_, current) {
        token = current;
        sent.complete();
        return pending.future;
      }),
    );
    final checking = repository.check();
    await sent.future;
    repository.cancel();
    expect(token!.isCanceled, isTrue);
    // Deliberately ignore cancellation as a custom transport might do.
    pending.complete(_response);
    expect(
      await checking,
      const Left<AppAvailabilityFailure, AppAvailability>(
        AppAvailabilityFailure.unavailable,
      ),
    );
  });

  test('replacing a request cancels only its predecessor', () async {
    final sent = Completer<void>();
    final firstResponse = Completer<ApiResponse>();
    final tokens = <ApiCancellationToken>[];
    final repository = _repository(
      _Client((_, token) {
        tokens.add(token!);
        if (tokens.length == 1) {
          sent.complete();
          return firstResponse.future;
        }
        return Future.value(_response);
      }),
    );
    final first = repository.check();
    await sent.future;
    final second = await repository.check();
    expect(second, isA<Right<AppAvailabilityFailure, AppAvailability>>());
    expect(tokens.first.isCanceled, isTrue);
    expect(tokens.last.isCanceled, isFalse);
    firstResponse.complete(_response);
    expect(await first, isA<Left<AppAvailabilityFailure, AppAvailability>>());
  });

  test('malformed data and native exceptions fail closed', () async {
    final malformed = await _repository(
      _Client(
        (_, _) async =>
            const ApiResponse(statusCode: 200, json: {}, requestId: 'test'),
      ),
    ).check();
    expect(
      malformed,
      const Left<AppAvailabilityFailure, AppAvailability>(
        AppAvailabilityFailure.invalidResponse,
      ),
    );
    final native = await _repository(
      _Client((_, _) async => _response),
      _Gateway(info: () async => throw StateError('private-platform-details')),
    ).check();
    expect(
      native,
      const Left<AppAvailabilityFailure, AppAvailability>(
        AppAvailabilityFailure.unavailable,
      ),
    );
  });

  test(
    'invalid store links and platform exceptions are contained by repository',
    () async {
      var calls = 0;
      final repository = _repository(
        _Client((_, _) async => _response),
        _Gateway(
          store: (_) async {
            calls++;
            throw StateError('native-details');
          },
        ),
      );
      expect(
        await repository.openStore(Uri.parse('https://evil.example')),
        isFalse,
      );
      expect(calls, 0);
      expect(
        await repository.openStore(Uri.parse('https://play.google.com/store')),
        isFalse,
      );
      expect(calls, 1);
      final cubit = AppAvailabilityCubit(repository);
      await cubit.close();
      await cubit.check();
      expect(await cubit.openStore(), isFalse);
      expect(calls, 1);
    },
  );
}

ApiAppAvailabilityRepository _repository(_Client client, [_Gateway? gateway]) =>
    ApiAppAvailabilityRepository(
      AppConfigRemoteDataSource(client),
      gateway ?? _Gateway(),
    );

class _Client implements ApiClient {
  _Client(this.operation);
  final Future<ApiResponse> Function(ApiRequest, ApiCancellationToken?)
  operation;
  int calls = 0;

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) {
    calls++;
    return operation(request, cancellationToken);
  }

  @override
  void close() {}
}

class _Gateway implements MobileAppGateway {
  _Gateway({this.info, this.store});
  final Future<MobileAppInfo> Function()? info;
  final Future<bool> Function(Uri)? store;

  @override
  Future<MobileAppInfo> readInfo() async => await info?.call() ?? _info;

  @override
  Future<bool> openStore(Uri url) async => await store?.call(url) ?? true;
}
