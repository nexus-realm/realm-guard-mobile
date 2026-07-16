import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/vault_service.dart';
import 'package:realmguard/features/auth/data/auth_exception.dart';
import 'package:realmguard/features/auth/data/stored_vault_key.dart';
import 'package:realmguard/features/auth/viewmodels/vault_recovery_view_model.dart';
import 'package:realmguard/features/onboarding/data/onboarding_step.dart';
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart';
import 'package:realmguard/features/onboarding/service/onboarding_storage_service.dart';

import '../../../support/auth_test_doubles.dart';

class _FakeOnboardingStorage extends OnboardingStorageService {
  OnboardingProgress progress = OnboardingProgress.initial();

  @override
  Future<OnboardingProgress> loadProgress() async => progress;

  @override
  Future<void> saveProgress(OnboardingProgress value) async => progress = value;
}

void main() {
  final wrapped = Uint8List.fromList([1, 2, 3]);
  final salt = Uint8List.fromList([4, 5, 6]);

  ({
    VaultRecoveryViewModel vm,
    _FakeOnboardingStorage storage,
    List<String> recoveredWith,
  })
  build(
    FakeAuthService auth, {
    RecoverVaultResult result = RecoverVaultResult.success,
  }) {
    final storage = _FakeOnboardingStorage();
    final recoveredWith = <String>[];
    final vm = VaultRecoveryViewModel(
      authService: auth,
      recover:
          ({
            required Uint8List wrappedVaultKey,
            required Uint8List backupSalt,
            required String masterPassword,
          }) async {
            recoveredWith.add(masterPassword);
            return result;
          },
      onboardingStorage: storage,
    );
    return (vm: vm, storage: storage, recoveredWith: recoveredWith);
  }

  test('phase 1 : login puis récupération de la sauvegarde', () async {
    final auth = FakeAuthService()
      ..backup = StoredVaultKey(wrappedVaultKey: wrapped, salt: salt);
    final (:vm, storage: _, recoveredWith: _) = build(auth);

    final ok = await vm.fetchBackup(username: 'alice', password: 'compte1!');

    expect(ok, isTrue);
    expect(vm.backupFetched, isTrue);
    expect(vm.error, isNull);
    expect(auth.loggedInUsernames, ['alice']);
    // C'est la clé exportée du login qui ouvre l'enveloppe serveur.
    expect(auth.fetchedWith, [auth.exportKey]);
  });

  test(
    'phase 1 : aucune sauvegarde sur le compte → message explicite',
    () async {
      final auth = FakeAuthService(); // backup null
      final (:vm, storage: _, recoveredWith: _) = build(auth);

      final ok = await vm.fetchBackup(username: 'alice', password: 'compte1!');

      expect(ok, isFalse);
      expect(vm.backupFetched, isFalse);
      expect(vm.error, contains('Aucune sauvegarde'));
    },
  );

  test('phase 1 : identifiants invalides → message', () async {
    final auth = FakeAuthService()
      ..loginFailure = const AuthException.invalidCredentials();
    final (:vm, storage: _, recoveredWith: _) = build(auth);

    final ok = await vm.fetchBackup(username: 'alice', password: 'faux');

    expect(ok, isFalse);
    expect(vm.error, 'Identifiants invalides.');
  });

  test('phase 2 : restaure et marque les étapes d\'onboarding', () async {
    final auth = FakeAuthService()
      ..backup = StoredVaultKey(wrappedVaultKey: wrapped, salt: salt);
    final (:vm, :storage, :recoveredWith) = build(auth);
    await vm.fetchBackup(username: 'alice', password: 'compte1!');

    final ok = await vm.restore('MotDePasseMaitre1!');

    expect(ok, isTrue);
    expect(vm.installed, isTrue);
    expect(recoveredWith, ['MotDePasseMaitre1!']);
    // Le pairing/récupération satisfait accueil + sync + mot de passe maître.
    expect(
      storage.progress.completedSteps,
      containsAll([
        OnboardingStep.welcome,
        OnboardingStep.syncChoice,
        OnboardingStep.masterPassword,
      ]),
    );
  });

  test(
    'phase 2 : mauvais mot de passe maître → message, rien marqué',
    () async {
      final auth = FakeAuthService()
        ..backup = StoredVaultKey(wrappedVaultKey: wrapped, salt: salt);
      final (:vm, :storage, recoveredWith: _) = build(
        auth,
        result: RecoverVaultResult.wrongMasterPassword,
      );
      await vm.fetchBackup(username: 'alice', password: 'compte1!');

      final ok = await vm.restore('mauvais');

      expect(ok, isFalse);
      expect(vm.installed, isFalse);
      expect(vm.error, 'Mot de passe maître incorrect.');
      expect(storage.progress.completedSteps, isEmpty);
    },
  );

  test('phase 2 : coffre déjà présent → message dédié', () async {
    final auth = FakeAuthService()
      ..backup = StoredVaultKey(wrappedVaultKey: wrapped, salt: salt);
    final (:vm, storage: _, recoveredWith: _) = build(
      auth,
      result: RecoverVaultResult.vaultAlreadyExists,
    );
    await vm.fetchBackup(username: 'alice', password: 'compte1!');

    final ok = await vm.restore('MotDePasseMaitre1!');

    expect(ok, isFalse);
    expect(vm.error, contains('existe déjà'));
  });

  test('restore avant fetch → sans effet', () async {
    final auth = FakeAuthService();
    final (:vm, storage: _, :recoveredWith) = build(auth);

    final ok = await vm.restore('peu-importe');

    expect(ok, isFalse);
    expect(recoveredWith, isEmpty);
  });
}
