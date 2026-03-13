import 'package:flutter/material.dart';

import '../service/onboarding_storage_service.dart';

enum StartupRouteTarget { onboarding, home }

class StartupGateViewModel extends ChangeNotifier {
  final OnboardingStorageService _onboardingStorageService;

  bool _isLoading = true;
  StartupRouteTarget? _targetRoute;

  StartupGateViewModel({
    required OnboardingStorageService onboardingStorageService,
  }) : _onboardingStorageService = onboardingStorageService;

  bool get isLoading => _isLoading;
  StartupRouteTarget? get targetRoute => _targetRoute;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final progress = await _onboardingStorageService.loadProgress();
    _targetRoute = progress.isCompleted
        ? StartupRouteTarget.home
        : StartupRouteTarget.onboarding;

    _isLoading = false;
    notifyListeners();
  }
}
