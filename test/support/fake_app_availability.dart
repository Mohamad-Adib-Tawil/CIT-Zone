import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/features/app_status/domain/app_availability.dart';
import 'package:cit_zone/features/app_status/domain/app_availability_repository.dart';

class FakeMobileAppGateway implements MobileAppGateway {
  @override
  Future<MobileAppInfo> readInfo() async =>
      const MobileAppInfo(platform: MobilePlatform.android, version: '1.0.0');
  @override
  Future<bool> openStore(Uri url) async => false;
}

class FakeAvailableApiClient implements ApiClient {
  @override
  void close() {}
  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    if (request.path != 'app/config') {
      throw StateError('Unexpected test request');
    }
    return const ApiResponse(
      statusCode: 200,
      requestId: 'availability-test',
      json: {
        'data': {
          'maintenance': {'enabled': false, 'message': ''},
          'platforms': {
            'android': {'minVersion': '1.0.0', 'storeUrl': null},
          },
        },
      },
    );
  }
}
