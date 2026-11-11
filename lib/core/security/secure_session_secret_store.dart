import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/either.dart';
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
  Future<Either<StorageFailure, String?>> read() => _capture(() async {
    final value = await _storage.read(key: _key);
    if (value != null && (value.isEmpty || value.length > 16384)) {
      return const Left(StorageFailure.corrupt);
    }
    return Right(value);
  });

  @override
  Future<Either<StorageFailure, void>> write(String secret) =>
      _capture(() async {
        if (secret.isEmpty || secret.length > 16384) {
          return const Left(StorageFailure.corrupt);
        }
        await _storage.write(key: _key, value: secret);
        return const Right(null);
      });

  @override
  Future<Either<StorageFailure, void>> clear() => _capture(() async {
    await _storage.delete(key: _key);
    return const Right(null);
  });

  Future<Either<StorageFailure, T>> _capture<T>(
    Future<Either<StorageFailure, T>> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (_) {
      return const Left(StorageFailure.unavailable);
    }
  }
}
