import 'package:cryptography/cryptography.dart';

import '../database/app_database.dart';
import 'key_derivator.dart';
import 'salt_manager.dart';

class VaultService {
  AppDatabase? _database;

  Future<void> unlockVault(String masterPassword) async {
    try {
      final salt = await SaltManager.getOrGenerateSalt();

      final SecretKey secretKey = await KeyDerivator.deriveKeyFromPassword(
        masterPassword,
        salt,
      );

      final List<int> keyBytes = await secretKey.extractBytes();

      _database = AppDatabase(keyBytes);

      await _database!.customSelect('SELECT 1').get();

      print("Coffre-fort déverrouillé avec succès !");

    } catch (e) {
      _database?.close();
      _database = null;
      throw Exception("Mot de passe incorrect ou base de données corrompue : $e");
    }
  }

  AppDatabase get db {
    if (_database == null) throw Exception("Vault is locked!");
    return _database!;
  }
}