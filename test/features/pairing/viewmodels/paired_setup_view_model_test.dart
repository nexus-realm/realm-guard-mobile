import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/onboarding/data/onboarding_step.dart';
import 'package:realmguard/features/onboarding/service/onboarding_progress.dart';
import 'package:realmguard/features/onboarding/service/onboarding_storage_service.dart';
import 'package:realmguard/features/pairing/data/pairing_exception.dart';
import 'package:realmguard/features/pairing/service/pairing_service.dart';
import 'package:realmguard/features/pairing/viewmodels/paired_setup_view_model.dart';

class _FakePairing implements PairingApi {
  final vaultKey = Uint8List.fromList([4, 4, 4]);

  /// L'auth d'appareil échoue-t-elle ? (cas réel : la source n'a pas encore inscrit
  /// cet appareil au moment de l'installation.)
  bool failAuthenticate = false;
  int authenticateCalls = 0;

  @override
  Future<PairingSession> startNewDevice() async => PairingSession(
    state: Uint8List.fromList([1]),
    relayId: 'r',
    qrPayload: '{"i":"r","q":"AAAA"}',
  );

  @override
  Future<PairingReceipt> receiveVaultKey(
    PairingSession session, {
    Duration timeout = const Duration(minutes: 3),
    Duration interval = const Duration(seconds: 2),
  }) async => PairingReceipt(
    vaultKey: vaultKey,
    accountId: '00000000-0000-0000-0000-000000000001',
    sas: '424242',
  );

  @override
  Future<PairingSealOutcome> pairScannedDevice({
    required String qrPayload,
    required String accountId,
    required Uint8List vaultKey,
  }) => throw UnimplementedError();

  @override
  Future<void> registerPairedDevice({
    required Uint8List devicePublicKey,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<void> authenticateDevice() async {
    authenticateCalls++;
    if (failAuthenticate) throw const PairingException.deviceRejected();
  }
}

class _FakeOnboardingStorage extends OnboardingStorageService {
  OnboardingProgress progress = OnboardingProgress.initial();

  @override
  Future<OnboardingProgress> loadProgress() async => progress;

  @override
  Future<void> saveProgress(OnboardingProgress value) async => progress = value;
}

void main() {
  test('pairing puis installation : marque accueil + mot de passe', () async {
    final pairing = _FakePairing();
    final storage = _FakeOnboardingStorage();
    List<int>? installedKey;
    String? installedPassword;

    final vm = PairedSetupViewModel(
      pairing: pairing,
      install: (vaultKey, password) async {
        installedKey = vaultKey;
        installedPassword = password;
      },
      onboardingStorage: storage,
    );

    await vm.startPairing();
    expect(vm.qrPayload, isNotNull);
    expect(vm.sas, '424242');

    final installed = await vm.installVault(
      'motdepasse-long',
      'motdepasse-long',
    );

    expect(installed, isTrue);
    expect(vm.installed, isTrue);
    expect(installedKey, pairing.vaultKey);
    expect(installedPassword, 'motdepasse-long');
    expect(
      storage.progress.completedSteps,
      containsAll([
        OnboardingStep.welcome,
        OnboardingStep.syncChoice,
        OnboardingStep.masterPassword,
      ]),
    );
  });

  test('mot de passe trop court → refusé, rien installé', () async {
    var installs = 0;
    final vm = PairedSetupViewModel(
      pairing: _FakePairing(),
      install: (key, password) async => installs++,
      onboardingStorage: _FakeOnboardingStorage(),
    );
    await vm.startPairing();

    final installed = await vm.installVault('court', 'court');

    expect(installed, isFalse);
    expect(vm.installed, isFalse);
    expect(vm.error, isNotNull);
    expect(installs, 0);
  });

  test('confirmation différente → refusé', () async {
    var installs = 0;
    final vm = PairedSetupViewModel(
      pairing: _FakePairing(),
      install: (key, password) async => installs++,
      onboardingStorage: _FakeOnboardingStorage(),
    );
    await vm.startPairing();

    final installed = await vm.installVault(
      'motdepasse-long',
      'motdepasse-autre',
    );

    expect(installed, isFalse);
    expect(vm.error, isNotNull);
    expect(installs, 0);
  });

  test('pas de VaultKey reçue → installation impossible', () async {
    var installs = 0;
    final vm = PairedSetupViewModel(
      pairing: _FakePairing(),
      install: (key, password) async => installs++,
      onboardingStorage: _FakeOnboardingStorage(),
    );

    // startPairing() n'a pas été appelé : aucune VaultKey en main.
    final installed = await vm.installVault(
      'motdepasse-long',
      'motdepasse-long',
    );

    expect(installed, isFalse);
    expect(installs, 0);
  });
}
