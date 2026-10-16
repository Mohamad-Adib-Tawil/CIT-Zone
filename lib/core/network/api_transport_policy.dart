import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'api_failure.dart';
import 'api_request.dart';

/// Shared wire contract; adapters own only I/O, cancellation and resource cleanup.
class ApiTransportPolicy {
  ApiTransportPolicy(
    Uri? baseUrl, {
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 1024 * 1024,
    bool allowLocalHttp = false,
  }) : baseUrl = _validateBaseUrl(baseUrl, allowLocalHttp) {
    if (timeout <= Duration.zero || maxResponseBytes < 1) {
      throw ArgumentError('A positive timeout and response limit are required');
    }
  }

  final Uri? baseUrl;
  final Duration timeout;
  final int maxResponseBytes;

  static Uri? _validateBaseUrl(Uri? baseUrl, bool allowLocalHttp) {
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
      throw ArgumentError('A valid HTTPS API base URL is required');
    }
    return baseUrl;
  }

  Uri resolve(ApiRequest request) {
    final base = baseUrl;
    if (base == null) throw const ApiFailure(ApiFailureKind.configuration);
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
    final target = base.resolveUri(
      path.replace(queryParameters: request.query),
    );
    if (target.origin != base.origin || !target.path.startsWith(base.path)) {
      throw const ApiFailure(ApiFailureKind.configuration);
    }
    return target;
  }

  ApiResponse decode(int status, List<int> bytes, String requestId) {
    Map<String, dynamic> json = const {};
    if (bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
        if (decoded is! Map<String, dynamic>) throw const FormatException();
        json = decoded;
      } on FormatException {
        throw ApiFailure(
          ApiFailureKind.invalidResponse,
          statusCode: status,
          requestId: requestId,
        );
      }
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
      code: rawCode is String ? safeIdentifier(rawCode) : null,
      requestId: requestId,
    );
  }

  static String newRequestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String? safeIdentifier(String? value) =>
      value != null && RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)
      ? value
      : null;
}
