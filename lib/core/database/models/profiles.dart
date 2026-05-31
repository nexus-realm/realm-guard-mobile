import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emails => text()(); // JSON list of emails
}
