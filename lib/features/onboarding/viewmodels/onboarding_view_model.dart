import 'package:flutter/material.dart';

import '../../../core/security/vault_service.dart';
import '../data/onboarding_step.dart';
import '../data/password_validation_rule.dart';
import '../service/onboarding_flow_controller.dart';
import '../service/onboarding_storage_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  late final OnboardingFlowController _flowController;

  OnboardingViewModel({
    required OnboardingStorageService onboardingStorageService,
    required VaultService vaultService,
  }) {
    _flowController = OnboardingFlowController(
      onboardingStorageService: onboardingStorageService,
      vaultService: vaultService,
    );
    _flowController.addListener(_forwardFlowControllerUpdates);
  }

  bool get isLoading => _flowController.isLoading;
  bool get isSubmitting => _flowController.isSubmitting;
  bool get isCompleted => _flowController.isCompleted;
  OnboardingStep? get currentStep => _flowController.currentStep;
  String? get errorMessage => _flowController.errorMessage;
  int get currentStepIndex => _flowController.currentStepIndex;
  int get totalStepCount => _flowController.totalStepCount;

  Future<void> initialize() => _flowController.initialize();

  Future<void> completeWelcomeStep() => _flowController.completeWelcomeStep();

  Future<bool> completeMasterPasswordStep(
    String password,
    String confirmation,
  ) {
    return _flowController.completeMasterPasswordStep(password, confirmation);
  }

  Future<void> completeBiometricStep(bool enabled) {
    return _flowController.completeBiometricStep(enabled);
  }

  void _forwardFlowControllerUpdates() {
    notifyListeners();
  }

  List<PasswordValidationRule> getPasswordValidationRules(String password) {
    return [
      PasswordValidationRule(
        label: 'Au moins 12 caractères',
        validate: (pwd) => pwd.length >= 12,
      ),
      PasswordValidationRule(
        label: 'Contient au moins une lettre majuscule',
        validate: (pwd) => pwd.contains(RegExp(r'[A-Z]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins une lettre minuscule',
        validate: (pwd) => pwd.contains(RegExp(r'[a-z]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins un chiffre',
        validate: (pwd) => pwd.contains(RegExp(r'[0-9]')),
      ),
      PasswordValidationRule(
        label: 'Contient au moins un caractère spécial',
        validate: (pwd) => pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }

  @override
  void dispose() {
    _flowController.removeListener(_forwardFlowControllerUpdates);
    _flowController.dispose();
    super.dispose();
  }
}
