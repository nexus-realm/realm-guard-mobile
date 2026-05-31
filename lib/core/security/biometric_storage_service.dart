import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'keystore_key_guard.dart';

/// Issue d'une tentative de déverrouillage biométrique.
enum BiometricUnlockStatus {
  /// Authentifié et clé déchiffrée avec succès.
  success,

  /// Échec réel (déchiffrement impossible après authentification) :
  /// pénalise uniquement le compteur biométrique.
  failed,

  /// L'utilisateur a annulé / abandonné le prompt : n'est pas compté.
  canceled,

  /// Biométrie indisponible, aucune clé stockée, ou clé invalidée :
  /// n'est pas compté.
  unavailable,
}

class BiometricStorageService {
  BiometricStorageService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
    KeystoreKeyGuard? keyGuard,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _auth = localAuth ?? LocalAuthentication(),
       _keyGuard = keyGuard ?? const KeystoreKeyGuard();

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _auth;
  final KeystoreKeyGuard _keyGuard;

  static const String _keyDerivedVaultKey = 'derived_vault_key';
  static const String _keyBiometricEnabled = 'biometric_enabled_v1';

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Indique si l'utilisateur a activé le déverrouillage biométrique rapide.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Enregistre le choix biométrique de l'utilisateur.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Chiffre (wrap) la clé dérivée avec une clé matérielle de l'Android
  /// Keystore liée à l'authentification, puis ne stocke que le chiffré.
  /// La clé en clair ne touche jamais le stockage persistant.
  Future<void> saveDerivedKey(List<int> keyBytes) async {
    final wrapped = await _keyGuard.wrap(keyBytes);
    await _secureStorage.write(
      key: _keyDerivedVaultKey,
      value: base64Encode(wrapped),
    );
  }

  /// Supprime la clé chiffrée stockée et la clé Keystore sous-jacente.
  Future<void> clearDerivedKey() async {
    await _secureStorage.delete(key: _keyDerivedVaultKey);
    await _keyGuard.deleteKey();
  }

  /// Authentifie l'utilisateur puis déchiffre (unwrap) la clé dérivée via le
  /// Keystore.
  ///
  /// Retourne l'issue ([BiometricUnlockStatus]) et, en cas de succès, les octets
  /// de la clé. L'issue distingue l'annulation et l'indisponibilité (à ne pas
  /// pénaliser) d'un échec réel.
  Future<(BiometricUnlockStatus, List<int>?)> getDerivedKeyWithBiometrics(
    String reason,
  ) async {
    final stored = await _secureStorage.read(key: _keyDerivedVaultKey);
    if (stored == null) return (BiometricUnlockStatus.unavailable, null);

    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) {
      return (BiometricUnlockStatus.unavailable, null);
    }

    final Uint8List wrapped;
    try {
      wrapped = base64Decode(stored);
    } catch (_) {
      // Format inconnu/hérité : on le supprime pour qu'un prochain
      // déverrouillage par mot de passe le ré-enregistre au bon format.
      await clearDerivedKey();
      return (BiometricUnlockStatus.unavailable, null);
    }

    final bool authenticated;
    try {
      authenticated = await _auth.authenticate(
        sensitiveTransaction: true,
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // Erreur OS (biométrie indisponible, lockout système, ...) :
      // ne pénalise pas le compteur.
      return (BiometricUnlockStatus.unavailable, null);
    }

    if (!authenticated) {
      // Annulation / abandon par l'utilisateur : n'est pas compté.
      return (BiometricUnlockStatus.canceled, null);
    }

    try {
      final keyBytes = await _keyGuard.unwrap(wrapped);
      return (BiometricUnlockStatus.success, keyBytes);
    } on KeyInvalidatedException {
      // Biométrie ré-enrôlée : on force un déverrouillage par mot de passe.
      await clearDerivedKey();
      return (BiometricUnlockStatus.unavailable, null);
    } on UserNotAuthenticatedException {
      return (BiometricUnlockStatus.failed, null);
    } catch (_) {
      return (BiometricUnlockStatus.failed, null);
    }
  }
}
