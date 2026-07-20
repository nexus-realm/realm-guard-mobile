import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
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
