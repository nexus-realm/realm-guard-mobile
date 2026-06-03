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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        await migrator.renameTable(credentials, 'vault_entries');
        await migrator.addColumn(credentials, credentials.profileId);
        await migrator.createTable(profiles);
      }
      if (from < 3) {
        // Credentials : nouveaux champs structurés + métadonnées.
        await migrator.addColumn(credentials, credentials.username);
        await migrator.addColumn(credentials, credentials.password);
        await migrator.addColumn(credentials, credentials.uri);
        await migrator.addColumn(credentials, credentials.notes);
        await migrator.addColumn(credentials, credentials.customFields);
        await migrator.addColumn(credentials, credentials.favorite);
        await migrator.addColumn(credentials, credentials.createdAt);
        await migrator.addColumn(credentials, credentials.updatedAt);

        // Reprise des données : l'ancien blob `encryptedData` devient `notes`.
        await customStatement(
          'UPDATE credentials SET notes = encrypted_data '
          'WHERE encrypted_data IS NOT NULL AND encrypted_data != \'\'',
        );
        // L'ancienne colonne n'est plus utilisée (SQLite récent supporte DROP).
        await customStatement(
          'ALTER TABLE credentials DROP COLUMN encrypted_data',
        );

        // Profiles : nouveaux champs.
        await migrator.addColumn(profiles, profiles.usernames);
        await migrator.addColumn(profiles, profiles.phoneNumbers);
        await migrator.addColumn(profiles, profiles.color);
        await migrator.addColumn(profiles, profiles.note);
        await migrator.addColumn(profiles, profiles.createdAt);
        await migrator.addColumn(profiles, profiles.updatedAt);
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
