import 'package:cit_zone/core/errors/result.dart';
import 'package:cit_zone/core/security/secure_session_secret_store.dart';
import 'package:cit_zone/core/storage/account_cache.dart';
import 'package:cit_zone/core/storage/account_local_data.dart';
import 'package:cit_zone/core/storage/account_scope.dart';
import 'package:cit_zone/core/storage/cache_database.dart';
import 'package:cit_zone/core/storage/drift_account_cache.dart';
import 'package:cit_zone/core/storage/storage_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_navigation_test.dart' as navigation;

T success<T>(Result<T, StorageFailure> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) =>
      throw StateError('Storage integration failed: $failure'),
);

void main() {
  navigation.main();

  testWidgets(
    'native secure storage and Drift persist and isolate account data',
    (tester) async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final a = AccountScope('storage_test_a_$suffix');
      final b = AccountScope('storage_test_b_$suffix');
      final secretA = SecureSessionSecretStore(account: a);
      final secretB = SecureSessionSecretStore(account: b);
      var database = CacheDatabase.onDevice();
      addTearDown(() async {
        await secretA.clear();
        await secretB.clear();
        await DriftAccountCache(database, a).clear();
        await DriftAccountCache(database, b).clear();
        await database.close();
      });
      success(await secretA.write('integration-only-a'));
      success(await secretB.write('integration-only-b'));
      final idsA = CachedPageIndex(
        itemIds: ['subject_reference'],
        cachedAt: DateTime.now().toUtc(),
      );
      final idsB = CachedPageIndex(
        itemIds: ['course_reference'],
        cachedAt: DateTime.now().toUtc(),
      );
      success(await DriftAccountCache(database, a).writePage('page', idsA));
      success(await DriftAccountCache(database, b).writePage('page', idsB));
      await database.close();
      database = CacheDatabase.onDevice();
      final cacheA = DriftAccountCache(database, a);
      final cacheB = DriftAccountCache(database, b);
      expect(success(await cacheA.readPage('page'))!.itemIds, [
        'subject_reference',
      ]);
      expect(success(await cacheB.readPage('page'))!.itemIds, [
        'course_reference',
      ]);
      final recreatedSecret = SecureSessionSecretStore(account: a);
      expect(success(await recreatedSecret.read()), 'integration-only-a');
      // Simulates a missing key. Real Keychain/Keystore reset is a separate gate.
      success(await secretA.clear());
      final localA = AccountLocalData(secrets: recreatedSecret, cache: cacheA);
      expect(success(await localA.readSecret()), isNull);
      expect(
        success(await DriftAccountCache(database, a).readPage('page')),
        isNull,
      );
      expect(success(await secretB.read()), 'integration-only-b');
      expect(success(await cacheB.readPage('page'))!.itemIds, [
        'course_reference',
      ]);
      success(await AccountLocalData(secrets: secretB, cache: cacheB).clear());
      expect(success(await secretB.read()), isNull);
      expect(
        success(await DriftAccountCache(database, b).readPage('page')),
        isNull,
      );
    },
  );
}
