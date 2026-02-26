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

      _database = AppDatabase(keyBytes);
      await _database!.customSelect('SELECT 1').get();

      // Sauvegarde la clé pour la prochaine ouverture biométrique
      await _biometricService.saveDerivedKey(keyBytes);
    } catch (e) {
      _database?.close();
      _database = null;
      throw Exception("Mot de passe incorrect ou base de données corrompue : $e");
    }
  }

  /// Ouverture rapide via biométrie
  Future<bool> unlockWithBiometrics() async {
    try {
      final keyBytes = await _biometricService.getDerivedKeyWithBiometrics(
        "Déverrouillez Realm Guard",
      );

      if (keyBytes == null) return false;

      _database = AppDatabase(keyBytes);
      await _database!.customSelect('SELECT 1').get();
      return true;
    } catch (e) {
      _database?.close();
      _database = null;
      return false; // Forcera l'utilisateur à entrer le mot de passe
    }
  }

  /// Verrouille activement le coffre
  void lockVault() {
    _database?.close();
    _database = null;
  }

  AppDatabase get db {
    if (_database == null) throw Exception("Vault is locked!");
    return _database!;
  }
}