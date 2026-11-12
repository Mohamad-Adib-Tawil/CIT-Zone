import 'dart:convert';
import 'dart:io';

import '../debug/safe_debug_log.dart';
import 'api_cancellation_token.dart';
import 'api_client.dart';
import 'api_failure.dart';
import 'api_request.dart';
import 'api_request_scope.dart';
import 'api_transport_policy.dart';

class IoApiClient implements ApiClient {
  IoApiClient(
    Uri? baseUrl, {
    Duration timeout = const Duration(seconds: 15),
    int maxResponseBytes = 1024 * 1024,
    bool allowLocalHttp = false,
    HttpClient? httpClient,
  }) : _policy = ApiTransportPolicy(
         baseUrl,
         timeout: timeout,
         maxResponseBytes: maxResponseBytes,
         allowLocalHttp: allowLocalHttp,
       ),
       _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = timeout;
  }

  final ApiTransportPolicy _policy;
  final HttpClient _httpClient;
  final _active = <ApiRequestScope>{};
  bool _closed = false;

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    for (final scope in List.of(_active)) {
      scope.stop(ApiFailureKind.canceled);
    }
    _httpClient.close(force: true);
  }

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    if (_closed) throw const ApiFailure(ApiFailureKind.configuration);
    final uri = _policy.resolve(request);
    final stopwatch = Stopwatch()..start();
    if (cancellationToken?.isCanceled == true) {
      SafeDebugLog.event('API', 'failure', {'kind': 'canceled'});
      throw const ApiFailure(ApiFailureKind.canceled);
    }
    final scope = ApiRequestScope(
      timeout: _policy.timeout,
      requestId: ApiTransportPolicy.newRequestId(),
      cancellationToken: cancellationToken,
    );
    SafeDebugLog.event('API', 'request', {
      'request_id': scope.requestId,
      'method': request.method,
      'path': '${uri.path}${uri.hasQuery ? '?[QUERY]' : ''}',
      'headers': request.headers,
      'body': request.jsonBody is Map
          ? request.jsonBody! as Map
          : {'payload_type': request.jsonBody?.runtimeType.toString()},
    });
    _active.add(scope);
    HttpClientRequest? outgoing;
    try {
      return await scope.run(() async {
        scope.throwIfStopped();
        outgoing = await _httpClient.openUrl(request.method, uri);
        scope.onAbort(() => outgoing!.abort());
        scope.throwIfStopped();
        outgoing!.followRedirects = false;
        request.headers.forEach(outgoing!.headers.set);
        outgoing!.headers.set(HttpHeaders.acceptHeader, 'application/json');
        outgoing!.headers.set('X-Request-ID', scope.requestId);
        if (request.jsonBody != null) {
          outgoing!.headers.contentType = ContentType.json;
          outgoing!.write(jsonEncode(request.jsonBody));
        }
        final response = await outgoing!.close();
        final ids = response.headers['X-Request-ID'];
        final responseId =
            ApiTransportPolicy.safeIdentifier(
              ids?.length == 1 ? ids!.single : null,
            ) ??
            scope.requestId;
        final bytes = await scope.readLimited(
          response,
          _policy.maxResponseBytes,
        );
        final decoded = _policy.decode(response.statusCode, bytes, responseId);
        SafeDebugLog.event('API', 'response', {
          'status': decoded.statusCode,
          'request_id': scope.requestId,
          'response_request_id': decoded.requestId,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'body': decoded.json,
        });
        return decoded;
      });
    } catch (error) {
      outgoing?.abort();
      try {
        scope.throwIfStopped();
      } on ApiFailure catch (failure) {
        SafeDebugLog.event('API', 'failure', {
          'kind': failure.kind.name,
          'request_id': failure.requestId,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });
        rethrow;
      }
      if (error is ApiFailure) {
        SafeDebugLog.event('API', 'failure', {
          'kind': error.kind.name,
          'status': error.statusCode,
          'code': error.code,
          'request_id': error.requestId,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });
        rethrow;
      }
      final kind = switch (error) {
        SocketException() ||
        HandshakeException() ||
        HttpException() => ApiFailureKind.network,
        FormatException() => ApiFailureKind.invalidResponse,
        _ => ApiFailureKind.unexpected,
      };
      SafeDebugLog.event('API', 'failure', {
        'kind': kind.name,
        'request_id': scope.requestId,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      throw ApiFailure(kind, requestId: scope.requestId);
    } finally {
      _active.remove(scope);
    }
  }
}
