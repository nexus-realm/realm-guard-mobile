enum OnboardingStep {
  welcome,
  masterPassword,
  biometricChoice,
  totpChoice;

  String get storageKey {
    switch (this) {
      case OnboardingStep.welcome:
        return 'welcome';
      case OnboardingStep.masterPassword:
        return 'master_password';
      case OnboardingStep.biometricChoice:
        return 'biometric_choice';
      case OnboardingStep.totpChoice:
        return 'totp_choice';
    }
  }

  static OnboardingStep? fromStorageKey(String value) {
    for (final step in OnboardingStep.values) {
      if (step.storageKey == value) {
        return step;
      }
    }
    return null;
  }
}
