import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/credentials.dart';
import 'models/profiles.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Credentials])
class AppDatabase extends _$AppDatabase {
  AppDatabase(List<int> encryptionKeyBytes)
    : super(_openConnection(encryptionKeyBytes));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        await migrator.renameTable(credentials, 'vault_entries');
        await migrator.addColumn(credentials, credentials.profileId);
        await migrator.createTable(profiles);
      }
    },
  );
}

LazyDatabase _openConnection(List<int> encryptionKeyBytes) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'realm_guard_vault.sqlite'));

    // Conversion de la clé en hexadécimal pour l'utiliser dans la PRAGMA key
    final hexKey = encryptionKeyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    return NativeDatabase(
      file,
      setup: (db) {
        db.execute("PRAGMA key = \"x'$hexKey'\";");
        db.execute("PRAGMA cipher_page_size = 4096;");
        db.execute("SELECT count(*) FROM sqlite_master;");
      },
    );
  });
}
