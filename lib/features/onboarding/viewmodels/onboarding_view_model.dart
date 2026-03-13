import 'package:flutter/material.dart';

import '../service/onboarding_flow_controller.dart';
import '../data/onboarding_step.dart';
import '../service/onboarding_storage_service.dart';
import '../../../../core/security/vault_service.dart';

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

  @override
  void dispose() {
    _flowController.removeListener(_forwardFlowControllerUpdates);
    _flowController.dispose();
    super.dispose();
  }
}
