import 'package:drift/drift.dart';

import 'sync_id.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Clé stable de synchronisation (16 o) ⇔ `EntryId` du CRDT. Indexée unique
  /// (index créé en migration). `clientDefault` garantit un id sur toute
  /// insertion hors chemin CRDT.
  BlobColumn get syncId => blob().nullable().clientDefault(generateSyncId)();

  TextColumn get name => text()();

  /// Listes encodées JSON (tableau de chaînes).
  TextColumn get emails => text()();
  TextColumn get usernames => text().withDefault(const Constant('[]'))();
  TextColumn get phoneNumbers => text().withDefault(const Constant('[]'))();

  /// Repère visuel : valeur ARGB d'une couleur d'une palette fixe.
  IntColumn get color => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
