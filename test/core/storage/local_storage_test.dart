import 'dart:io';

import 'package:cit_zone/core/errors/result.dart';
import 'package:cit_zone/core/security/session_secret_store.dart';
import 'package:cit_zone/core/storage/account_cache.dart';
import 'package:cit_zone/core/storage/account_local_data.dart';
import 'package:cit_zone/core/storage/account_scope.dart';
import 'package:cit_zone/core/storage/cache_database.dart';
import 'package:cit_zone/core/storage/drift_account_cache.dart';
import 'package:cit_zone/core/storage/storage_failure.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

T value<T>(Result<T, StorageFailure> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw StateError('$failure'),
);
CachedPageIndex page(List<String> ids) =>
    CachedPageIndex(itemIds: ids, cachedAt: DateTime.utc(2026, 10, 16));

void main() {
  test(
    'database opens lazily and unopened close does not activate SQLite',
    () async {
      var opens = 0;
      CacheDatabase create() => CacheDatabase(
        LazyDatabase(() {
          opens++;
          return NativeDatabase.memory();
        }),
      );
      final unused = create();
      await unused.close();
      expect(opens, 0);
      final used = create();
      expect(opens, 0);
      final cache = DriftAccountCache(used, AccountScope('backend_a'));
      value(await cache.writePage('catalog/page1', page(['subject_id'])));
      expect(opens, 1);
      await used.close();
    },
  );

  test(
    'account switching isolates identical cache keys; clear only erases owner',
    () async {
      final database = CacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final a = DriftAccountCache(database, AccountScope('backend_a'));
      final b = DriftAccountCache(database, AccountScope('backend_b'));
      expect(value(await a.readPage('page')), isNull);
      value(await a.writePage('page', page(['academic_subject_id'])));
      value(await b.writePage('page', page(['independent_course_id'])));
      expect(value(await a.readPage('page'))!.itemIds, ['academic_subject_id']);
      expect(value(await b.readPage('page'))!.itemIds, [
        'independent_course_id',
      ]);
      value(await a.writePage('page', page(['updated_id'])));
      expect(value(await a.readPage('page'))!.itemIds, ['updated_id']);
      value(await a.clear());
      expect(value(await a.readPage('page')), isNull);
      expect(value(await b.readPage('page'))!.itemIds, [
        'independent_course_id',
      ]);
    },
  );

  test('logout retires old handles and prevents late writes from repopulating cache', () async {
    final database = CacheDatabase(
      LazyDatabase(() async {
        await Future<void>.delayed(Duration.zero);
        return NativeDatabase.memory();
      }),
    );
    addTearDown(database.close);
    final account = AccountScope('backend_a');
    final old = DriftAccountCache(database, account);
    final pendingWrite = old.writePage('page', page(['stale']));
    final cleanup = old.clear();
    await pendingWrite;
    value(await cleanup);
    expect(
      await old.writePage('page', page(['late'])),
      isA<Failure<void, StorageFailure>>(),
    );
    final fresh = DriftAccountCache(database, account);
    expect(value(await fresh.readPage('page')), isNull);
    value(await fresh.writePage('page', page(['new-session'])));
    expect(value(await old.readPage('page')), isNull);
    expect(value(await fresh.readPage('page'))!.itemIds, ['new-session']);
  });

  test('schema creation/reopen preserves cache and future schema is not erased', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hasobjy_cache_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/cache.sqlite');
    final account = AccountScope('backend_a');
    final first = CacheDatabase(NativeDatabase(file));
    value(
      await DriftAccountCache(
        first,
        account,
      ).writePage('page', page(['stable_id'])),
    );
    await first.close();
    final reopened = CacheDatabase(NativeDatabase(file));
    expect(
      value(await DriftAccountCache(reopened, account).readPage('page'))!
          .itemIds,
      ['stable_id'],
    );
    await reopened.customStatement('PRAGMA user_version = 2');
    await reopened.close();
    final unsupported = CacheDatabase(NativeDatabase(file));
    expect(
      await DriftAccountCache(unsupported, account).readPage('page'),
      isA<Failure<CachedPageIndex?, StorageFailure>>(),
    );
    await unsupported.close();
    // Simulate reopening with the newer owner, proving no destructive fallback.
    final newer = _FutureSchemaDatabase(NativeDatabase(file));
    expect(
      value(await DriftAccountCache(newer, account).readPage('page'))!.itemIds,
      ['stable_id'],
    );
    await newer.close();
  });

  test(
    'malformed cached metadata is failure, never trusted content or a session',
    () async {
      final database = CacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cache = DriftAccountCache(database, AccountScope('backend_a'));
      value(await cache.writePage('page', page([])));
      expect(value(await cache.readPage('page'))!.itemIds, isEmpty);
      await database.customStatement(
        'UPDATE account_page_indices SET item_ids_json = ?',
        ['{"invalid":"shape"}'],
      );
      expect(
        (await cache.readPage('page'))
            .fold(onSuccess: (_) => null, onFailure: (failure) => failure),
        StorageFailure.corrupt,
      );
      expect(
        await cache.writePage('', page([])),
        isA<Failure<void, StorageFailure>>(),
      );
      final ids = ['id'];
      final immutable = page(ids);
      ids.add('later');
      expect(immutable.itemIds, ['id']);
      expect(() => immutable.itemIds.add('change'), throwsUnsupportedError);
    },
  );

  for (final readFailure in [false, true]) {
    test(
      'missing/lost key (error=$readFailure) purges only that account cache',
      () async {
        final database = CacheDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final account = AccountScope('backend_a');
        final a = DriftAccountCache(database, account);
        final b = DriftAccountCache(database, AccountScope('backend_b'));
        value(await a.writePage('page', page(['a'])));
        value(await b.writePage('page', page(['b'])));
        final local = AccountLocalData(
          cache: a,
          secrets: _SecretStore(account, readFailure: readFailure),
        );
        final result = await local.readSecret();
        if (readFailure) {
          expect(result, isA<Failure<String?, StorageFailure>>());
        } else {
          expect(value(result), isNull);
        }
        expect(value(await a.readPage('page')), isNull);
        expect(value(await b.readPage('page'))!.itemIds, ['b']);
      },
    );
  }

  test('failed secret deletion still clears cache and does not claim logout success', () async {
    final database = CacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final account = AccountScope('backend_a');
    final cache = DriftAccountCache(database, account);
    value(await cache.writePage('page', page(['a'])));
    final local = AccountLocalData(
      cache: cache,
      secrets: _SecretStore(account, clearFailure: true),
    );
    expect(await local.clear(), isA<Failure<void, StorageFailure>>());
    expect(value(await cache.readPage('page')), isNull);
    expect(
      () => AccountLocalData(
        cache: cache,
        secrets: _SecretStore(AccountScope('backend_b')),
      ),
      throwsArgumentError,
    );
  });
}

class _FutureSchemaDatabase extends CacheDatabase {
  _FutureSchemaDatabase(super.executor);
  @override
  int get schemaVersion => 2;
}

class _SecretStore implements SessionSecretStore {
  _SecretStore(
    this.account, {
    this.readFailure = false,
    this.clearFailure = false,
  });
  @override
  final AccountScope account;
  final bool readFailure;
  final bool clearFailure;
  @override
  Future<Result<String?, StorageFailure>> read() async => readFailure
      ? const Failure(StorageFailure.unavailable)
      : const Success(null);
  @override
  Future<Result<void, StorageFailure>> write(String secret) async =>
      const Success(null);
  @override
  Future<Result<void, StorageFailure>> clear() async => clearFailure
      ? const Failure(StorageFailure.unavailable)
      : const Success(null);
}
