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
  static const VerificationMeta _usernamesMeta = const VerificationMeta(
    'usernames',
  );
  @override
  late final GeneratedColumn<String> usernames = GeneratedColumn<String>(
    'usernames',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _phoneNumbersMeta = const VerificationMeta(
    'phoneNumbers',
  );
  @override
  late final GeneratedColumn<String> phoneNumbers = GeneratedColumn<String>(
    'phone_numbers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    emails,
    usernames,
    phoneNumbers,
    color,
    note,
    createdAt,
    updatedAt,
  ];
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
    if (data.containsKey('usernames')) {
      context.handle(
        _usernamesMeta,
        usernames.isAcceptableOrUnknown(data['usernames']!, _usernamesMeta),
      );
    }
    if (data.containsKey('phone_numbers')) {
      context.handle(
        _phoneNumbersMeta,
        phoneNumbers.isAcceptableOrUnknown(
          data['phone_numbers']!,
          _phoneNumbersMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
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
      usernames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usernames'],
      )!,
      phoneNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_numbers'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
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

  /// Listes encodées JSON (tableau de chaînes).
  final String emails;
  final String usernames;
  final String phoneNumbers;

  /// Repère visuel : valeur ARGB d'une couleur d'une palette fixe.
  final int? color;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Profile({
    required this.id,
    required this.name,
    required this.emails,
    required this.usernames,
    required this.phoneNumbers,
    this.color,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['emails'] = Variable<String>(emails);
    map['usernames'] = Variable<String>(usernames);
    map['phone_numbers'] = Variable<String>(phoneNumbers);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      emails: Value(emails),
      usernames: Value(usernames),
      phoneNumbers: Value(phoneNumbers),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      usernames: serializer.fromJson<String>(json['usernames']),
      phoneNumbers: serializer.fromJson<String>(json['phoneNumbers']),
      color: serializer.fromJson<int?>(json['color']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emails': serializer.toJson<String>(emails),
      'usernames': serializer.toJson<String>(usernames),
      'phoneNumbers': serializer.toJson<String>(phoneNumbers),
      'color': serializer.toJson<int?>(color),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    String? emails,
    String? usernames,
    String? phoneNumbers,
    Value<int?> color = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    emails: emails ?? this.emails,
    usernames: usernames ?? this.usernames,
    phoneNumbers: phoneNumbers ?? this.phoneNumbers,
    color: color.present ? color.value : this.color,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emails: data.emails.present ? data.emails.value : this.emails,
      usernames: data.usernames.present ? data.usernames.value : this.usernames,
      phoneNumbers: data.phoneNumbers.present
          ? data.phoneNumbers.value
          : this.phoneNumbers,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emails: $emails, ')
          ..write('usernames: $usernames, ')
          ..write('phoneNumbers: $phoneNumbers, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    emails,
    usernames,
    phoneNumbers,
    color,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.emails == this.emails &&
          other.usernames == this.usernames &&
          other.phoneNumbers == this.phoneNumbers &&
          other.color == this.color &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> emails;
  final Value<String> usernames;
  final Value<String> phoneNumbers;
  final Value<int?> color;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emails = const Value.absent(),
    this.usernames = const Value.absent(),
    this.phoneNumbers = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String emails,
    this.usernames = const Value.absent(),
    this.phoneNumbers = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       emails = Value(emails);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emails,
    Expression<String>? usernames,
    Expression<String>? phoneNumbers,
    Expression<int>? color,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emails != null) 'emails': emails,
      if (usernames != null) 'usernames': usernames,
      if (phoneNumbers != null) 'phone_numbers': phoneNumbers,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? emails,
    Value<String>? usernames,
    Value<String>? phoneNumbers,
    Value<int?>? color,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emails: emails ?? this.emails,
      usernames: usernames ?? this.usernames,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (usernames.present) {
      map['usernames'] = Variable<String>(usernames.value);
    }
    if (phoneNumbers.present) {
      map['phone_numbers'] = Variable<String>(phoneNumbers.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emails: $emails, ')
          ..write('usernames: $usernames, ')
          ..write('phoneNumbers: $phoneNumbers, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customFieldsMeta = const VerificationMeta(
    'customFields',
  );
  @override
  late final GeneratedColumn<String> customFields = GeneratedColumn<String>(
    'custom_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    username,
    password,
    uri,
    notes,
    customFields,
    favorite,
    profileId,
    createdAt,
    updatedAt,
  ];
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
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('custom_fields')) {
      context.handle(
        _customFieldsMeta,
        customFields.isAcceptableOrUnknown(
          data['custom_fields']!,
          _customFieldsMeta,
        ),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
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
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      ),
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      customFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
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
  final String? username;
  final String? password;
  final String? uri;
  final String? notes;

  /// Champs personnalisés, encodés JSON : liste d'objets
  /// `{ "label": ..., "value": ..., "secret": bool }`.
  final String customFields;
  final bool favorite;
  final int? profileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Credential({
    required this.id,
    required this.title,
    this.username,
    this.password,
    this.uri,
    this.notes,
    required this.customFields,
    required this.favorite,
    this.profileId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || uri != null) {
      map['uri'] = Variable<String>(uri);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['custom_fields'] = Variable<String>(customFields);
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CredentialsCompanion toCompanion(bool nullToAbsent) {
    return CredentialsCompanion(
      id: Value(id),
      title: Value(title),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      uri: uri == null && nullToAbsent ? const Value.absent() : Value(uri),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      customFields: Value(customFields),
      favorite: Value(favorite),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      username: serializer.fromJson<String?>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      uri: serializer.fromJson<String?>(json['uri']),
      notes: serializer.fromJson<String?>(json['notes']),
      customFields: serializer.fromJson<String>(json['customFields']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'username': serializer.toJson<String?>(username),
      'password': serializer.toJson<String?>(password),
      'uri': serializer.toJson<String?>(uri),
      'notes': serializer.toJson<String?>(notes),
      'customFields': serializer.toJson<String>(customFields),
      'favorite': serializer.toJson<bool>(favorite),
      'profileId': serializer.toJson<int?>(profileId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Credential copyWith({
    int? id,
    String? title,
    Value<String?> username = const Value.absent(),
    Value<String?> password = const Value.absent(),
    Value<String?> uri = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? customFields,
    bool? favorite,
    Value<int?> profileId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Credential(
    id: id ?? this.id,
    title: title ?? this.title,
    username: username.present ? username.value : this.username,
    password: password.present ? password.value : this.password,
    uri: uri.present ? uri.value : this.uri,
    notes: notes.present ? notes.value : this.notes,
    customFields: customFields ?? this.customFields,
    favorite: favorite ?? this.favorite,
    profileId: profileId.present ? profileId.value : this.profileId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Credential copyWithCompanion(CredentialsCompanion data) {
    return Credential(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      uri: data.uri.present ? data.uri.value : this.uri,
      notes: data.notes.present ? data.notes.value : this.notes,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Credential(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('uri: $uri, ')
          ..write('notes: $notes, ')
          ..write('customFields: $customFields, ')
          ..write('favorite: $favorite, ')
          ..write('profileId: $profileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    username,
    password,
    uri,
    notes,
    customFields,
    favorite,
    profileId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Credential &&
          other.id == this.id &&
          other.title == this.title &&
          other.username == this.username &&
          other.password == this.password &&
          other.uri == this.uri &&
          other.notes == this.notes &&
          other.customFields == this.customFields &&
          other.favorite == this.favorite &&
          other.profileId == this.profileId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CredentialsCompanion extends UpdateCompanion<Credential> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> username;
  final Value<String?> password;
  final Value<String?> uri;
  final Value<String?> notes;
  final Value<String> customFields;
  final Value<bool> favorite;
  final Value<int?> profileId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CredentialsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.uri = const Value.absent(),
    this.notes = const Value.absent(),
    this.customFields = const Value.absent(),
    this.favorite = const Value.absent(),
    this.profileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CredentialsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.uri = const Value.absent(),
    this.notes = const Value.absent(),
    this.customFields = const Value.absent(),
    this.favorite = const Value.absent(),
    this.profileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Credential> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? uri,
    Expression<String>? notes,
    Expression<String>? customFields,
    Expression<bool>? favorite,
    Expression<int>? profileId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (uri != null) 'uri': uri,
      if (notes != null) 'notes': notes,
      if (customFields != null) 'custom_fields': customFields,
      if (favorite != null) 'favorite': favorite,
      if (profileId != null) 'profile_id': profileId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CredentialsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? username,
    Value<String?>? password,
    Value<String?>? uri,
    Value<String?>? notes,
    Value<String>? customFields,
    Value<bool>? favorite,
    Value<int?>? profileId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CredentialsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      uri: uri ?? this.uri,
      notes: notes ?? this.notes,
      customFields: customFields ?? this.customFields,
      favorite: favorite ?? this.favorite,
      profileId: profileId ?? this.profileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(customFields.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('uri: $uri, ')
          ..write('notes: $notes, ')
          ..write('customFields: $customFields, ')
          ..write('favorite: $favorite, ')
          ..write('profileId: $profileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TotpsTable extends Totps with TableInfo<$TotpsTable, Totp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TotpsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secretMeta = const VerificationMeta('secret');
  @override
  late final GeneratedColumn<String> secret = GeneratedColumn<String>(
    'secret',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _digitsMeta = const VerificationMeta('digits');
  @override
  late final GeneratedColumn<int> digits = GeneratedColumn<int>(
    'digits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _algorithmMeta = const VerificationMeta(
    'algorithm',
  );
  @override
  late final GeneratedColumn<String> algorithm = GeneratedColumn<String>(
    'algorithm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SHA1'),
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
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    account,
    secret,
    digits,
    period,
    algorithm,
    profileId,
    favorite,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'totps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Totp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('secret')) {
      context.handle(
        _secretMeta,
        secret.isAcceptableOrUnknown(data['secret']!, _secretMeta),
      );
    } else if (isInserting) {
      context.missing(_secretMeta);
    }
    if (data.containsKey('digits')) {
      context.handle(
        _digitsMeta,
        digits.isAcceptableOrUnknown(data['digits']!, _digitsMeta),
      );
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    }
    if (data.containsKey('algorithm')) {
      context.handle(
        _algorithmMeta,
        algorithm.isAcceptableOrUnknown(data['algorithm']!, _algorithmMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Totp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Totp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      secret: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret'],
      )!,
      digits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}digits'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      algorithm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}algorithm'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      ),
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TotpsTable createAlias(String alias) {
    return $TotpsTable(attachedDatabase, alias);
  }
}

class Totp extends DataClass implements Insertable<Totp> {
  final int id;

  /// Libellé affiché (ex. « GitHub »).
  final String label;

  /// Compte associé (ex. « me@example.com »).
  final String? account;

  /// Secret partagé, encodé en Base32.
  final String secret;

  /// Paramètres TOTP (valeurs par défaut RFC 6238 / usage courant).
  final int digits;
  final int period;

  /// Algorithme HMAC : 'SHA1' (défaut), 'SHA256' ou 'SHA512'.
  final String algorithm;
  final int? profileId;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Totp({
    required this.id,
    required this.label,
    this.account,
    required this.secret,
    required this.digits,
    required this.period,
    required this.algorithm,
    this.profileId,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || account != null) {
      map['account'] = Variable<String>(account);
    }
    map['secret'] = Variable<String>(secret);
    map['digits'] = Variable<int>(digits);
    map['period'] = Variable<int>(period);
    map['algorithm'] = Variable<String>(algorithm);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    map['favorite'] = Variable<bool>(favorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TotpsCompanion toCompanion(bool nullToAbsent) {
    return TotpsCompanion(
      id: Value(id),
      label: Value(label),
      account: account == null && nullToAbsent
          ? const Value.absent()
          : Value(account),
      secret: Value(secret),
      digits: Value(digits),
      period: Value(period),
      algorithm: Value(algorithm),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      favorite: Value(favorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Totp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Totp(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      account: serializer.fromJson<String?>(json['account']),
      secret: serializer.fromJson<String>(json['secret']),
      digits: serializer.fromJson<int>(json['digits']),
      period: serializer.fromJson<int>(json['period']),
      algorithm: serializer.fromJson<String>(json['algorithm']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'account': serializer.toJson<String?>(account),
      'secret': serializer.toJson<String>(secret),
      'digits': serializer.toJson<int>(digits),
      'period': serializer.toJson<int>(period),
      'algorithm': serializer.toJson<String>(algorithm),
      'profileId': serializer.toJson<int?>(profileId),
      'favorite': serializer.toJson<bool>(favorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Totp copyWith({
    int? id,
    String? label,
    Value<String?> account = const Value.absent(),
    String? secret,
    int? digits,
    int? period,
    String? algorithm,
    Value<int?> profileId = const Value.absent(),
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Totp(
    id: id ?? this.id,
    label: label ?? this.label,
    account: account.present ? account.value : this.account,
    secret: secret ?? this.secret,
    digits: digits ?? this.digits,
    period: period ?? this.period,
    algorithm: algorithm ?? this.algorithm,
    profileId: profileId.present ? profileId.value : this.profileId,
    favorite: favorite ?? this.favorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Totp copyWithCompanion(TotpsCompanion data) {
    return Totp(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      account: data.account.present ? data.account.value : this.account,
      secret: data.secret.present ? data.secret.value : this.secret,
      digits: data.digits.present ? data.digits.value : this.digits,
      period: data.period.present ? data.period.value : this.period,
      algorithm: data.algorithm.present ? data.algorithm.value : this.algorithm,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Totp(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('account: $account, ')
          ..write('secret: $secret, ')
          ..write('digits: $digits, ')
          ..write('period: $period, ')
          ..write('algorithm: $algorithm, ')
          ..write('profileId: $profileId, ')
          ..write('favorite: $favorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    account,
    secret,
    digits,
    period,
    algorithm,
    profileId,
    favorite,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Totp &&
          other.id == this.id &&
          other.label == this.label &&
          other.account == this.account &&
          other.secret == this.secret &&
          other.digits == this.digits &&
          other.period == this.period &&
          other.algorithm == this.algorithm &&
          other.profileId == this.profileId &&
          other.favorite == this.favorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TotpsCompanion extends UpdateCompanion<Totp> {
  final Value<int> id;
  final Value<String> label;
  final Value<String?> account;
  final Value<String> secret;
  final Value<int> digits;
  final Value<int> period;
  final Value<String> algorithm;
  final Value<int?> profileId;
  final Value<bool> favorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TotpsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.account = const Value.absent(),
    this.secret = const Value.absent(),
    this.digits = const Value.absent(),
    this.period = const Value.absent(),
    this.algorithm = const Value.absent(),
    this.profileId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TotpsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    this.account = const Value.absent(),
    required String secret,
    this.digits = const Value.absent(),
    this.period = const Value.absent(),
    this.algorithm = const Value.absent(),
    this.profileId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : label = Value(label),
       secret = Value(secret);
  static Insertable<Totp> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? account,
    Expression<String>? secret,
    Expression<int>? digits,
    Expression<int>? period,
    Expression<String>? algorithm,
    Expression<int>? profileId,
    Expression<bool>? favorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (account != null) 'account': account,
      if (secret != null) 'secret': secret,
      if (digits != null) 'digits': digits,
      if (period != null) 'period': period,
      if (algorithm != null) 'algorithm': algorithm,
      if (profileId != null) 'profile_id': profileId,
      if (favorite != null) 'favorite': favorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TotpsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<String?>? account,
    Value<String>? secret,
    Value<int>? digits,
    Value<int>? period,
    Value<String>? algorithm,
    Value<int?>? profileId,
    Value<bool>? favorite,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TotpsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      account: account ?? this.account,
      secret: secret ?? this.secret,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      algorithm: algorithm ?? this.algorithm,
      profileId: profileId ?? this.profileId,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (secret.present) {
      map['secret'] = Variable<String>(secret.value);
    }
    if (digits.present) {
      map['digits'] = Variable<int>(digits.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (algorithm.present) {
      map['algorithm'] = Variable<String>(algorithm.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TotpsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('account: $account, ')
          ..write('secret: $secret, ')
          ..write('digits: $digits, ')
          ..write('period: $period, ')
          ..write('algorithm: $algorithm, ')
          ..write('profileId: $profileId, ')
          ..write('favorite: $favorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $CredentialsTable credentials = $CredentialsTable(this);
  late final $TotpsTable totps = $TotpsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    credentials,
    totps,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String emails,
      Value<String> usernames,
      Value<String> phoneNumbers,
      Value<int?> color,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> emails,
      Value<String> usernames,
      Value<String> phoneNumbers,
      Value<int?> color,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
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

  static MultiTypedResultKey<$TotpsTable, List<Totp>> _totpsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.totps,
    aliasName: $_aliasNameGenerator(db.profiles.id, db.totps.profileId),
  );

  $$TotpsTableProcessedTableManager get totpsRefs {
    final manager = $$TotpsTableTableManager(
      $_db,
      $_db.totps,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_totpsRefsTable($_db));
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

  ColumnFilters<String> get usernames => $composableBuilder(
    column: $table.usernames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumbers => $composableBuilder(
    column: $table.phoneNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  Expression<bool> totpsRefs(
    Expression<bool> Function($$TotpsTableFilterComposer f) f,
  ) {
    final $$TotpsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.totps,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TotpsTableFilterComposer(
            $db: $db,
            $table: $db.totps,
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

  ColumnOrderings<String> get usernames => $composableBuilder(
    column: $table.usernames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumbers => $composableBuilder(
    column: $table.phoneNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  GeneratedColumn<String> get usernames =>
      $composableBuilder(column: $table.usernames, builder: (column) => column);

  GeneratedColumn<String> get phoneNumbers => $composableBuilder(
    column: $table.phoneNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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

  Expression<T> totpsRefs<T extends Object>(
    Expression<T> Function($$TotpsTableAnnotationComposer a) f,
  ) {
    final $$TotpsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.totps,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TotpsTableAnnotationComposer(
            $db: $db,
            $table: $db.totps,
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
          PrefetchHooks Function({bool credentialsRefs, bool totpsRefs})
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
                Value<String> usernames = const Value.absent(),
                Value<String> phoneNumbers = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                emails: emails,
                usernames: usernames,
                phoneNumbers: phoneNumbers,
                color: color,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String emails,
                Value<String> usernames = const Value.absent(),
                Value<String> phoneNumbers = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                emails: emails,
                usernames: usernames,
                phoneNumbers: phoneNumbers,
                color: color,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({credentialsRefs = false, totpsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (credentialsRefs) db.credentials,
                    if (totpsRefs) db.totps,
                  ],
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
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (totpsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Totp
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._totpsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).totpsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
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
      PrefetchHooks Function({bool credentialsRefs, bool totpsRefs})
    >;
typedef $$CredentialsTableCreateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> username,
      Value<String?> password,
      Value<String?> uri,
      Value<String?> notes,
      Value<String> customFields,
      Value<bool> favorite,
      Value<int?> profileId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CredentialsTableUpdateCompanionBuilder =
    CredentialsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> username,
      Value<String?> password,
      Value<String?> uri,
      Value<String?> notes,
      Value<String> customFields,
      Value<bool> favorite,
      Value<int?> profileId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
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

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> uri = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> customFields = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CredentialsCompanion(
                id: id,
                title: title,
                username: username,
                password: password,
                uri: uri,
                notes: notes,
                customFields: customFields,
                favorite: favorite,
                profileId: profileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> uri = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> customFields = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CredentialsCompanion.insert(
                id: id,
                title: title,
                username: username,
                password: password,
                uri: uri,
                notes: notes,
                customFields: customFields,
                favorite: favorite,
                profileId: profileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
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
typedef $$TotpsTableCreateCompanionBuilder =
    TotpsCompanion Function({
      Value<int> id,
      required String label,
      Value<String?> account,
      required String secret,
      Value<int> digits,
      Value<int> period,
      Value<String> algorithm,
      Value<int?> profileId,
      Value<bool> favorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TotpsTableUpdateCompanionBuilder =
    TotpsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<String?> account,
      Value<String> secret,
      Value<int> digits,
      Value<int> period,
      Value<String> algorithm,
      Value<int?> profileId,
      Value<bool> favorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TotpsTableReferences
    extends BaseReferences<_$AppDatabase, $TotpsTable, Totp> {
  $$TotpsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) => db.profiles
      .createAlias($_aliasNameGenerator(db.totps.profileId, db.profiles.id));

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

class $$TotpsTableFilterComposer extends Composer<_$AppDatabase, $TotpsTable> {
  $$TotpsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get digits => $composableBuilder(
    column: $table.digits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get algorithm => $composableBuilder(
    column: $table.algorithm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

class $$TotpsTableOrderingComposer
    extends Composer<_$AppDatabase, $TotpsTable> {
  $$TotpsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get digits => $composableBuilder(
    column: $table.digits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get algorithm => $composableBuilder(
    column: $table.algorithm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

class $$TotpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TotpsTable> {
  $$TotpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get secret =>
      $composableBuilder(column: $table.secret, builder: (column) => column);

  GeneratedColumn<int> get digits =>
      $composableBuilder(column: $table.digits, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get algorithm =>
      $composableBuilder(column: $table.algorithm, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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

class $$TotpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TotpsTable,
          Totp,
          $$TotpsTableFilterComposer,
          $$TotpsTableOrderingComposer,
          $$TotpsTableAnnotationComposer,
          $$TotpsTableCreateCompanionBuilder,
          $$TotpsTableUpdateCompanionBuilder,
          (Totp, $$TotpsTableReferences),
          Totp,
          PrefetchHooks Function({bool profileId})
        > {
  $$TotpsTableTableManager(_$AppDatabase db, $TotpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TotpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TotpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TotpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<String> secret = const Value.absent(),
                Value<int> digits = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<String> algorithm = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TotpsCompanion(
                id: id,
                label: label,
                account: account,
                secret: secret,
                digits: digits,
                period: period,
                algorithm: algorithm,
                profileId: profileId,
                favorite: favorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                Value<String?> account = const Value.absent(),
                required String secret,
                Value<int> digits = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<String> algorithm = const Value.absent(),
                Value<int?> profileId = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TotpsCompanion.insert(
                id: id,
                label: label,
                account: account,
                secret: secret,
                digits: digits,
                period: period,
                algorithm: algorithm,
                profileId: profileId,
                favorite: favorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TotpsTableReferences(db, table, e)),
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
                                referencedTable: $$TotpsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$TotpsTableReferences
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

typedef $$TotpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TotpsTable,
      Totp,
      $$TotpsTableFilterComposer,
      $$TotpsTableOrderingComposer,
      $$TotpsTableAnnotationComposer,
      $$TotpsTableCreateCompanionBuilder,
      $$TotpsTableUpdateCompanionBuilder,
      (Totp, $$TotpsTableReferences),
      Totp,
      PrefetchHooks Function({bool profileId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db, _db.credentials);
  $$TotpsTableTableManager get totps =>
      $$TotpsTableTableManager(_db, _db.totps);
}
