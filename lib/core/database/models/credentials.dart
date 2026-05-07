import 'package:drift/drift.dart';

import 'profiles.dart';

class Credentials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get encryptedData => text()();
  IntColumn get profileId => integer().nullable().references(Profiles, #id)();
}
