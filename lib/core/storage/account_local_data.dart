import '../errors/either.dart';
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

  Future<Either<StorageFailure, String?>> readSecret() async {
    final result = await secrets.read();
    if (result case Right(value: final secret?)) return Right(secret);
    final cleanup = await cache.clear();
    if (result case Left(value: final failure)) return Left(failure);
    if (cleanup case Left(value: final failure)) return Left(failure);
    return const Right(null);
  }

  /// Both stores are attempted; a failure is never reported as successful logout.
  Future<Either<StorageFailure, void>> clear() async {
    final secretResult = await secrets.clear();
    final cacheResult = await cache.clear();
    if (secretResult case Left(value: final failure)) return Left(failure);
    return cacheResult;
  }
}
