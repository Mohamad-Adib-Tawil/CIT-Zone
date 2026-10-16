import 'dart:convert';

import 'package:drift/drift.dart';

import '../errors/result.dart';
import 'account_cache.dart';
import 'account_scope.dart';
import 'cache_database.dart';
import 'storage_failure.dart';

final class DriftAccountCache implements AccountCache {
  DriftAccountCache(this._database, this._account);

  final CacheDatabase _database;
  final AccountScope _account;
  bool _retired = false;
  @override
  AccountScope get account => _account;

  bool _validKey(String key) => key.isNotEmpty && key.length <= 256;

  @override
  Future<Result<CachedPageIndex?, StorageFailure>> readPage(String key) async {
    if (_retired) return const Success(null);
    if (!_validKey(key)) return const Failure(StorageFailure.corrupt);
    try {
      final table = _database.accountPageIndices;
      final row =
          await (_database.select(table)..where(
                (row) =>
                    row.accountId.equals(_account.id) &
                    row.cacheKey.equals(key),
              ))
              .getSingleOrNull();
      if (_retired || row == null) return const Success(null);
      try {
        final ids = jsonDecode(row.itemIdsJson);
        if (ids is! List || ids.any((id) => id is! String)) {
          return const Failure(StorageFailure.corrupt);
        }
        return Success(
          CachedPageIndex(
            itemIds: ids.cast<String>(),
            cachedAt: DateTime.fromMillisecondsSinceEpoch(
              row.cachedAtMs,
              isUtc: true,
            ),
          ),
        );
      } catch (_) {
        return const Failure(StorageFailure.corrupt);
      }
    } catch (_) {
      return const Failure(StorageFailure.unavailable);
    }
  }

  @override
  Future<Result<void, StorageFailure>> writePage(
    String key,
    CachedPageIndex page,
  ) async {
    if (_retired) return const Failure(StorageFailure.unavailable);
    if (!_validKey(key)) return const Failure(StorageFailure.corrupt);
    try {
      return await _database.transaction(() async {
        if (_retired) {
          return const Failure<void, StorageFailure>(
            StorageFailure.unavailable,
          );
        }
        await _database
            .into(_database.accountPageIndices)
            .insertOnConflictUpdate(
              AccountPageIndicesCompanion.insert(
                accountId: _account.id,
                cacheKey: key,
                itemIdsJson: jsonEncode(page.itemIds),
                cachedAtMs: page.cachedAt.toUtc().millisecondsSinceEpoch,
              ),
            );
        return _retired
            ? const Failure<void, StorageFailure>(StorageFailure.unavailable)
            : const Success<void, StorageFailure>(null);
      });
    } catch (_) {
      return const Failure(StorageFailure.unavailable);
    }
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _retired = true;
    try {
      await (_database.delete(
        _database.accountPageIndices,
      )..where((row) => row.accountId.equals(_account.id))).go();
      return const Success(null);
    } catch (_) {
      return const Failure(StorageFailure.unavailable);
    }
  }
}
