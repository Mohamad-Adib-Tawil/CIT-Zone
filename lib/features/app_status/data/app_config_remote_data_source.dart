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
    final request = ApiRequest(
      method: 'GET',
      path: 'app/config',
      // The public CDN cache varies by URL, while the API reads headers.
      query: {'platform': info.platform.name, 'version': info.version},
      headers: {
        'X-App-Platform': info.platform.name,
        'X-App-Version': info.version,
      },
    );
    final elapsed = Stopwatch()..start();
    ApiResponse response;
    try {
      response = await _client.send(
        request,
        cancellationToken: cancellationToken,
      );
    } on ApiFailure catch (failure) {
      if (failure.kind != ApiFailureKind.network ||
          elapsed.elapsed >= const Duration(seconds: 2)) {
        rethrow;
      }
      _ensureActive(cancellationToken);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _ensureActive(cancellationToken);
      response = await _client.send(
        request,
        cancellationToken: cancellationToken,
      );
    }
    // A custom transport may finish after cancellation. Never accept its result.
    _ensureActive(cancellationToken);
    return decodeAppAvailability(response.json, info);
  }

  static void _ensureActive(ApiCancellationToken token) {
    if (token.isCanceled) throw const ApiFailure(ApiFailureKind.canceled);
  }
}
