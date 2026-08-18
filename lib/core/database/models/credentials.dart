import 'package:drift/drift.dart';

import 'profiles.dart';
import 'sync_id.dart';

class Credentials extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Clé stable de synchronisation (16 o) ⇔ `EntryId` du CRDT. Indexée unique
  /// (index créé en migration). `clientDefault` garantit un id sur toute
  /// insertion hors chemin CRDT.
  BlobColumn get syncId => blob().nullable().clientDefault(generateSyncId)();

  TextColumn get title => text()();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  TextColumn get uri => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Champs personnalisés, encodés JSON : liste d'objets
  /// `{ "label": ..., "value": ..., "secret": bool }`.
  TextColumn get customFields => text().withDefault(const Constant('[]'))();

  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get profileId => integer().nullable().references(Profiles, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
