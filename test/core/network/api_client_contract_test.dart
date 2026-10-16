import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/network/dio_api_client.dart';
import 'package:cit_zone/core/network/io_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

typedef ClientFactory = ApiClient Function(Uri?, Duration, int, bool);

void main() {
  final factories = <String, ClientFactory>{
    'Io': (uri, timeout, limit, local) => IoApiClient(
      uri,
      timeout: timeout,
      maxResponseBytes: limit,
      allowLocalHttp: local,
    ),
    'Dio': (uri, timeout, limit, local) => DioApiClient(
      uri,
      timeout: timeout,
      maxResponseBytes: limit,
      allowLocalHttp: local,
    ),
  };
  for (final entry in factories.entries) {
    group(entry.key, () => contract(entry.value));
  }

  test('cancellation listeners detach and late listeners fire once', () {
    final token = ApiCancellationToken();
    var calls = 0;
    final remove = token.addListener(() => calls++);
    remove();
    token.addListener(() => calls++);
    token.cancel();
    token.cancel();
    expect(calls, 1);
    token.addListener(() => calls++);
    expect(calls, 2);
  });
}

void contract(ClientFactory factory) {
  ApiClient client(
    int? port, {
    Duration timeout = const Duration(seconds: 2),
    int limit = 1024,
  }) {
    final result = factory(
      port == null ? null : Uri.parse('http://127.0.0.1:$port/api/v1/'),
      timeout,
      limit,
      true,
    );
    addTearDown(result.close);
    return result;
  }

  Future<HttpServer> server(void Function(HttpRequest) handler) async {
    final result = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => result.close(force: true));
    result.listen(handler);
    return result;
  }

  test(
    'validates configuration and confines URL before any connection',
    () async {
      for (final uri in [
        'http://example.com/v1/',
        'https://user:secret@example.com/v1/',
        'https://example.com/v1',
        'https://example.com/v1/?secret=1',
      ]) {
        expect(
          () =>
              factory(Uri.parse(uri), const Duration(seconds: 1), 1024, false),
          throwsArgumentError,
        );
      }
      expect(
        () => factory(null, Duration.zero, 1024, false),
        throwsArgumentError,
      );
      expect(
        () => factory(null, const Duration(seconds: 1), 0, false),
        throwsArgumentError,
      );
      await expectLater(
        client(null).send(const ApiRequest(method: 'GET', path: 'items')),
        fails(ApiFailureKind.configuration),
      );
      final transport = client(1);
      for (final path in [
        '',
        '../admin',
        '/outside',
        '//evil.test/x',
        'https://evil.test/',
        '%2e%2e/admin',
        'items?token=x',
        'items#x',
      ]) {
        await expectLater(
          transport.send(ApiRequest(method: 'GET', path: path)),
          fails(ApiFailureKind.configuration),
        );
      }
      await expectLater(
        transport.send(const ApiRequest(method: 'get', path: 'items')),
        fails(ApiFailureKind.configuration),
      );
    },
  );

  test(
    'preserves JSON encoding, query, request ID and excludes credentials',
    () async {
      final received = Completer<HttpRequest>();
      final body = Completer<String>();
      final host = await server((request) async {
        received.complete(request);
        body.complete(await utf8.decoder.bind(request).join());
        request.response.headers.set('X-Request-ID', 'server-123');
        request.response.write('{"ok":true}');
        await request.response.close();
      });
      final response = await client(host.port).send(
        const ApiRequest(
          method: 'POST',
          path: 'items',
          query: {'search': 'عربي + &'},
          jsonBody: 'JSON string',
        ),
      );
      final request = await received.future;
      expect(request.uri.path, '/api/v1/items');
      expect(request.uri.queryParameters['search'], 'عربي + &');
      expect(await body.future, jsonEncode('JSON string'));
      expect(request.headers.contentType?.mimeType, 'application/json');
      expect(
        request.headers.value('X-Request-ID'),
        matches(RegExp(r'^[a-f0-9]{32}$')),
      );
      expect(request.headers.value('Authorization'), isNull);
      expect(request.headers.value('Cookie'), isNull);
      expect(response.requestId, 'server-123');
      expect(response.json, {'ok': true});
    },
  );

  test('maps all status classes and never returns unsafe remote metadata', () async {
    final host = await server((request) async {
      request.response.statusCode = int.parse(request.uri.pathSegments.last);
      request.response.headers.set('X-Request-ID', 'unsafe private details');
      request.response.write(
        '{"error":{"code":"unsafe private details","message":"secret-token"}}',
      );
      await request.response.close();
    });
    final transport = client(host.port);
    for (final item in {
      401: ApiFailureKind.unauthenticated,
      403: ApiFailureKind.forbidden,
      408: ApiFailureKind.timeout,
      409: ApiFailureKind.conflict,
      429: ApiFailureKind.rateLimited,
      503: ApiFailureKind.server,
      400: ApiFailureKind.unexpected,
    }.entries) {
      await expectLater(
        transport.send(ApiRequest(method: 'GET', path: '${item.key}')),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.kind, 'kind', item.value)
              .having((e) => e.statusCode, 'status', item.key)
              .having((e) => e.code, 'safe code', isNull)
              .having(
                (e) => e.requestId,
                'safe id',
                matches(RegExp(r'^[a-f0-9]{32}$')),
              ),
        ),
      );
    }
  });

  test(
    'strict UTF8, object JSON, empty success and exact byte limit',
    () async {
      final host = await server((request) async {
        switch (request.uri.pathSegments.last) {
          case 'invalid':
            request.response.write('not-json');
          case 'array':
            request.response.write('[]');
          case 'utf8':
            request.response.add([255]);
          case 'empty':
            break;
          case 'none':
            request.response.statusCode = 204;
          default:
            request.response.write('{"a":1}');
        }
        await request.response.close();
      });
      final transport = client(host.port, limit: 7);
      for (final path in ['invalid', 'array', 'utf8', 'empty']) {
        await expectLater(
          transport.send(ApiRequest(method: 'GET', path: path)),
          fails(ApiFailureKind.invalidResponse),
        );
      }
      expect(
        (await transport.send(const ApiRequest(method: 'GET', path: 'none')))
            .json,
        isEmpty,
      );
      expect(
        (await transport.send(const ApiRequest(method: 'GET', path: 'exact')))
            .json,
        {'a': 1},
      );
      await expectLater(
        client(
          host.port,
          limit: 6,
        ).send(const ApiRequest(method: 'GET', path: 'exact')),
        fails(ApiFailureKind.invalidResponse),
      );
    },
  );

  test(
    'bounds decoded gzip bytes rather than compressed content length',
    () async {
      final compressed = gzip.encode(
        utf8.encode(jsonEncode({'value': 'x' * 4096})),
      );
      final host = await server((request) async {
        request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        request.response.contentLength = compressed.length;
        request.response.add(compressed);
        await request.response.close();
      });
      expect(compressed.length, lessThan(256));
      await expectLater(
        client(
          host.port,
          limit: 256,
        ).send(const ApiRequest(method: 'GET', path: 'gzip')),
        fails(ApiFailureKind.invalidResponse),
      );
    },
  );

  test('does not follow redirects or retry sensitive POST failures', () async {
    var requests = 0;
    final host = await server((request) async {
      requests++;
      request.response.statusCode = request.uri.path.endsWith('redirect')
          ? 302
          : 503;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        '/api/v1/destination',
      );
      request.response.write('{}');
      await request.response.close();
    });
    final transport = client(host.port);
    await expectLater(
      transport.send(
        const ApiRequest(
          method: 'POST',
          path: 'redirect',
          jsonBody: {'write': true},
        ),
      ),
      fails(ApiFailureKind.unexpected),
    );
    expect(requests, 1);
    await expectLater(
      transport.send(
        const ApiRequest(
          method: 'POST',
          path: 'write',
          jsonBody: {'write': true},
        ),
      ),
      fails(ApiFailureKind.server),
    );
    expect(requests, 2);
  });

  test(
    'pre-cancel never sends, one canceled request does not poison others',
    () async {
      var requests = 0;
      final host = await server((request) async {
        requests++;
        request.response.write('{}');
        await request.response.close();
      });
      final transport = client(host.port);
      final canceled = ApiCancellationToken()..cancel();
      await expectLater(
        transport.send(
          const ApiRequest(method: 'GET', path: 'items'),
          cancellationToken: canceled,
        ),
        fails(ApiFailureKind.canceled),
      );
      expect(requests, 0);
      await transport.send(const ApiRequest(method: 'GET', path: 'items'));
      expect(requests, 1);
    },
  );

  for (final closeClient in [false, true]) {
    test(
      '${closeClient ? 'close' : 'cancel'} aborts a response stalled after headers',
      () async {
        final headersSent = Completer<void>();
        final release = Completer<void>();
        addTearDown(() {
          if (!release.isCompleted) release.complete();
        });
        final host = await server((request) async {
          try {
            request.response.write('{"a":');
            await request.response.flush();
            if (!headersSent.isCompleted) headersSent.complete();
            await release.future;
            request.response.write('1}');
            await request.response.close();
          } on IOException {
            /* The client intentionally aborts this stream. */
          }
        });
        final transport = client(host.port);
        final token = ApiCancellationToken();
        final pending = transport.send(
          const ApiRequest(method: 'GET', path: 'stalled'),
          cancellationToken: token,
        );
        final check = expectLater(
          pending.timeout(const Duration(seconds: 1)),
          fails(ApiFailureKind.canceled),
        );
        await headersSent.future;
        if (closeClient) {
          transport.close();
        } else {
          token.cancel();
        }
        await check;
        release.complete();
        if (closeClient) {
          transport.close();
          await expectLater(
            transport.send(const ApiRequest(method: 'GET', path: 'items')),
            fails(ApiFailureKind.configuration),
          );
        } else {
          expect(
            (await transport.send(
              const ApiRequest(method: 'GET', path: 'after'),
            )).json,
            {'a': 1},
          );
        }
      },
    );
  }

  test('total deadline also expires a continuously arriving body', () async {
    final host = await server((request) async {
      try {
        request.response.write('{"value":"');
        for (var i = 0; i < 30; i++) {
          request.response.write('x');
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        request.response.write('"}');
        await request.response.close();
      } on IOException {
        /* Deadline closes the socket before the body ends. */
      }
    });
    await expectLater(
      client(
        host.port,
        timeout: const Duration(milliseconds: 100),
      ).send(const ApiRequest(method: 'GET', path: 'drip')),
      fails(ApiFailureKind.timeout),
    );
  });

  test('connection refusal maps to network without raw exception', () async {
    final unused = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = unused.port;
    await unused.close(force: true);
    await expectLater(
      client(port).send(const ApiRequest(method: 'GET', path: 'items')),
      fails(ApiFailureKind.network),
    );
  });
}

Matcher fails(ApiFailureKind kind) =>
    throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', kind));
