import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../debug/safe_debug_log.dart';
import 'api_cancellation_token.dart';
import 'api_client.dart';
import 'api_failure.dart';
import 'api_request.dart';
import 'api_request_scope.dart';
import 'api_transport_policy.dart';

/// Dio remains private: no SDK options, exceptions or response types escape.
class DioApiClient implements ApiClient {
  DioApiClient(
    Uri? baseUrl, {
    Duration timeout = const Duration(seconds: 15),
    int maxResponseBytes = 1024 * 1024,
    bool allowLocalHttp = false,
  }) : _policy = ApiTransportPolicy(
         baseUrl,
         timeout: timeout,
         maxResponseBytes: maxResponseBytes,
         allowLocalHttp: allowLocalHttp,
       ),
       _dio = Dio() {
    _dio.options = BaseOptions(
      connectTimeout: timeout,
      sendTimeout: timeout,
      receiveTimeout: timeout,
    );
  }

  final ApiTransportPolicy _policy;
  final Dio _dio;
  final _active = <ApiRequestScope>{};
  bool _closed = false;

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    for (final scope in List.of(_active)) {
      scope.stop(ApiFailureKind.canceled);
    }
    _dio.close(force: true);
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
      'body': request.jsonBody is Map<String, Object?>
          ? request.jsonBody! as Map<String, Object?>
          : {'payload': request.jsonBody?.runtimeType.toString()},
    });
    final cancel = CancelToken();
    scope.onAbort(() => cancel.cancel());
    _active.add(scope);
    try {
      return await scope.run(() async {
        scope.throwIfStopped();
        final response = await _dio.requestUri<ResponseBody>(
          uri,
          data: request.jsonBody == null ? null : jsonEncode(request.jsonBody),
          cancelToken: cancel,
          options: Options(
            method: request.method,
            responseType: ResponseType.stream,
            followRedirects: false,
            validateStatus: (_) => true,
            contentType: request.jsonBody == null
                ? null
                : Headers.jsonContentType,
            headers: {
              ...request.headers,
              'Accept': 'application/json',
              'X-Request-ID': scope.requestId,
            },
          ),
        );
        final body = response.data;
        if (body == null || response.statusCode == null) {
          throw ApiFailure(
            ApiFailureKind.invalidResponse,
            requestId: scope.requestId,
          );
        }
        final ids = response.headers['X-Request-ID'];
        final responseId =
            ApiTransportPolicy.safeIdentifier(
              ids?.length == 1 ? ids!.single : null,
            ) ??
            scope.requestId;
        final bytes = await scope.readLimited(
          body.stream,
          _policy.maxResponseBytes,
        );
        return _policy.decode(
          response.statusCode!,
          bytes,
          responseId,
          requestId: scope.requestId,
          stopwatch: stopwatch,
        );
      });
    } catch (error) {
      cancel.cancel();
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
        DioException(
          type: DioExceptionType.connectionTimeout ||
              DioExceptionType.sendTimeout ||
              DioExceptionType.receiveTimeout,
        ) =>
          ApiFailureKind.timeout,
        DioException(type: DioExceptionType.cancel) => ApiFailureKind.canceled,
        DioException(
          type: DioExceptionType.connectionError ||
              DioExceptionType.badCertificate,
        ) =>
          ApiFailureKind.network,
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
