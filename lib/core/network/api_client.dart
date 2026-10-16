import 'api_cancellation_token.dart';
import 'api_request.dart';

abstract class ApiClient {
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  });

  /// Aborts outstanding requests and releases this client's transport resources.
  void close();
}
