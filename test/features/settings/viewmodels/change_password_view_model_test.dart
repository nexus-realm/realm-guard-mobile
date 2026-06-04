import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/security/vault_service.dart';
import 'package:realm_guard_mobile/features/settings/viewmodels/change_password_view_model.dart';

class FakeVaultService extends VaultService {
  ChangePasswordResult result = ChangePasswordResult.success;
  String? receivedCurrent;
  String? receivedNew;
  int callCount = 0;

  @override
  Future<ChangePasswordResult> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    callCount++;
    receivedCurrent = currentPassword;
    receivedNew = newPassword;
    return result;
  }
}

const _validNew = 'NouveauP@ss12';

void main() {
  group('ChangePasswordViewModel - validation', () {
    test('refuse un champ vide sans appeler le service', () async {
      final vault = FakeVaultService();
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: '',
        newPassword: _validNew,
        confirmation: _validNew,
      );

      expect(ok, isFalse);
      expect(vault.callCount, 0);
      expect(vm.errorMessage, isNotNull);
    });

    test('refuse un nouveau mot de passe faible', () async {
      final vault = FakeVaultService();
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: 'Ancien@Pass12',
        newPassword: 'faible',
        confirmation: 'faible',
      );

      expect(ok, isFalse);
      expect(vault.callCount, 0);
    });

    test('refuse si confirmation différente', () async {
      final vault = FakeVaultService();
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: 'Ancien@Pass12',
        newPassword: _validNew,
        confirmation: 'Autre@Pass123',
      );

      expect(ok, isFalse);
      expect(vault.callCount, 0);
    });

    test('refuse si nouveau == ancien', () async {
      final vault = FakeVaultService();
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: _validNew,
        newPassword: _validNew,
        confirmation: _validNew,
      );

      expect(ok, isFalse);
      expect(vault.callCount, 0);
    });
  });

  group('ChangePasswordViewModel - résultats du service', () {
    test('succès : transmet les valeurs et marque success', () async {
      final vault = FakeVaultService()..result = ChangePasswordResult.success;
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: 'Ancien@Pass12',
        newPassword: _validNew,
        confirmation: _validNew,
      );

      expect(ok, isTrue);
      expect(vm.success, isTrue);
      expect(vault.receivedCurrent, 'Ancien@Pass12');
      expect(vault.receivedNew, _validNew);
    });

    test('mot de passe actuel incorrect : échec avec message', () async {
      final vault = FakeVaultService()
        ..result = ChangePasswordResult.wrongCurrentPassword;
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: 'Ancien@Pass12',
        newPassword: _validNew,
        confirmation: _validNew,
      );

      expect(ok, isFalse);
      expect(vm.success, isFalse);
      expect(vm.errorMessage, contains('actuel'));
    });

    test('échec technique : message rassurant sur l\'intégrité', () async {
      final vault = FakeVaultService()..result = ChangePasswordResult.failure;
      final vm = ChangePasswordViewModel(vaultService: vault);

      final ok = await vm.submit(
        currentPassword: 'Ancien@Pass12',
        newPassword: _validNew,
        confirmation: _validNew,
      );

      expect(ok, isFalse);
      expect(vm.errorMessage, contains('intactes'));
    });
  });
}
