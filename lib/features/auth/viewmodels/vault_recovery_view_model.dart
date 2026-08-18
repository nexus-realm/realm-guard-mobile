import 'package:flutter/foundation.dart';

import '../../../core/security/vault_service.dart';
import '../../onboarding/data/onboarding_step.dart';
import '../../onboarding/service/onboarding_storage_service.dart';
import '../data/auth_exception.dart';
import '../data/stored_vault_key.dart';
import '../service/auth_service.dart';

/// Signature de la récupération de coffre (injectée : [VaultService.recoverVaultFromBackup]).
typedef RecoverVault =
    Future<RecoverVaultResult> Function({
      required Uint8List wrappedVaultKey,
      required Uint8List backupSalt,
      required String masterPassword,
    });

/// Récupération du coffre **depuis le backup serveur**, sans autre appareil.
///
/// Deux phases, et **deux mots de passe** — c'est le modèle de sécurité, pas une
/// lourdeur : le compte (OPAQUE) donne la clé exportée qui ouvre l'enveloppe
/// serveur, le mot de passe maître désenrobe la VaultKey. Une fuite de la base
/// serveur seule, ou le seul mot de passe de compte, ne suffisent pas.
class VaultRecoveryViewModel extends ChangeNotifier {
  VaultRecoveryViewModel({
    required AuthService authService,
    required RecoverVault recover,
    required OnboardingStorageService onboardingStorage,
  }) : _authService = authService,
       _recover = recover,
       _onboardingStorage = onboardingStorage;

  final AuthService _authService;
  final RecoverVault _recover;
  final OnboardingStorageService _onboardingStorage;

  StoredVaultKey? _backup;
  bool _submitting = false;
  bool _installed = false;
  String? _error;

  /// Sauvegarde récupérée : la phase « mot de passe maître » peut commencer.
  bool get backupFetched => _backup != null;

  bool get submitting => _submitting;

  /// Coffre restauré : l'onboarding peut reprendre.
  bool get installed => _installed;

  String? get error => _error;

  /// **Phase 1** — se connecte au compte et récupère la clé de coffre sauvegardée.
  Future<bool> fetchBackup({
    required String username,
    required String password,
  }) async {
    if (_submitting) return false;
    final handle = username.trim();
    if (handle.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir les deux champs.';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final exportKey = await _authService.login(handle, password);
      final backup = await _authService.fetchVaultKey(exportKey);
      if (backup == null) {
        _error =
            "Aucune sauvegarde de coffre sur ce compte. Utilisez « lier cet "
            'appareil » depuis un appareil déjà configuré.';
        return false;
      }
      _backup = backup;
      return true;
    } on AuthException catch (error) {
      _error = error.message;
      return false;
    } catch (error, stack) {
      _logFailure('récupération', error, stack);
      _error = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// **Phase 2** — désenrobe la clé avec le mot de passe maître et installe le coffre.
  Future<bool> restore(String masterPassword) async {
    final backup = _backup;
    if (backup == null || _submitting) return false;
    if (masterPassword.isEmpty) {
      _error = 'Veuillez saisir votre mot de passe maître.';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _recover(
        wrappedVaultKey: backup.wrappedVaultKey,
        backupSalt: backup.salt,
        masterPassword: masterPassword,
      );
      switch (result) {
        case RecoverVaultResult.success:
          await _markOnboardingSteps();
          _installed = true;
          return true;
        case RecoverVaultResult.wrongMasterPassword:
          _error = 'Mot de passe maître incorrect.';
          return false;
        case RecoverVaultResult.vaultAlreadyExists:
          _error = 'Un coffre existe déjà sur cet appareil.';
          return false;
        case RecoverVaultResult.failure:
          _error = "Impossible d'installer le coffre. Réessayez.";
          return false;
      }
    } catch (error, stack) {
      _logFailure('installation', error, stack);
      _error = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// La récupération satisfait « accueil », « synchronisation » et « mot de passe
  /// maître » (celui-ci vient d'être re-saisi et protège le coffre installé).
  Future<void> _markOnboardingSteps() async {
    var progress = await _onboardingStorage.loadProgress();
    progress = progress.markStepCompleted(OnboardingStep.welcome);
    progress = progress.markStepCompleted(OnboardingStep.syncChoice);
    progress = progress.markStepCompleted(OnboardingStep.masterPassword);
    await _onboardingStorage.saveProgress(progress);
  }

  void _logFailure(String stage, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[recovery] échec ($stage) : $error\n$stack');
    }
  }
}
