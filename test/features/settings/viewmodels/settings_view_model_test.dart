import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/security/biometric_storage_service.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';
import 'package:realm_guard_mobile/features/settings/service/app_reset_service.dart';
import 'package:realm_guard_mobile/features/settings/viewmodels/settings_view_model.dart';

class FakeBiometricStorageService extends BiometricStorageService {
  FakeBiometricStorageService({this.available = true, this.enabled = false});

  bool available;
  bool enabled;
  bool clearCalled = false;
  bool? lastSetValue;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> isBiometricEnabled() async => enabled;

  @override
  Future<void> setBiometricEnabled(bool value) async {
    lastSetValue = value;
    enabled = value;
  }

  @override
  Future<void> clearDerivedKey() async {
    clearCalled = true;
  }
}

class FakeVaultService extends VaultService {
  int lockCount = 0;
  int closeCount = 0;

  @override
  void lockVault() => lockCount++;

  @override
  Future<void> closeVault() async => closeCount++;
}

class FakeAppResetService extends AppResetService {
  bool wiped = false;

  @override
  Future<void> wipeAllData() async {
    wiped = true;
  }
}

SettingsViewModel _build({
  FakeBiometricStorageService? bio,
  FakeVaultService? vault,
  FakeAppResetService? reset,
}) {
  return SettingsViewModel(
    biometricService: bio ?? FakeBiometricStorageService(),
    vaultService: vault ?? FakeVaultService(),
    resetService: reset ?? FakeAppResetService(),
  );
}

void main() {
  group('SettingsViewModel', () {
    test('initialize charge l\'état biométrique', () async {
      final vm = _build(
        bio: FakeBiometricStorageService(available: true, enabled: true),
      );

      await vm.initialize();

      expect(vm.isLoading, isFalse);
      expect(vm.biometricAvailable, isTrue);
      expect(vm.biometricEnabled, isTrue);
    });

    test('biométrie indisponible force enabled=false', () async {
      final vm = _build(
        bio: FakeBiometricStorageService(available: false, enabled: true),
      );

      await vm.initialize();

      expect(vm.biometricAvailable, isFalse);
      expect(vm.biometricEnabled, isFalse);
    });

    test('désactiver la biométrie efface la clé stockée', () async {
      final bio = FakeBiometricStorageService(available: true, enabled: true);
      final vm = _build(bio: bio);
      await vm.initialize();

      await vm.setBiometricEnabled(false);

      expect(vm.biometricEnabled, isFalse);
      expect(bio.lastSetValue, isFalse);
      expect(bio.clearCalled, isTrue);
    });

    test('activer la biométrie n\'efface pas la clé', () async {
      final bio = FakeBiometricStorageService(available: true, enabled: false);
      final vm = _build(bio: bio);
      await vm.initialize();

      await vm.setBiometricEnabled(true);

      expect(vm.biometricEnabled, isTrue);
      expect(bio.lastSetValue, isTrue);
      expect(bio.clearCalled, isFalse);
    });

    test('lockNow verrouille le coffre', () async {
      final vault = FakeVaultService();
      final vm = _build(vault: vault);

      vm.lockNow();

      expect(vault.lockCount, 1);
    });

    test('deleteAllData ferme le coffre (awaited) puis efface tout', () async {
      final vault = FakeVaultService();
      final reset = FakeAppResetService();
      final vm = _build(vault: vault, reset: reset);

      await vm.deleteAllData();

      expect(vault.closeCount, 1);
      expect(reset.wiped, isTrue);
      expect(vm.isBusy, isFalse);
    });
  });
}
