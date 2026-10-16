import 'package:cit_zone/core/errors/result.dart';
import 'package:cit_zone/core/security/secure_session_secret_store.dart';
import 'package:cit_zone/core/storage/account_scope.dart';
import 'package:cit_zone/core/storage/storage_failure.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

void main() {
  test('secure adapter isolates accounts and removes only one key', () async {
    final platform = _Storage();
    final values = <String, String>{};
    when(
      () => platform.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      values[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String;
    });
    when(() => platform.read(key: any(named: 'key')))
        .thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(() => platform.delete(key: any(named: 'key')))
        .thenAnswer((call) async {
          values.remove(call.namedArguments[#key]);
        });
    final a = SecureSessionSecretStore(
      account: AccountScope('a'),
      storage: platform,
    );
    final b = SecureSessionSecretStore(
      account: AccountScope('b'),
      storage: platform,
    );
    expect(values, isEmpty);
    await a.write('test-only-secret-a');
    await b.write('test-only-secret-b');
    expect(
      (await a.read()).fold(
        onSuccess: (value) => value,
        onFailure: (_) => null,
      ),
      'test-only-secret-a',
    );
    await a.clear();
    expect(
      (await a.read()).fold(
        onSuccess: (value) => value,
        onFailure: (_) => 'unexpected',
      ),
      isNull,
    );
    expect(
      (await b.read()).fold(
        onSuccess: (value) => value,
        onFailure: (_) => null,
      ),
      'test-only-secret-b',
    );
    expect(await a.write(''), isA<Failure<void, StorageFailure>>());
  });

  test(
    'platform key loss is a typed failure; never a memory fallback',
    () async {
      final platform = _Storage();
      when(() => platform.read(key: any(named: 'key')))
          .thenThrow(StateError('key-invalid secret-value'));
      when(
        () => platform.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('private'));
      when(() => platform.delete(key: any(named: 'key')))
          .thenThrow(StateError('private'));
      final store = SecureSessionSecretStore(
        account: AccountScope('a'),
        storage: platform,
      );
      for (final result in [
        await store.read(),
        await store.write('test-only'),
        await store.clear(),
      ]) {
        expect(
          result.fold(onSuccess: (_) => null, onFailure: (failure) => failure),
          StorageFailure.unavailable,
        );
      }
    },
  );

  test(
    'platform options keep no biometric requirement, no sync, no auto reset',
    () {
      final storage = SecureSessionSecretStore.platformStorage;
      final android = storage.aOptions.toMap();
      final ios = storage.iOptions.toMap();
      expect(android['resetOnError'], 'false');
      expect(android['enforceBiometrics'], 'false');
      expect(ios['synchronizable'], 'false');
      expect(ios['accessibility'], 'unlocked_this_device');
    },
  );
}
