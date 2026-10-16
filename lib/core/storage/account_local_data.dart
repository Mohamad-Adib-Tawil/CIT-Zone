import '../errors/result.dart';
import '../security/session_secret_store.dart';
import 'account_cache.dart';
import 'storage_failure.dart';

/// Local cleanup only: does not revoke a backend session or unbind a device.
final class AccountLocalData {
  AccountLocalData({required this.secrets, required this.cache}) {
    if (secrets.account.id != cache.account.id) {
      throw ArgumentError('Local stores must belong to the same account');
    }
  }

  final SessionSecretStore secrets;
  final AccountCache cache;

  Future<Result<String?, StorageFailure>> readSecret() async {
    final result = await secrets.read();
    if (result case Success(value: final secret?)) return Success(secret);
    final cleanup = await cache.clear();
    if (result case Failure(:final failure)) return Failure(failure);
    if (cleanup case Failure(:final failure)) return Failure(failure);
    return const Success(null);
  }

  /// Both stores are attempted; a failure is never reported as successful logout.
  Future<Result<void, StorageFailure>> clear() async {
    final secretResult = await secrets.clear();
    final cacheResult = await cache.clear();
    if (secretResult case Failure(:final failure)) return Failure(failure);
    return cacheResult;
  }
}
