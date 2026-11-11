import '../errors/either.dart';
import '../storage/storage_failure.dart';
import '../storage/account_scope.dart';

/// Stores an opaque server session secret. Does not issue or validate sessions.
/// DRM keys/licenses must remain in their platform/provider-owned store.
abstract interface class SessionSecretStore {
  AccountScope get account;
  Future<Either<StorageFailure, String?>> read();
  Future<Either<StorageFailure, void>> write(String secret);
  Future<Either<StorageFailure, void>> clear();
}
