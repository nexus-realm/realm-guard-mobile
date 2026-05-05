import 'package:flutter/material.dart';

import '../../../core/security/biometric_storage_service.dart';
import '../data/onboarding_step.dart';
import '../service/onboarding_storage_service.dart';

enum StartupRouteTarget { onboarding, unlock, home }

class StartupGateViewModel extends ChangeNotifier {
  final OnboardingStorageService _onboardingStorageService;
  final BiometricStorageService _biometricStorageService;

  bool _isLoading = true;
  StartupRouteTarget? _targetRoute;

  StartupGateViewModel({
    required OnboardingStorageService onboardingStorageService,
    BiometricStorageService? biometricStorageService,
  }) : _onboardingStorageService = onboardingStorageService,
       _biometricStorageService =
           biometricStorageService ?? BiometricStorageService();

  bool get isLoading => _isLoading;

  StartupRouteTarget? get targetRoute => _targetRoute;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final progress = await _onboardingStorageService.loadProgress();
    final isBiometricAvailable = await _biometricStorageService
        .isBiometricAvailable();

    final activeSteps = isBiometricAvailable
        ? OnboardingStep.values
        : OnboardingStep.values
              .where((step) => step != OnboardingStep.biometricChoice)
              .toList(growable: false);

    _targetRoute = progress.isCompletedFor(activeSteps)
        ? StartupRouteTarget.unlock
        : StartupRouteTarget.onboarding;

    _isLoading = false;
    notifyListeners();
  }
}
