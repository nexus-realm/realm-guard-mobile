import 'package:cryptography/cryptography.dart';

import '../database/app_database.dart';
import 'biometric_storage_service.dart';
import 'key_derivator.dart';
import 'salt_manager.dart';

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
      throw Exception(
        "Mot de passe incorrect ou base de données corrompue : $e",
      );
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

  /// Ouverture rapide via biométrie
  Future<bool> unlockWithBiometrics() async {
    try {
      final keyBytes = await _biometricService.getDerivedKeyWithBiometrics(
        "Déverrouillez Realm Guard",
      );

      if (keyBytes == null) return false;

      await openDatabaseWithKey(keyBytes);

      return true;
    } catch (e) {
      return false; // Demande le mot de passe à l'utilisateur
    }
  }

  Future<void> openDatabaseWithKey(List<int> keyBytes) async {
    try {
      _database = AppDatabase(keyBytes);
      await _database!.customSelect('SELECT 1').get();
    } catch (e) {
      _database?.close();
      _database = null;
      throw Exception(
        "Clé de déchiffrement incorrecte ou base de données corrompue : $e",
      );
    }
  }

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
