// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VaultEntriesTable extends VaultEntries
    with TableInfo<$VaultEntriesTable, VaultEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedDataMeta = const VerificationMeta(
    'encryptedData',
  );
  @override
  late final GeneratedColumn<String> encryptedData = GeneratedColumn<String>(
    'encrypted_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, encryptedData];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('encrypted_data')) {
      context.handle(
        _encryptedDataMeta,
        encryptedData.isAcceptableOrUnknown(
          data['encrypted_data']!,
          _encryptedDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedDataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      encryptedData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_data'],
      )!,
    );
  }

  @override
  $VaultEntriesTable createAlias(String alias) {
    return $VaultEntriesTable(attachedDatabase, alias);
  }
}

class VaultEntry extends DataClass implements Insertable<VaultEntry> {
  final int id;
  final String title;
  final String encryptedData;
  const VaultEntry({
    required this.id,
    required this.title,
    required this.encryptedData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['encrypted_data'] = Variable<String>(encryptedData);
    return map;
  }

  VaultEntriesCompanion toCompanion(bool nullToAbsent) {
    return VaultEntriesCompanion(
      id: Value(id),
      title: Value(title),
      encryptedData: Value(encryptedData),
    );
  }

  factory VaultEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      encryptedData: serializer.fromJson<String>(json['encryptedData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'encryptedData': serializer.toJson<String>(encryptedData),
    };
  }

  VaultEntry copyWith({int? id, String? title, String? encryptedData}) =>
      VaultEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        encryptedData: encryptedData ?? this.encryptedData,
      );
  VaultEntry copyWithCompanion(VaultEntriesCompanion data) {
    return VaultEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      encryptedData: data.encryptedData.present
          ? data.encryptedData.value
          : this.encryptedData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedData: $encryptedData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, encryptedData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.encryptedData == this.encryptedData);
}

class VaultEntriesCompanion extends UpdateCompanion<VaultEntry> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> encryptedData;
  const VaultEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.encryptedData = const Value.absent(),
  });
  VaultEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String encryptedData,
  }) : title = Value(title),
       encryptedData = Value(encryptedData);
  static Insertable<VaultEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? encryptedData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (encryptedData != null) 'encrypted_data': encryptedData,
    });
  }

  VaultEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? encryptedData,
  }) {
    return VaultEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      encryptedData: encryptedData ?? this.encryptedData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (encryptedData.present) {
      map['encrypted_data'] = Variable<String>(encryptedData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedData: $encryptedData')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VaultEntriesTable vaultEntries = $VaultEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vaultEntries];
}

typedef $$VaultEntriesTableCreateCompanionBuilder =
    VaultEntriesCompanion Function({
      Value<int> id,
      required String title,
      required String encryptedData,
    });
typedef $$VaultEntriesTableUpdateCompanionBuilder =
    VaultEntriesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> encryptedData,
    });

class $$VaultEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedData => $composableBuilder(
    column: $table.encryptedData,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedData => $composableBuilder(
    column: $table.encryptedData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultEntriesTable> {
  $$VaultEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get encryptedData => $composableBuilder(
    column: $table.encryptedData,
    builder: (column) => column,
  );
}

class $$VaultEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultEntriesTable,
          VaultEntry,
          $$VaultEntriesTableFilterComposer,
          $$VaultEntriesTableOrderingComposer,
          $$VaultEntriesTableAnnotationComposer,
          $$VaultEntriesTableCreateCompanionBuilder,
          $$VaultEntriesTableUpdateCompanionBuilder,
          (
            VaultEntry,
            BaseReferences<_$AppDatabase, $VaultEntriesTable, VaultEntry>,
          ),
          VaultEntry,
          PrefetchHooks Function()
        > {
  $$VaultEntriesTableTableManager(_$AppDatabase db, $VaultEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> encryptedData = const Value.absent(),
              }) => VaultEntriesCompanion(
                id: id,
                title: title,
                encryptedData: encryptedData,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String encryptedData,
              }) => VaultEntriesCompanion.insert(
                id: id,
                title: title,
                encryptedData: encryptedData,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultEntriesTable,
      VaultEntry,
      $$VaultEntriesTableFilterComposer,
      $$VaultEntriesTableOrderingComposer,
      $$VaultEntriesTableAnnotationComposer,
      $$VaultEntriesTableCreateCompanionBuilder,
      $$VaultEntriesTableUpdateCompanionBuilder,
      (
        VaultEntry,
        BaseReferences<_$AppDatabase, $VaultEntriesTable, VaultEntry>,
      ),
      VaultEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultEntriesTableTableManager get vaultEntries =>
      $$VaultEntriesTableTableManager(_db, _db.vaultEntries);
}
