// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_database.dart';

// ignore_for_file: type=lint
class $AccountPageIndicesTable extends AccountPageIndices
    with TableInfo<$AccountPageIndicesTable, AccountPageIndice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountPageIndicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdsJsonMeta = const VerificationMeta(
    'itemIdsJson',
  );
  @override
  late final GeneratedColumn<String> itemIdsJson = GeneratedColumn<String>(
    'item_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMsMeta = const VerificationMeta(
    'cachedAtMs',
  );
  @override
  late final GeneratedColumn<int> cachedAtMs = GeneratedColumn<int>(
    'cached_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    cacheKey,
    itemIdsJson,
    cachedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_page_indices';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountPageIndice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('item_ids_json')) {
      context.handle(
        _itemIdsJsonMeta,
        itemIdsJson.isAcceptableOrUnknown(
          data['item_ids_json']!,
          _itemIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemIdsJsonMeta);
    }
    if (data.containsKey('cached_at_ms')) {
      context.handle(
        _cachedAtMsMeta,
        cachedAtMs.isAcceptableOrUnknown(
          data['cached_at_ms']!,
          _cachedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, cacheKey};
  @override
  AccountPageIndice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountPageIndice(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      itemIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_ids_json'],
      )!,
      cachedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at_ms'],
      )!,
    );
  }

  @override
  $AccountPageIndicesTable createAlias(String alias) {
    return $AccountPageIndicesTable(attachedDatabase, alias);
  }
}

