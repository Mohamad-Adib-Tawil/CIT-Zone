import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/network/dio_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final configuration = AppConfiguration.parse(
    environment: AppEnvironment.parse(stageName: 'development', apiBaseUrl: ''),
    debugBuild: true,
  );
  test(
    'API transport stays lazy, is shared and closes exactly once if resolved',
    () async {
      var creations = 0;
      final client = _Client();
      AppDependencies create() => AppDependencies(
        configuration: configuration,
        apiClientFactory: () {
          creations++;
          return client;
        },
      );
      final unused = create();
      await unused.dispose();
      expect(creations, 0);
      expect(client.closes, 0);
      final used = create();
      expect(used.apiClient, same(used.apiClient));
      expect(creations, 1);
      await used.dispose();
      await used.dispose();
      expect(client.closes, 1);
      expect(() => used.apiClient, throwsStateError);
    },
  );

  test(
    'default transport is Dio and no endpoint remains unconfigured',
    () async {
      final root = AppDependencies(configuration: configuration);
      addTearDown(root.dispose);
      expect(root.apiClient, isA<DioApiClient>());
      await expectLater(
        root.apiClient.send(const ApiRequest(method: 'GET', path: 'items')),
        throwsA(
          isA<ApiFailure>().having(
            (error) => error.kind,
            'kind',
            ApiFailureKind.configuration,
          ),
        ),
      );
    },
  );
}

class _Client implements ApiClient {
  int closes = 0;
  @override
  void close() => closes++;
  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async => throw const ApiFailure(ApiFailureKind.configuration);
}
