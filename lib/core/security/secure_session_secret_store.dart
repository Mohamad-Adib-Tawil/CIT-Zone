import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/result.dart';
import '../storage/account_scope.dart';
import '../storage/storage_failure.dart';
import 'session_secret_store.dart';

/// Dormant until a server session repository explicitly uses this adapter.
final class SecureSessionSecretStore implements SessionSecretStore {
  SecureSessionSecretStore({
    required this.account,
    FlutterSecureStorage? storage,
  }) : _key = 'hasobjy_session_v1_${account.storageKey}',
       _storage = storage ?? platformStorage;

  static const platformStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'hasobjy_sessions_v1',
      resetOnError: false,
      enforceBiometrics: false,
    ),
    iOptions: IOSOptions(
      accountName: 'hasobjy_sessions_v1',
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );

  final String _key;
  @override
  final AccountScope account;
  final FlutterSecureStorage _storage;

  @override
  Future<Result<String?, StorageFailure>> read() => _capture(() async {
    final value = await _storage.read(key: _key);
    if (value != null && (value.isEmpty || value.length > 16384)) {
      return const Failure(StorageFailure.corrupt);
    }
    return Success(value);
  });

  @override
  Future<Result<void, StorageFailure>> write(String secret) =>
      _capture(() async {
        if (secret.isEmpty || secret.length > 16384) {
          return const Failure(StorageFailure.corrupt);
        }
        await _storage.write(key: _key, value: secret);
        return const Success(null);
      });

  @override
  Future<Result<void, StorageFailure>> clear() => _capture(() async {
    await _storage.delete(key: _key);
    return const Success(null);
  });

  Future<Result<T, StorageFailure>> _capture<T>(
    Future<Result<T, StorageFailure>> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (_) {
      return const Failure(StorageFailure.unavailable);
    }
  }
}
