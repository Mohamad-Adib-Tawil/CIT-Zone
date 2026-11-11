import '../errors/either.dart';
import 'storage_failure.dart';
import 'account_scope.dart';

/// Only page membership metadata; never credentials, licenses or protected data.
final class CachedPageIndex {
  CachedPageIndex({required List<String> itemIds, required this.cachedAt})
    : itemIds = List.unmodifiable(itemIds) {
    if (itemIds.length > 1000 ||
        itemIds.any((id) => id.isEmpty || id.length > 256)) {
      throw ArgumentError('Cache page IDs must be non-empty and bounded');
    }
  }
  final List<String> itemIds;
  final DateTime cachedAt;
}

abstract interface class AccountCache {
  AccountScope get account;
  Future<Either<StorageFailure, CachedPageIndex?>> readPage(String key);
  Future<Either<StorageFailure, void>> writePage(
    String key,
    CachedPageIndex page,
  );

  /// Purges this account and retires the handle. A later session gets a new one.
  Future<Either<StorageFailure, void>> clear();
}
