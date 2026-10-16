import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'cache_database.g.dart';

class AccountPageIndices extends Table {
  TextColumn get accountId => text()();
  TextColumn get cacheKey => text()();
  TextColumn get itemIdsJson => text()();
  IntColumn get cachedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, cacheKey};
}

@DriftDatabase(tables: [AccountPageIndices])
class CacheDatabase extends _$CacheDatabase {
  CacheDatabase(super.executor);

  factory CacheDatabase.onDevice() => CacheDatabase(
    LazyDatabase(() => driftDatabase(name: 'hasobjy_metadata_cache_v1')),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    // No shipped older schema exists. Never silently drop account data.
    onUpgrade: (_, from, to) async =>
        throw StateError('Unsupported cache schema migration'),
  );
}