class AccountPageIndice extends DataClass
    implements Insertable<AccountPageIndice> {
  final String accountId;
  final String cacheKey;
  final String itemIdsJson;
  final int cachedAtMs;
  const AccountPageIndice({
    required this.accountId,
    required this.cacheKey,
    required this.itemIdsJson,
    required this.cachedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['cache_key'] = Variable<String>(cacheKey);
    map['item_ids_json'] = Variable<String>(itemIdsJson);
    map['cached_at_ms'] = Variable<int>(cachedAtMs);
    return map;
  }

  AccountPageIndicesCompanion toCompanion(bool nullToAbsent) {
    return AccountPageIndicesCompanion(
      accountId: Value(accountId),
      cacheKey: Value(cacheKey),
      itemIdsJson: Value(itemIdsJson),
      cachedAtMs: Value(cachedAtMs),
    );
  }

  factory AccountPageIndice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountPageIndice(
      accountId: serializer.fromJson<String>(json['accountId']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      itemIdsJson: serializer.fromJson<String>(json['itemIdsJson']),
      cachedAtMs: serializer.fromJson<int>(json['cachedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'itemIdsJson': serializer.toJson<String>(itemIdsJson),
      'cachedAtMs': serializer.toJson<int>(cachedAtMs),
    };
  }

  AccountPageIndice copyWith({
    String? accountId,
    String? cacheKey,
    String? itemIdsJson,
    int? cachedAtMs,
  }) => AccountPageIndice(
    accountId: accountId ?? this.accountId,
    cacheKey: cacheKey ?? this.cacheKey,
    itemIdsJson: itemIdsJson ?? this.itemIdsJson,
    cachedAtMs: cachedAtMs ?? this.cachedAtMs,
  );
  AccountPageIndice copyWithCompanion(AccountPageIndicesCompanion data) {
    return AccountPageIndice(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      itemIdsJson: data.itemIdsJson.present
          ? data.itemIdsJson.value
          : this.itemIdsJson,
      cachedAtMs: data.cachedAtMs.present
          ? data.cachedAtMs.value
          : this.cachedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountPageIndice(')
          ..write('accountId: $accountId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('itemIdsJson: $itemIdsJson, ')
          ..write('cachedAtMs: $cachedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, cacheKey, itemIdsJson, cachedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountPageIndice &&
          other.accountId == this.accountId &&
          other.cacheKey == this.cacheKey &&
          other.itemIdsJson == this.itemIdsJson &&
          other.cachedAtMs == this.cachedAtMs);
}

class AccountPageIndicesCompanion extends UpdateCompanion<AccountPageIndice> {
  final Value<String> accountId;
  final Value<String> cacheKey;
  final Value<String> itemIdsJson;
  final Value<int> cachedAtMs;
  final Value<int> rowid;
  const AccountPageIndicesCompanion({
    this.accountId = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.itemIdsJson = const Value.absent(),
    this.cachedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountPageIndicesCompanion.insert({
    required String accountId,
    required String cacheKey,
    required String itemIdsJson,
    required int cachedAtMs,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       cacheKey = Value(cacheKey),
       itemIdsJson = Value(itemIdsJson),
       cachedAtMs = Value(cachedAtMs);
  static Insertable<AccountPageIndice> custom({
    Expression<String>? accountId,
    Expression<String>? cacheKey,
    Expression<String>? itemIdsJson,
    Expression<int>? cachedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (itemIdsJson != null) 'item_ids_json': itemIdsJson,
      if (cachedAtMs != null) 'cached_at_ms': cachedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountPageIndicesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? cacheKey,
    Value<String>? itemIdsJson,
    Value<int>? cachedAtMs,
    Value<int>? rowid,
  }) {
    return AccountPageIndicesCompanion(
      accountId: accountId ?? this.accountId,
      cacheKey: cacheKey ?? this.cacheKey,
      itemIdsJson: itemIdsJson ?? this.itemIdsJson,
      cachedAtMs: cachedAtMs ?? this.cachedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (itemIdsJson.present) {
      map['item_ids_json'] = Variable<String>(itemIdsJson.value);
    }
    if (cachedAtMs.present) {
      map['cached_at_ms'] = Variable<int>(cachedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountPageIndicesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('itemIdsJson: $itemIdsJson, ')
          ..write('cachedAtMs: $cachedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CacheDatabase extends GeneratedDatabase {
  _$CacheDatabase(QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final $AccountPageIndicesTable accountPageIndices =
      $AccountPageIndicesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [accountPageIndices];
}

typedef $$AccountPageIndicesTableCreateCompanionBuilder =
    AccountPageIndicesCompanion Function({
      required String accountId,
      required String cacheKey,
      required String itemIdsJson,
      required int cachedAtMs,
      Value<int> rowid,
    });
typedef $$AccountPageIndicesTableUpdateCompanionBuilder =
    AccountPageIndicesCompanion Function({
      Value<String> accountId,
      Value<String> cacheKey,
      Value<String> itemIdsJson,
      Value<int> cachedAtMs,
      Value<int> rowid,
    });

class $$AccountPageIndicesTableFilterComposer
    extends Composer<_$CacheDatabase, $AccountPageIndicesTable> {
  $$AccountPageIndicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemIdsJson => $composableBuilder(
    column: $table.itemIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAtMs => $composableBuilder(
    column: $table.cachedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountPageIndicesTableOrderingComposer
    extends Composer<_$CacheDatabase, $AccountPageIndicesTable> {
  $$AccountPageIndicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemIdsJson => $composableBuilder(
    column: $table.itemIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAtMs => $composableBuilder(
    column: $table.cachedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountPageIndicesTableAnnotationComposer
    extends Composer<_$CacheDatabase, $AccountPageIndicesTable> {
  $$AccountPageIndicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get itemIdsJson => $composableBuilder(
    column: $table.itemIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAtMs => $composableBuilder(
    column: $table.cachedAtMs,
    builder: (column) => column,
  );
}

class $$AccountPageIndicesTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $AccountPageIndicesTable,
          AccountPageIndice,
          $$AccountPageIndicesTableFilterComposer,
          $$AccountPageIndicesTableOrderingComposer,
          $$AccountPageIndicesTableAnnotationComposer,
          $$AccountPageIndicesTableCreateCompanionBuilder,
          $$AccountPageIndicesTableUpdateCompanionBuilder,
          (
            AccountPageIndice,
            BaseReferences<
              _$CacheDatabase,
              $AccountPageIndicesTable,
              AccountPageIndice
            >,
          ),
          AccountPageIndice,
          PrefetchHooks Function()
        > {
  $$AccountPageIndicesTableTableManager(
    _$CacheDatabase db,
    $AccountPageIndicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountPageIndicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountPageIndicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountPageIndicesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> cacheKey = const Value.absent(),
                Value<String> itemIdsJson = const Value.absent(),
                Value<int> cachedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountPageIndicesCompanion(
                accountId: accountId,
                cacheKey: cacheKey,
                itemIdsJson: itemIdsJson,
                cachedAtMs: cachedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String cacheKey,
                required String itemIdsJson,
                required int cachedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AccountPageIndicesCompanion.insert(
                accountId: accountId,
                cacheKey: cacheKey,
                itemIdsJson: itemIdsJson,
                cachedAtMs: cachedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountPageIndicesTable, AccountPageIndice>(
                    table,
                  ),
                  BaseReferences<
                    _$CacheDatabase,
                    $AccountPageIndicesTable,
                    AccountPageIndice
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountPageIndicesTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $AccountPageIndicesTable,
      AccountPageIndice,
      $$AccountPageIndicesTableFilterComposer,
      $$AccountPageIndicesTableOrderingComposer,
      $$AccountPageIndicesTableAnnotationComposer,
      $$AccountPageIndicesTableCreateCompanionBuilder,
      $$AccountPageIndicesTableUpdateCompanionBuilder,
      (
        AccountPageIndice,
        BaseReferences<
          _$CacheDatabase,
          $AccountPageIndicesTable,
          AccountPageIndice
        >,
      ),
      AccountPageIndice,
      PrefetchHooks Function()
    >;

class $CacheDatabaseManager {
  final _$CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  $$AccountPageIndicesTableTableManager get accountPageIndices =>
      $$AccountPageIndicesTableTableManager(_db, _db.accountPageIndices);
}
