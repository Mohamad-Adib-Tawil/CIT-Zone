import 'dart:async';
import 'dart:io';

import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/core/network/io_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _HttpClient extends Mock implements HttpClient {}

class _HttpRequest extends Mock implements HttpClientRequest {}

void main() {
  for (final cancel in [true, false]) {
    test(
      'late connection is aborted after ${cancel ? 'cancellation' : 'deadline'}',
      () async {
        final http = _HttpClient();
        final request = _HttpRequest();
        final opening = Completer<void>();
        final opened = Completer<HttpClientRequest>();
        final uri = Uri.parse('https://api.test/v1/items')
            .replace(queryParameters: {});
        when(() => http.openUrl('GET', uri)).thenAnswer((_) {
          opening.complete();
          return opened.future;
        });
        final client = IoApiClient(
          Uri.parse('https://api.test/v1/'),
          httpClient: http,
          timeout: cancel
              ? const Duration(seconds: 30)
              : const Duration(milliseconds: 20),
        );
        addTearDown(client.close);
        final token = ApiCancellationToken();
        final pending = client.send(
          const ApiRequest(method: 'GET', path: 'items'),
          cancellationToken: token,
        );
        final check = expectLater(
          pending,
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.kind,
              'kind',
              cancel ? ApiFailureKind.canceled : ApiFailureKind.timeout,
            ),
          ),
        );
        // Keep the connection pending until the public operation stops.
        await opening.future;
        if (cancel) token.cancel();
        await check;
        opened.complete(request);
        await Future<void>.delayed(Duration.zero);
        verify(() => request.abort()).called(1);
      },
    );
  }
}
