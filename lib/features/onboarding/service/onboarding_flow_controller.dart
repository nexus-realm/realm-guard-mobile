import 'package:flutter/material.dart';

import '../../../core/security/biometric_storage_service.dart';
import '../../../core/security/vault_service.dart';
import 'onboarding_progress.dart';
import '../data/onboarding_step.dart';
import 'onboarding_storage_service.dart';

class OnboardingFlowController extends ChangeNotifier {
  final OnboardingStorageService _onboardingStorageService;
  final VaultService _vaultService;
  final BiometricStorageService _biometricStorageService;

  OnboardingProgress _progress = OnboardingProgress.initial();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  OnboardingFlowController({
    required OnboardingStorageService onboardingStorageService,
    required VaultService vaultService,
    BiometricStorageService? biometricStorageService,
  }) : _onboardingStorageService = onboardingStorageService,
       _vaultService = vaultService,
       _biometricStorageService =
           biometricStorageService ?? BiometricStorageService();

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCompleted => _progress.isCompleted;
  OnboardingProgress get progress => _progress;
  OnboardingStep? get currentStep => _progress.nextMissingStep;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _progress = await _onboardingStorageService.loadProgress();
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

    if (normalizedPassword.length < 8) {
      _errorMessage =
          'Le mot de passe maitre doit contenir au moins 8 caracteres.';
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
          'Impossible de configurer le mot de passe maitre. Reessayez.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> completeBiometricStep(bool enabled) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!enabled) {
        await _biometricStorageService.clearDerivedKey();
      }
      await _markStepCompleted(
        OnboardingStep.biometricChoice,
        biometricEnabled: enabled,
      );
    } catch (_) {
      _errorMessage =
          'Impossible d\'enregistrer votre choix biometrique pour le moment.';
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
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

