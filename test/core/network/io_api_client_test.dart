import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/network/io_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('لا يرسل طلباً دون عنوان API أو عند خروج المسار عن الأصل', () async {
    expect(
      () => IoApiClient(Uri.parse('http://api.example.com/v1/')),
      throwsArgumentError,
    );
    final noApi = IoApiClient(
      AppEnvironment.parse(stageName: 'development', apiBaseUrl: '').apiBaseUrl,
    );
    addTearDown(noApi.close);
    await expectLater(
      noApi.send(const ApiRequest(method: 'GET', path: 'catalog')),
      _hasKind(ApiFailureKind.configuration),
    );

    final client = IoApiClient(
      AppEnvironment.parse(
        stageName: 'development',
        apiBaseUrl: 'http://127.0.0.1:8080/api/v1/',
      ).apiBaseUrl,
      allowLocalHttp: true,
    );
    addTearDown(client.close);
    for (final path in ['../admin', '/outside', 'https://evil.example/']) {
      await expectLater(
        client.send(ApiRequest(method: 'GET', path: path)),
        _hasKind(ApiFailureKind.configuration),
      );
    }
  });

  test('يقرأ JSON محدوداً ويرسل معرّف طلب دون رؤوس حساسة', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? receivedRequestId;
    server.listen((request) async {
      receivedRequestId = request.headers.value('X-Request-ID');
      expect(request.uri.path, '/api/v1/catalog');
      expect(request.uri.queryParameters['page'], '1');
      expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
      request.response.headers.set('X-Request-ID', 'server-123');
      request.response.write(jsonEncode({'items': <Object>[]}));
      await request.response.close();
    });
    final client = _localClient(server.port);
    addTearDown(client.close);

    final response = await client.send(
      const ApiRequest(method: 'GET', path: 'catalog', query: {'page': '1'}),
    );
    expect(response.statusCode, 200);
    expect(response.json['items'], isEmpty);
    expect(response.requestId, 'server-123');
    expect(receivedRequestId, matches(RegExp(r'^[a-f0-9]{32}$')));
  });

  test('يصنف رفض الهوية والصلاحية والتعارض والمعدل والخادم', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final status = int.parse(request.uri.pathSegments.last);
      request.response.statusCode = status;
      request.response.write(
        jsonEncode({
          'error': {'code': 'TEST_ERROR', 'message': 'لا تعرض هذا النص'},
        }),
      );
      await request.response.close();
    });
    final client = _localClient(server.port);
    addTearDown(client.close);

    for (final entry in <int, ApiFailureKind>{
      401: ApiFailureKind.unauthenticated,
      403: ApiFailureKind.forbidden,
      409: ApiFailureKind.conflict,
      429: ApiFailureKind.rateLimited,
      503: ApiFailureKind.server,
    }.entries) {
      await expectLater(
        client.send(ApiRequest(method: 'GET', path: '${entry.key}')),
        throwsA(
          isA<ApiFailure>()
              .having((error) => error.kind, 'kind', entry.value)
              .having((error) => error.code, 'code', 'TEST_ERROR')
              .having((error) => error.statusCode, 'status', entry.key),
        ),
      );
    }
  });

  test('يرفض JSON غير صالح أو استجابة أكبر من الحد', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.write(
        request.uri.path.endsWith('/invalid')
            ? 'not-json'
            : jsonEncode({'value': 'x' * 200}),
      );
      await request.response.close();
    });
    final client = _localClient(server.port, maxResponseBytes: 64);
    addTearDown(client.close);
    for (final path in ['invalid', 'large']) {
      await expectLater(
        client.send(ApiRequest(method: 'GET', path: path)),
        _hasKind(ApiFailureKind.invalidResponse),
      );
    }
  });

  test('المهلة والإلغاء ينهيان الطلب المعلق', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = Completer<void>();
    server.listen((request) async {
      if (!received.isCompleted) received.complete();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      try {
        await request.response.close();
      } catch (_) {}
    });
    final timeoutClient = _localClient(
      server.port,
      timeout: const Duration(milliseconds: 40),
    );
    addTearDown(timeoutClient.close);
    await expectLater(
      timeoutClient.send(const ApiRequest(method: 'GET', path: 'slow')),
      _hasKind(ApiFailureKind.timeout),
    );

    final cancelClient = _localClient(server.port);
    addTearDown(cancelClient.close);
    final token = ApiCancellationToken();
    final pending = cancelClient.send(
      const ApiRequest(method: 'GET', path: 'slow'),
      cancellationToken: token,
    );
    await received.future;
    token.cancel();
    await expectLater(pending, _hasKind(ApiFailureKind.canceled));
  });
}

IoApiClient _localClient(
  int port, {
  Duration timeout = const Duration(seconds: 2),
  int maxResponseBytes = 1024 * 1024,
}) => IoApiClient(
  AppEnvironment.parse(
    stageName: 'development',
    apiBaseUrl: 'http://127.0.0.1:$port/api/v1/',
  ).apiBaseUrl,
  allowLocalHttp: true,
  timeout: timeout,
  maxResponseBytes: maxResponseBytes,
);

Matcher _hasKind(ApiFailureKind kind) =>
    throwsA(isA<ApiFailure>().having((error) => error.kind, 'kind', kind));
