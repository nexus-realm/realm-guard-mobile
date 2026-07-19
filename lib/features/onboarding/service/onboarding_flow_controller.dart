import 'package:flutter/material.dart';

import '../../../core/feature_flags/feature_flag.dart';
import '../../../core/feature_flags/feature_flags_controller.dart';
import '../../../core/security/biometric_storage_service.dart';
import '../../../core/security/vault_service.dart';
import '../../auth/data/account_credential_rules.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/service/auth_service.dart';
import 'onboarding_progress.dart';
import '../data/onboarding_step.dart';
import 'onboarding_storage_service.dart';

class OnboardingFlowController extends ChangeNotifier {
  final OnboardingStorageService _onboardingStorageService;
  final VaultService _vaultService;
  final BiometricStorageService _biometricStorageService;
  // Le contrôleur partagé (singleton) doit être injecté pour que le choix fait
  // ici se reflète immédiatement sur l'accueil après l'onboarding.
  final FeatureFlagsController _featureFlagsController;
  // Authentification de synchronisation (OPAQUE) — utilisée par l'étape optionnelle
  // de création de compte.
  final AuthService _authService;

  OnboardingProgress _progress = OnboardingProgress.initial();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isBiometricStepAvailable = true;

  OnboardingFlowController({
    required OnboardingStorageService onboardingStorageService,
    required VaultService vaultService,
    required FeatureFlagsController featureFlagsController,
    required AuthService authService,
    BiometricStorageService? biometricStorageService,
  }) : _onboardingStorageService = onboardingStorageService,
       _vaultService = vaultService,
       _featureFlagsController = featureFlagsController,
       _authService = authService,
       _biometricStorageService =
           biometricStorageService ?? BiometricStorageService();

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCompleted => _progress.isCompletedFor(_effectiveSteps);
  OnboardingProgress get progress => _progress;
  OnboardingStep? get currentStep =>
      _progress.nextMissingStepFor(_effectiveSteps);
  String? get errorMessage => _errorMessage;
  int get totalStepCount => _effectiveSteps.length;

  int get currentStepIndex {
    final step = currentStep;
    if (step == null) {
      return totalStepCount;
    }
    return _effectiveSteps.indexOf(step) + 1;
  }

  List<OnboardingStep> get _effectiveSteps {
    if (_isBiometricStepAvailable) {
      return OnboardingStep.values;
    }

    return OnboardingStep.values
        .where((step) => step != OnboardingStep.biometricChoice)
        .toList(growable: false);
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _progress = await _onboardingStorageService.loadProgress();
    _isBiometricStepAvailable = await _biometricStorageService
        .isBiometricAvailable();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeWelcomeStep() async {
    await _markStepCompleted(OnboardingStep.welcome);
  }

  Future<bool> completeMasterPasswordStep(
    String password,
    String confirmation,
  ) async {
    final normalizedPassword = password.trim();
    final normalizedConfirmation = confirmation.trim();

    if (normalizedPassword.isEmpty || normalizedConfirmation.isEmpty) {
      _errorMessage = 'Veuillez remplir les deux champs du mot de passe.';
      notifyListeners();
      return false;
    }

    if (normalizedPassword.length < 12) {
      _errorMessage =
          'Le mot de passe maître doit contenir au moins 12 caractères.';
      notifyListeners();
      return false;
    }

    if (normalizedPassword != normalizedConfirmation) {
      _errorMessage = 'Les mots de passe saisis ne correspondent pas.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _vaultService.unlockWithMasterPassword(normalizedPassword);
      _vaultService.lockVault();
      await _markStepCompleted(OnboardingStep.masterPassword);
      return true;
    } catch (_) {
      _errorMessage =
          'Impossible de configurer le mot de passe maître. Réessayez.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> completeBiometricStep(bool enabled) async {
    if (!_isBiometricStepAvailable) {
      return;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _biometricStorageService.setBiometricEnabled(enabled);
      if (!enabled) {
        await _biometricStorageService.clearDerivedKey();
      }
      await _markStepCompleted(
        OnboardingStep.biometricChoice,
        biometricEnabled: enabled,
      );
    } catch (_) {
      _errorMessage =
          'Impossible d\'enregistrer votre choix biométrique pour le moment.';
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Enregistre le choix d'activation de la gestion des TOTP et termine
  /// l'étape. Aucune donnée TOTP existante n'est supprimée (désactivation =
  /// masquage de l'interface uniquement).
  Future<void> completeTotpChoiceStep(bool enabled) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _featureFlagsController.setEnabled(FeatureFlag.totp, enabled);
      await _markStepCompleted(OnboardingStep.totpChoice);
    } catch (_) {
      _errorMessage =
          'Impossible d\'enregistrer votre choix pour le moment. Réessayez.';
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Crée un **compte de synchronisation** (OPAQUE) et ouvre la session. Le mot de
  /// passe du compte est **distinct** du mot de passe maître : le serveur ne le voit
  /// jamais (zero-knowledge). Renvoie `true` si le compte est créé et la session
  /// établie. Ne termine **pas** l'étape (l'appelant affiche d'abord la confirmation
  /// de réussite, puis appelle [completeSyncStep]).
  Future<bool> registerSyncAccount({
    required String username,
    required String password,
  }) async {
    final handle = username.trim();
    final usernameError = AccountCredentialRules.validateUsername(handle);
    if (usernameError != null) {
      _errorMessage = usernameError;
      notifyListeners();
      return false;
    }
    final passwordError = AccountCredentialRules.validatePassword(password);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(handle, password);
      await _authService.login(handle, password);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Termine l'étape de synchronisation (choix hors-ligne **ou** compte créé).
  Future<void> completeSyncStep() async {
    await _markStepCompleted(OnboardingStep.syncChoice);
  }

  Future<void> _markStepCompleted(
    OnboardingStep step, {
    bool? biometricEnabled,
  }) async {
    _progress = _progress.markStepCompleted(
      step,
      biometricEnabled: biometricEnabled,
    );
    await _onboardingStorageService.saveProgress(_progress);
    _errorMessage = null;
    notifyListeners();
  }
}
