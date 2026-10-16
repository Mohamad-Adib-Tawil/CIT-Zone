import '../errors/result.dart';
import '../storage/storage_failure.dart';
import '../storage/account_scope.dart';

/// Stores an opaque server session secret. Does not issue or validate sessions.
/// DRM keys/licenses must remain in their platform/provider-owned store.
abstract interface class SessionSecretStore {
  AccountScope get account;
  Future<Result<String?, StorageFailure>> read();
  Future<Result<void, StorageFailure>> write(String secret);
  Future<Result<void, StorageFailure>> clear();
}
