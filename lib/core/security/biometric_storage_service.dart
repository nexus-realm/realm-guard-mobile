import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyDerivedVaultKey = 'derived_vault_key';

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Sauvegarde la clé après une connexion réussie par mot de passe
  Future<void> saveDerivedKey(List<int> keyBytes) async {
    await _secureStorage.write(
      key: _keyDerivedVaultKey,
      value: base64Encode(keyBytes),
    );
  }

  /// Supprime la clé (ex: déconnexion manuelle ou révocation)
  Future<void> clearDerivedKey() async {
    await _secureStorage.delete(key: _keyDerivedVaultKey);
  }

  /// Tente de récupérer la clé après validation biométrique
  Future<List<int>?> getDerivedKeyWithBiometrics(String reason) async {
    final bool hasKey = await _secureStorage.containsKey(
      key: _keyDerivedVaultKey,
    );
    if (!hasKey) return null;

    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) {
      return null;
    }

    try {
      final bool authenticated = await _auth.authenticate(
        sensitiveTransaction: true,
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        final base64Key = await _secureStorage.read(key: _keyDerivedVaultKey);
        if (base64Key != null) {
          return base64Decode(base64Key);
        }
      }
    } catch (e) {
      // Gérer l'erreur (ex: trop de tentatives biométriques échouées)
      return null;
    }

    return null;
  }
}
