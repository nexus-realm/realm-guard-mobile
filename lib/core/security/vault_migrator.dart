import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import 'vault_key_crypto.dart';
import 'wrapped_vault_key_store.dart';

/// Opérations SQLCipher nécessaires à la migration (seam testable).
abstract interface class MigrationDb {
  /// Replie le WAL dans le fichier principal (`PRAGMA wal_checkpoint(TRUNCATE)`).
  Future<void> checkpoint();

  /// Re-chiffre la base sous `newKey` (`PRAGMA rekey`).
  Future<void> rekey(List<int> newKey);

  /// Vérifie que la base est lisible (`SELECT 1`).
  Future<void> validate();
}

/// Gestion du fichier de sauvegarde du coffre (seam testable).
abstract interface class VaultBackupFiles {
  Future<bool> backupExists();
  Future<void> backup();
  Future<void> restoreBackup();
  Future<void> deleteBackup();
}

/// Migration du coffre **v1** (clé du coffre = mot de passe dérivé) vers le
/// **modèle VaultKey** (la KEK enrobe une VaultKey aléatoire = clé du coffre), et
/// récupération d'une migration interrompue.
///
/// Conçue pour ne **jamais** laisser d'état mixte : un crash retombe toujours en
/// état **A** (pré-migration : DB=KEK, pas de wrapped-VK, pas de `.bak`) ou **B**
/// (migré : DB=VaultKey, wrapped-VK présente, pas de `.bak`).
class VaultMigrator {
  const VaultMigrator(this._crypto, this._store);

  final VaultKeyCrypto _crypto;
  final WrappedVaultKeyStore _store;

  /// À appeler **avant** tout déverrouillage. Si une sauvegarde traîne, une
  /// migration a été interrompue : on finalise (si la wrapped-VK est déjà écrite,
  /// état B) ou on restaure (sinon, retour en A pour retenter).
  Future<void> heal(VaultBackupFiles files) async {
    if (!await files.backupExists()) return;
    if (await _store.read() != null) {
      // wrapped-VK présente ⇒ migration terminée, seul le nettoyage a manqué.
      await files.deleteBackup();
    } else {
      // wrapped-VK absente ⇒ migration interrompue ⇒ retour à l'état A.
      await files.restoreBackup();
    }
  }

  /// Migre le coffre (déjà **ouvert avec la KEK**) vers le modèle VaultKey. Renvoie
  /// les octets de la VaultKey (nouvelle clé du coffre).
  ///
  /// L'ordre garantit l'invariant A/B : la wrapped-VK n'est écrite qu'après un
  /// rekey **vérifié**, et la sauvegarde n'est supprimée qu'en tout dernier.
  Future<List<int>> migrate(
    List<int> kek,
    MigrationDb db,
    VaultBackupFiles files,
  ) async {
    await db.checkpoint();
    await files.backup();
    final vaultKey = _crypto.generate();
    await db.rekey(vaultKey);
    await db.validate();
    await _store.write(_crypto.wrap(kek, vaultKey));
    await files.deleteBackup();
    return vaultKey;
  }
}

/// Implémentation réelle des opérations SQLCipher sur la connexion ouverte.
class DriftMigrationDb implements MigrationDb {
  const DriftMigrationDb(this._db);

  final AppDatabase _db;

  @override
  Future<void> checkpoint() =>
      _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

  @override
  Future<void> rekey(List<int> newKey) =>
      _db.customStatement('PRAGMA rekey = "x\'${_toHex(newKey)}\'";');

  @override
  Future<void> validate() async {
    await _db.customSelect('SELECT 1').get();
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Implémentation réelle du backup fichier du coffre (dossier support de l'app).
class VaultFiles implements VaultBackupFiles {
  const VaultFiles(this._dbPath);

  /// Nom du fichier de base (aligné sur `AppDatabase` / `AppResetService`).
  static const String dbFileName = 'realm_guard_vault.sqlite';

  final String _dbPath;

  /// Résout le chemin du fichier de base dans le dossier support de l'app.
  static Future<VaultFiles> resolve() async {
    final dir = await getApplicationSupportDirectory();
    return VaultFiles(p.join(dir.path, dbFileName));
  }

  String get _backupPath => '$_dbPath.bak';

  @override
  Future<bool> backupExists() => File(_backupPath).exists();

  @override
  Future<void> backup() async {
    await File(_dbPath).copy(_backupPath);
  }

  @override
  Future<void> restoreBackup() async {
    await File(_backupPath).copy(_dbPath);
    // Purge les résidus d'un rekey partiel (la sauvegarde est cohérente seule).
    for (final suffix in const ['-wal', '-shm']) {
      final residue = File('$_dbPath$suffix');
      if (await residue.exists()) await residue.delete();
    }
    await File(_backupPath).delete();
  }

  @override
  Future<void> deleteBackup() async {
    final backup = File(_backupPath);
    if (await backup.exists()) await backup.delete();
  }
}
