import 'package:flutter/foundation.dart';

import '../../../core/security/biometric_storage_service.dart';
import '../../../core/security/vault_service.dart';
import '../service/app_reset_service.dart';

/// ViewModel de la page Paramètres : état biométrie + actions de sécurité
/// (verrouillage immédiat, suppression de toutes les données).
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required BiometricStorageService biometricService,
    required VaultService vaultService,
    required AppResetService resetService,
  }) : _biometricService = biometricService,
       _vaultService = vaultService,
       _resetService = resetService;

  final BiometricStorageService _biometricService;
  final VaultService _vaultService;
  final AppResetService _resetService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  Future<void> initialize() async {
    _biometricAvailable = await _biometricService.isBiometricAvailable();
    _biometricEnabled =
        _biometricAvailable && await _biometricService.isBiometricEnabled();
    _isLoading = false;
    notifyListeners();
  }

  /// Active/désactive la biométrie. À l'activation, la clé ne sera mise en
  /// cache qu'au prochain déverrouillage par mot de passe (cf. modèle Keystore) ;
  /// à la désactivation, la clé chiffrée stockée est immédiatement effacée.
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    notifyListeners();

    await _biometricService.setBiometricEnabled(enabled);
    if (!enabled) {
      await _biometricService.clearDerivedKey();
    }
  }

  /// Verrouille immédiatement le coffre (ferme la base chiffrée en mémoire).
  void lockNow() {
    _vaultService.lockVault();
  }

  /// Ferme le coffre puis efface toutes les données locales. Irréversible.
  Future<void> deleteAllData() async {
    _isBusy = true;
    notifyListeners();
    try {
      // Fermeture **attendue** de la base avant d'effacer ses fichiers : évite
      // toute course avec la fermeture asynchrone de SQLCipher (fragments
      // chiffrés résiduels).
      await _vaultService.closeVault();
      await _resetService.wipeAllData();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
