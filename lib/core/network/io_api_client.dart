import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'api_cancellation_token.dart';
import 'api_client.dart';
import 'api_failure.dart';
import 'api_request.dart';

class IoApiClient implements ApiClient {
  IoApiClient(
    Uri? baseUrl, {
    Duration timeout = const Duration(seconds: 15),
    int maxResponseBytes = 1024 * 1024,
    bool allowLocalHttp = false,
    HttpClient? httpClient,
  }) : _baseUrl = _validatedBaseUrl(baseUrl, allowLocalHttp),
       _timeout = timeout,
       _maxResponseBytes = maxResponseBytes,
       _httpClient = httpClient ?? HttpClient() {
    if (timeout <= Duration.zero || maxResponseBytes < 1) {
      throw ArgumentError('A positive timeout and response limit are required');
    }
    _httpClient.connectionTimeout = timeout;
  }

  final Uri? _baseUrl;
  final Duration _timeout;
  final int _maxResponseBytes;
  final HttpClient _httpClient;

  static Uri? _validatedBaseUrl(Uri? baseUrl, bool allowLocalHttp) {
    if (baseUrl == null) return null;
    final localHttp =
        allowLocalHttp &&
        baseUrl.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '::1'}.contains(baseUrl.host);
    if (!baseUrl.hasAuthority ||
        baseUrl.host.isEmpty ||
        !baseUrl.path.endsWith('/') ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        (baseUrl.scheme != 'https' && !localHttp)) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'HTTPS is required');
    }
    return baseUrl;
  }

  void close() => _httpClient.close(force: true);

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      throw const ApiFailure(ApiFailureKind.configuration);
    }
    final uri = _resolveUri(baseUrl, request);
    if (cancellationToken?.isCanceled == true) {
      throw const ApiFailure(ApiFailureKind.canceled);
    }

    final requestId = _newRequestId();
    HttpClientRequest? outgoing;
    var timedOut = false;
    try {
      final operation = () async {
        outgoing = await _httpClient.openUrl(request.method, uri);
        if (timedOut || cancellationToken?.isCanceled == true) {
          outgoing!.abort();
          throw const ApiFailure(ApiFailureKind.canceled);
        }
        outgoing!.followRedirects = false;
        outgoing!.headers.set(HttpHeaders.acceptHeader, 'application/json');
        outgoing!.headers.set('X-Request-ID', requestId);
        if (request.jsonBody != null) {
          outgoing!.headers.contentType = ContentType.json;
          outgoing!.write(jsonEncode(request.jsonBody));
        }
        final response = await outgoing!.close();
        final responseId =
            _safeIdentifier(response.headers.value('X-Request-ID')) ??
            requestId;
        final bytes = await _readLimited(response, cancellationToken);
        return _parseResponse(response.statusCode, bytes, responseId);
      }();

      final pending = cancellationToken == null
          ? operation
          : Future.any<ApiResponse>([
              operation,
              cancellationToken.whenCanceled.then((_) {
                outgoing?.abort();
                throw const ApiFailure(ApiFailureKind.canceled);
              }),
            ]);
      return await pending.timeout(
        _timeout,
        onTimeout: () {
          timedOut = true;
          outgoing?.abort();
          throw ApiFailure(ApiFailureKind.timeout, requestId: requestId);
        },
      );
    } on ApiFailure {
      rethrow;
    } on SocketException {
      throw ApiFailure(ApiFailureKind.network, requestId: requestId);
    } on HandshakeException {
      throw ApiFailure(ApiFailureKind.network, requestId: requestId);
    } on HttpException {
      throw ApiFailure(ApiFailureKind.network, requestId: requestId);
    } on FormatException {
      throw ApiFailure(ApiFailureKind.invalidResponse, requestId: requestId);
    } catch (_) {
      if (cancellationToken?.isCanceled == true) {
        throw ApiFailure(ApiFailureKind.canceled, requestId: requestId);
      }
      if (timedOut) {
        throw ApiFailure(ApiFailureKind.timeout, requestId: requestId);
      }
      throw ApiFailure(ApiFailureKind.unexpected, requestId: requestId);
    }
  }

  Uri _resolveUri(Uri baseUrl, ApiRequest request) {
    final path = Uri.tryParse(request.path);
    if (path == null ||
        request.path.isEmpty ||
        request.path.startsWith('/') ||
        path.hasScheme ||
        path.hasAuthority ||
        path.hasQuery ||
        path.hasFragment ||
        path.pathSegments.any((segment) => segment == '.' || segment == '..') ||
        !RegExp(r'^[A-Z]+$').hasMatch(request.method)) {
      throw const ApiFailure(ApiFailureKind.configuration);
    }
    final target = baseUrl.resolveUri(
      path.replace(queryParameters: request.query),
    );
    if (target.origin != baseUrl.origin ||
        !target.path.startsWith(baseUrl.path)) {
      throw const ApiFailure(ApiFailureKind.configuration);
    }
    return target;
  }

  Future<List<int>> _readLimited(
    HttpClientResponse response,
    ApiCancellationToken? cancellationToken,
  ) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (cancellationToken?.isCanceled == true) {
        throw const ApiFailure(ApiFailureKind.canceled);
      }
      bytes.add(chunk);
      if (bytes.length > _maxResponseBytes) {
        throw const ApiFailure(ApiFailureKind.invalidResponse);
      }
    }
    return bytes.takeBytes();
  }

  ApiResponse _parseResponse(int status, List<int> bytes, String requestId) {
    Map<String, dynamic> json = const {};
    if (bytes.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (decoded is! Map<String, dynamic>) {
        throw ApiFailure(
          ApiFailureKind.invalidResponse,
          statusCode: status,
          requestId: requestId,
        );
      }
      json = decoded;
    } else if (status >= 200 &&
        status < 300 &&
        status != HttpStatus.noContent) {
      throw ApiFailure(
        ApiFailureKind.invalidResponse,
        statusCode: status,
        requestId: requestId,
      );
    }

    if (status >= 200 && status < 300) {
      return ApiResponse(statusCode: status, json: json, requestId: requestId);
    }
    final error = json['error'];
    final rawCode = error is Map<String, dynamic> ? error['code'] : null;
    final code = rawCode is String ? _safeIdentifier(rawCode) : null;
    final kind = switch (status) {
      401 => ApiFailureKind.unauthenticated,
      403 => ApiFailureKind.forbidden,
      408 => ApiFailureKind.timeout,
      409 => ApiFailureKind.conflict,
      429 => ApiFailureKind.rateLimited,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.unexpected,
    };
    throw ApiFailure(
      kind,
      statusCode: status,
      code: code,
      requestId: requestId,
    );
  }

  String _newRequestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String? _safeIdentifier(String? value) {
    if (value == null || !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
      return null;
    }
    return value;
  }
}
