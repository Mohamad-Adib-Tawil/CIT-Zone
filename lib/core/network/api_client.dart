import 'api_cancellation_token.dart';
import 'api_request.dart';

abstract class ApiClient {
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  });
}
