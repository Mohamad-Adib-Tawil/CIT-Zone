import '../../../core/network/api_cancellation_token.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_request.dart';
import '../domain/app_availability.dart';
import 'app_availability_decoder.dart';

/// API service for the established app/config contract, independent of session.
final class AppConfigRemoteDataSource {
  const AppConfigRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AppAvailability> fetch(
    MobileAppInfo info, {
    required ApiCancellationToken cancellationToken,
  }) async {
    _ensureActive(cancellationToken);
    final response = await _client.send(
      ApiRequest(
        method: 'GET',
        path: 'app/config',
        headers: {
          'X-Platform': info.platform.name,
          'X-App-Version': info.version,
        },
      ),
      cancellationToken: cancellationToken,
    );
    // A custom transport may finish after cancellation. Never accept its result.
    _ensureActive(cancellationToken);
    return decodeAppAvailability(response.json, info);
  }

  static void _ensureActive(ApiCancellationToken token) {
    if (token.isCanceled) throw const ApiFailure(ApiFailureKind.canceled);
  }
}
