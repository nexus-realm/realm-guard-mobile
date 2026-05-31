// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailsMeta = const VerificationMeta('emails');
  @override
  late final GeneratedColumn<String> emails = GeneratedColumn<String>(
    'emails',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, emails];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emails')) {
      context.handle(
        _emailsMeta,
        emails.isAcceptableOrUnknown(data['emails']!, _emailsMeta),
      );
    } else if (isInserting) {
      context.missing(_emailsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emails'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final String emails;
  const Profile({required this.id, required this.name, required this.emails});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['emails'] = Variable<String>(emails);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      emails: Value(emails),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emails: serializer.fromJson<String>(json['emails']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emails': serializer.toJson<String>(emails),
    };
  }

  Profile copyWith({int? id, String? name, String? emails}) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    emails: emails ?? this.emails,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emails: data.emails.present ? data.emails.value : this.emails,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emails: $emails')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emails);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.emails == this.emails);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> emails;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emails = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String emails,
  }) : name = Value(name),
       emails = Value(emails);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emails,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emails != null) 'emails': emails,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? emails,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emails: emails ?? this.emails,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emails.present) {
      map['emails'] = Variable<String>(emails.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emails: $emails')
          ..write(')'))
        .toString();
  }
}

class $CredentialsTable extends Credentials
    with TableInfo<$CredentialsTable, Credential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, encryptedData, profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<Credential> instance, {
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
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Credential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Credential(
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
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
    );
  }

  @override
  $CredentialsTable createAlias(String alias) {
    return $CredentialsTable(attachedDatabase, alias);
  }
}

class Credential extends DataClass implements Insertable<Credential> {
  final int id;
  final String title;
  final String encryptedData;
  final int? profileId;
  const Credential({
    required this.id,
    required this.title,
    required this.encryptedData,
    this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['encrypted_data'] = Variable<String>(encryptedData);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    return map;
  }

  CredentialsCompanion toCompanion(bool nullToAbsent) {
    return CredentialsCompanion(
      id: Value(id),
      title: Value(title),
      encryptedData: Value(encryptedData),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
    );
  }

  factory Credential.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Credential(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      encryptedData: serializer.fromJson<String>(json['encryptedData']),
      profileId: serializer.fromJson<int?>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'encryptedData': serializer.toJson<String>(encryptedData),
      'profileId': serializer.toJson<int?>(profileId),
    };
  }

  Credential copyWith({
    int? id,
    String? title,
    String? encryptedData,
    Value<int?> profileId = const Value.absent(),
  }) => Credential(
    id: id ?? this.id,
    title: title ?? this.title,
    encryptedData: encryptedData ?? this.encryptedData,
    profileId: profileId.present ? profileId.value : this.profileId,
  );
  Credential copyWithCompanion(CredentialsCompanion data) {
    return Credential(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      encryptedData: data.encryptedData.present
          ? data.encryptedData.value
          : this.encryptedData,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Credential(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedData: $encryptedData, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, encryptedData, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Credential &&
          other.id == this.id &&
          other.title == this.title &&
          other.encryptedData == this.encryptedData &&
          other.profileId == this.profileId);
}

class CredentialsCompanion extends UpdateCompanion<Credential> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> encryptedData;
  final Value<int?> profileId;
  const CredentialsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.encryptedData = const Value.absent(),
    this.profileId = const Value.absent(),
  });
  CredentialsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String encryptedData,
    this.profileId = const Value.absent(),
  }) : title = Value(title),
       encryptedData = Value(encryptedData);
  static Insertable<Credential> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? encryptedData,
    Expression<int>? profileId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (encryptedData != null) 'encrypted_data': encryptedData,
      if (profileId != null) 'profile_id': profileId,
    });
  }

  CredentialsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? encryptedData,
    Value<int?>? profileId,
  }) {
    return CredentialsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      encryptedData: encryptedData ?? this.encryptedData,
      profileId: profileId ?? this.profileId,
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
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedData: $encryptedData, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $CredentialsTable credentials = $CredentialsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles, credentials];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String emails,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> emails,
    });

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CredentialsTable, List<Credential>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: $_aliasNameGenerator(db.profiles.id, db.credentials.profileId),
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emails => $composableBuilder(
    column: $table.emails,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emails => $composableBuilder(
    column: $table.emails,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emails =>
      $composableBuilder(column: $table.emails, builder: (column) => column);

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({bool credentialsRefs})
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emails = const Value.absent(),
              }) => ProfilesCompanion(id: id, name: name, emails: emails),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String emails,
              }) =>
                  ProfilesCompanion.insert(id: id, name: name, emails: emails),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({credentialsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (credentialsRefs) db.credentials],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (credentialsRefs)
                    await $_getPrefetchedData<
                      Profile,
                      $ProfilesTable,
                      Credential
                    >(
                      currentTable: table,
                      referencedTable: $$ProfilesTableReferences
                          ._credentialsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProfilesTableReferences(
                        db,
                        table,
                        p0,
                      ).credentialsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.profileId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({bool credentialsRefs})
    >;
typedef $$CredentialsTableCreateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      required String title,
      required String encryptedData,
      Value<int?> profileId,
    });
typedef $$CredentialsTableUpdateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> encryptedData,
      Value<int?> profileId,
    });

final class $$CredentialsTableReferences
    extends BaseReferences<_$AppDatabase, $CredentialsTable, Credential> {
  $$CredentialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias(
        $_aliasNameGenerator(db.credentials.profileId, db.profiles.id),
      );

  $$ProfilesTableProcessedTableManager? get profileId {
    final $_column = $_itemColumn<int>('profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableFilterComposer({
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

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableOrderingComposer({
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

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableAnnotationComposer({
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

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialsTable,
          Credential,
          $$CredentialsTableFilterComposer,
          $$CredentialsTableOrderingComposer,
          $$CredentialsTableAnnotationComposer,
          $$CredentialsTableCreateCompanionBuilder,
          $$CredentialsTableUpdateCompanionBuilder,
          (Credential, $$CredentialsTableReferences),
          Credential,
          PrefetchHooks Function({bool profileId})
        > {
  $$CredentialsTableTableManager(_$AppDatabase db, $CredentialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> encryptedData = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
              }) => CredentialsCompanion(
                id: id,
                title: title,
                encryptedData: encryptedData,
                profileId: profileId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String encryptedData,
                Value<int?> profileId = const Value.absent(),
              }) => CredentialsCompanion.insert(
                id: id,
                title: title,
                encryptedData: encryptedData,
                profileId: profileId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CredentialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$CredentialsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$CredentialsTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialsTable,
      Credential,
      $$CredentialsTableFilterComposer,
      $$CredentialsTableOrderingComposer,
      $$CredentialsTableAnnotationComposer,
      $$CredentialsTableCreateCompanionBuilder,
      $$CredentialsTableUpdateCompanionBuilder,
      (Credential, $$CredentialsTableReferences),
      Credential,
      PrefetchHooks Function({bool profileId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db, _db.credentials);
}
