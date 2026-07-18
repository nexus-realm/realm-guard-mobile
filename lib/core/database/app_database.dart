import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/crdt_docs.dart';
import 'models/credentials.dart';
import 'models/pending_deltas.dart';
import 'models/profiles.dart';
import 'models/sync_id.dart';
import 'models/totps.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Credentials, Totps, CrdtDocs, PendingDeltas])
class AppDatabase extends _$AppDatabase {
  AppDatabase(List<int> encryptionKeyBytes)
    : super(_openConnection(encryptionKeyBytes));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createSyncIdIndexes();
    },
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
      if (from < 4) {
        // Nouveau type de secret : TOTP.
        await migrator.createTable(totps);
      }
      if (from < 5) {
        // Synchronisation CRDT : clé stable `syncId` (⇔ `EntryId`) par ligne.
        await migrator.addColumn(profiles, profiles.syncId);
        await migrator.addColumn(credentials, credentials.syncId);
        await migrator.addColumn(totps, totps.syncId);
        // Attribue un id de sync (16 o) à chaque ligne v1 existante.
        // `randomblob(16)` : généré côté SQLite, sans aller-retour Dart.
        await customStatement(
          'UPDATE profiles SET sync_id = randomblob(16) WHERE sync_id IS NULL',
        );
        await customStatement(
          'UPDATE credentials SET sync_id = randomblob(16) WHERE sync_id IS NULL',
        );
        await customStatement(
          'UPDATE totps SET sync_id = randomblob(16) WHERE sync_id IS NULL',
        );
        await _createSyncIdIndexes();
      }
      if (from < 6) {
        // Synchronisation CRDT : doc du coffre + état d'horloge HLC (ligne unique).
        await migrator.createTable(crdtDocs);
      }
      if (from < 7) {
        // File de deltas en attente de push + curseur de tirage.
        await migrator.createTable(pendingDeltas);
        await migrator.addColumn(crdtDocs, crdtDocs.cursor);
      }
    },
  );

  /// Index unique sur `syncId` de chaque table. Créé à la main (et non via une
  /// contrainte `UNIQUE` de colonne) car SQLite refuse d'ajouter une colonne
  /// UNIQUE par `ALTER TABLE` ; l'index couvre aussi les recherches par `syncId`
  /// de la projection.
  Future<void> _createSyncIdIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_sync_id '
      'ON profiles (sync_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_credentials_sync_id '
      'ON credentials (sync_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_totps_sync_id '
      'ON totps (sync_id)',
    );
  }
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
