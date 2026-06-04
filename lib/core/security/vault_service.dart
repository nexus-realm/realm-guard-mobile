import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../database/app_database.dart';
import '../exceptions/vault_unlock_exception.dart';
import 'biometric_storage_service.dart';
import 'key_derivator.dart';
import 'salt_manager.dart';

/// Issue d'un changement de mot de passe maître.
enum ChangePasswordResult {
  /// Mot de passe changé, base re-chiffrée.
  success,

  /// Coffre verrouillé : impossible de changer le mot de passe.
  vaultLocked,

  /// L'ancien mot de passe fourni est incorrect.
  wrongCurrentPassword,

  /// Échec technique du re-chiffrement (la base reste sous l'ancienne clé).
  failure,
}

class VaultService {
  AppDatabase? _database;
  final BiometricStorageService _biometricService = BiometricStorageService();

  /// Ouverture initiale ou manuelle avec le mot de passe maître
  Future<void> unlockWithMasterPassword(String masterPassword) async {
    try {
      final salt = await SaltManager.getOrGenerateSalt();
      final SecretKey secretKey = await KeyDerivator.deriveKeyFromPassword(
        masterPassword,
        salt,
      );
      final List<int> keyBytes = await secretKey.extractBytes();

      await openDatabaseWithKey(keyBytes);

      // Sauvegarde la clé pour la biométrie uniquement si l'utilisateur l'a
      // activée. Best-effort : un échec ici ne doit jamais bloquer un
      // déverrouillage valide.
      await _persistKeyForBiometricsIfEnabled(keyBytes);
    } catch (e) {
      if (e is VaultUnlockException) rethrow;
      throw VaultUnlockException(e);
    }
  }

  /// Stocke (ou efface) la clé de déverrouillage rapide selon la préférence de
  /// l'utilisateur. Non critique : toute erreur est ignorée pour ne pas
  /// compromettre un déverrouillage par ailleurs réussi.
  Future<void> _persistKeyForBiometricsIfEnabled(List<int> keyBytes) async {
    try {
      if (await _biometricService.isBiometricEnabled()) {
        await _biometricService.saveDerivedKey(keyBytes);
      } else {
        await _biometricService.clearDerivedKey();
      }
    } catch (_) {
      // Persistance biométrique non critique : on ignore les échecs.
    }
  }

  /// Ouverture rapide via biométrie. Retourne l'issue précise pour que
  /// l'appelant distingue un échec réel d'une annulation / indisponibilité.
  Future<BiometricUnlockStatus> unlockWithBiometrics() async {
    final (status, keyBytes) = await _biometricService
        .getDerivedKeyWithBiometrics("Déverrouillez Realm Guard");

    if (status != BiometricUnlockStatus.success || keyBytes == null) {
      return status;
    }

    try {
      await openDatabaseWithKey(keyBytes);
      return BiometricUnlockStatus.success;
    } catch (_) {
      return BiometricUnlockStatus.failed; // Demande le mot de passe
    }
  }

  Future<void> openDatabaseWithKey(List<int> keyBytes) async {
    try {
      _database = AppDatabase(keyBytes);
      await _database!.customSelect('SELECT 1').get();
    } catch (e) {
      _database?.close();
      _database = null;
      throw VaultUnlockException(e);
    }
  }

  /// Change le mot de passe maître : re-chiffre la base via `PRAGMA rekey`
  /// (toutes les données sont conservées) puis re-protège la clé biométrique.
  ///
  /// Le coffre doit être déverrouillé. L'[currentPassword] est vérifié avant
  /// tout re-chiffrement. En cas d'échec du rekey, la base reste lisible avec
  /// l'ancien mot de passe (opération SQLCipher atomique).
  Future<ChangePasswordResult> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = _database;
    if (db == null) return ChangePasswordResult.vaultLocked;

    try {
      final salt = await SaltManager.getOrGenerateSalt();

      // 1. Vérifier l'ancien mot de passe : la clé dérivée doit ouvrir la base.
      final currentKey = await _deriveKeyBytes(currentPassword, salt);
      final isCurrentValid = await _keyOpensDatabase(currentKey);
      if (!isCurrentValid) {
        return ChangePasswordResult.wrongCurrentPassword;
      }

      // 2. Dériver la nouvelle clé (même sel : non secret, pas besoin de
      //    rotation) et re-chiffrer la base en place.
      final newKey = await _deriveKeyBytes(newPassword, salt);
      await db.customStatement('PRAGMA rekey = "x\'${_toHex(newKey)}\'";');

      // 3. Re-protéger la clé de déverrouillage biométrique (best-effort).
      await _persistKeyForBiometricsIfEnabled(newKey);

      return ChangePasswordResult.success;
    } catch (_) {
      return ChangePasswordResult.failure;
    }
  }

  Future<List<int>> _deriveKeyBytes(String password, Uint8List salt) async {
    final secretKey = await KeyDerivator.deriveKeyFromPassword(password, salt);
    return secretKey.extractBytes();
  }

  /// Vérifie qu'une clé donnée ouvre bien la base, via une connexion temporaire
  /// (ne perturbe pas la session principale ouverte).
  Future<bool> _keyOpensDatabase(List<int> keyBytes) async {
    final probe = AppDatabase(keyBytes);
    try {
      await probe.customSelect('SELECT 1').get();
      return true;
    } catch (_) {
      return false;
    } finally {
      await probe.close();
    }
  }

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Verrouille activement le coffre
  void lockVault() {
    _database?.close();
    _database = null;
  }

  /// Indique si le coffre est actuellement déverrouillé (DB ouverte en mémoire).
  bool get isUnlocked => _database != null;

  AppDatabase get db {
    if (_database == null) throw Exception("Vault is locked!");
    return _database!;
  }
}
