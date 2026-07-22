import 'package:flutter/material.dart';

import '../../../core/feature_flags/feature_flags_controller.dart';
import '../../../core/security/vault_service.dart';
import '../../auth/service/auth_service.dart';
import '../data/onboarding_step.dart';
import '../service/onboarding_flow_controller.dart';
import '../service/onboarding_storage_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  late final OnboardingFlowController _flowController;

  OnboardingViewModel({
    required OnboardingStorageService onboardingStorageService,
    required VaultService vaultService,
    required FeatureFlagsController featureFlagsController,
    required AuthService authService,
  }) {
    _flowController = OnboardingFlowController(
      onboardingStorageService: onboardingStorageService,
      vaultService: vaultService,
      featureFlagsController: featureFlagsController,
      authService: authService,
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

  Future<void> completeTotpChoiceStep(bool enabled) {
    return _flowController.completeTotpChoiceStep(enabled);
  }

  Future<bool> registerSyncAccount({
    required String username,
    required String password,
  }) {
    return _flowController.registerSyncAccount(
      username: username,
      password: password,
    );
  }

  Future<void> completeSyncStep() => _flowController.completeSyncStep();

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
