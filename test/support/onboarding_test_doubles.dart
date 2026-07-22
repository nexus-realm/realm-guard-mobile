import 'package:realmguard/core/security/biometric_storage_service.dart';
import 'package:realmguard/core/security/vault_service.dart';
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart';
import 'package:realmguard/features/onboarding/service/onboarding_storage_service.dart';

/// Progression d'onboarding en mémoire (aucun accès au stockage sécurisé).
class InMemoryOnboardingStorageService extends OnboardingStorageService {
  OnboardingProgress _progress = OnboardingProgress.initial();

  @override
  Future<OnboardingProgress> loadProgress() async => _progress;

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    _progress = progress;
  }

  @override
  Future<void> clearProgress() async {
    _progress = OnboardingProgress.initial();
  }
}

/// Coffre neutralisé : l'onboarding le sollicite pour créer/déverrouiller, on
/// ne veut ni Argon2id ni SQLCipher dans un test de vue.
class FakeVaultService extends VaultService {
  @override
  Future<void> unlockWithMasterPassword(String masterPassword) async {}
}

/// Biométrie neutralisée : sans ça, `initialize()` interroge `local_auth` et
/// reste en suspens hors appareil (le canal plateforme ne répond jamais).
class FakeBiometricStorageService extends BiometricStorageService {
  FakeBiometricStorageService({this.available = false});

  final bool available;

  @override
  Future<bool> isBiometricAvailable() async => available;
}
