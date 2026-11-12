import 'package:cit_zone/core/network/api_cancellation_token.dart';
import 'package:cit_zone/core/network/api_client.dart';
import 'package:cit_zone/core/network/api_failure.dart';
import 'package:cit_zone/core/network/api_request.dart';
import 'package:cit_zone/features/auth/data/firebase_identity_proof.dart';
import 'package:cit_zone/features/auth/data/student_session_gateway.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _identity = GoogleIdentity(
  idGoogle: 'google-test',
  firebaseUid: 'firebase-test',
  emailVerified: true,
  displayName: null,
  email: 'student@example.test',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  StudentSessionGateway gateway(_Api api) => StudentSessionGateway(
    api: api,
    proofSource: _Proof(),
    environment: Uri.parse('https://api.example.test/api/v1/'),
    platform: 'android',
    storage: const FlutterSecureStorage(),
  );

  test('exchanges, rotates on restart, and revokes the latest token', () async {
    final api = _Api();
    expect(await gateway(api).restore(_identity), isFalse);
    await gateway(api).start(_identity);
    expect(await gateway(api).restore(_identity), isTrue);
    await gateway(api).end(_identity);
    expect(await gateway(api).restore(_identity), isFalse);

    expect(api.requests.map((r) => r.path), [
      'auth/google',
      'me/session-state',
      'auth/refresh',
      'me/session-state',
      'auth/logout',
    ]);
    expect(api.requests.first.jsonBody, {
      'idToken': 'firebase-test-proof',
      'device': {'id': isA<String>(), 'platform': 'android'},
    });
    expect(api.requests[1].headers['Authorization'], 'Bearer access-1');
    expect(api.requests[2].jsonBody, {'refreshToken': _refresh(1)});
    expect(api.requests[3].headers['Authorization'], 'Bearer access-2');
    expect(api.requests[4].jsonBody, {'refreshToken': _refresh(2)});
    final device = (api.requests.first.jsonBody as Map)['device'];
    await gateway(api).start(_identity);
    expect((api.requests[5].jsonBody as Map)['device'], device);
  });

  test('clears a rejected refresh without retrying the write', () async {
    final api = _Api();
    await gateway(api).start(_identity);
    api.rejectRefresh = true;
    expect(await gateway(api).restore(_identity), isFalse);
    expect(await gateway(api).restore(_identity), isFalse);
    expect(
      api.requests.where((request) => request.path == 'auth/refresh'),
      hasLength(1),
    );
  });
}

String _refresh(int index) => 'test-only-refresh-token-$index';

final class _Proof implements FirebaseIdentityProofSource {
  @override
  Future<FirebaseIdentityProof> prepareForBackend({
    required String expectedFirebaseUid,
  }) async {
    expect(expectedFirebaseUid, _identity.firebaseUid);
    return const FirebaseIdentityProof(
      'firebase-test-proof',
      identity: _identity,
    );
  }
}

final class _Api implements ApiClient {
  final requests = <ApiRequest>[];
  bool rejectRefresh = false;
  int exchanges = 0;

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    ApiCancellationToken? cancellationToken,
  }) async {
    requests.add(request);
    switch (request.path) {
      case 'auth/google':
      case 'auth/refresh':
        if (request.path == 'auth/refresh' && rejectRefresh) {
          throw const ApiFailure(
            ApiFailureKind.unauthenticated,
            code: 'INVALID_REFRESH_TOKEN',
          );
        }
        exchanges++;
        return ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {
              'accessToken': 'access-$exchanges',
              'refreshToken': _refresh(exchanges),
            },
          },
        );
      case 'me/session-state':
        return const ApiResponse(
          statusCode: 200,
          requestId: 'test',
          json: {
            'data': {'next': 'choose_usage_type'},
          },
        );
      case 'auth/logout':
        return const ApiResponse(statusCode: 204, requestId: 'test', json: {});
      default:
        throw StateError('Unexpected path');
    }
  }

  @override
  void close() {}
}
