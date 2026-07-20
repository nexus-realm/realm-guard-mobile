import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/security/app_lock_controller.dart';
import 'package:realmguard/core/security/vault_service.dart';

class FakeVaultService extends VaultService {
  bool unlocked = false;
  bool lockCalled = false;

  @override
  bool get isUnlocked => unlocked;

  @override
  void lockVault() {
    lockCalled = true;
    unlocked = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockController', () {
    test('locks and requests navigation on background while unlocked', () {
      final vault = FakeVaultService()..unlocked = true;
      var lockRequested = false;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () => lockRequested = true);

      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(vault.lockCalled, isTrue);
      expect(lockRequested, isTrue);
    });

    test('does nothing on background when already locked', () {
      final vault = FakeVaultService()..unlocked = false;
      var lockRequested = false;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () => lockRequested = true);

      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(vault.lockCalled, isFalse);
      expect(lockRequested, isFalse);
    });

    test('locks after the inactivity timeout while unlocked', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final vault = FakeVaultService()..unlocked = true;
      var lockRequested = false;
      final controller = AppLockController(
        vaultService: vault,
        inactivityTimeout: const Duration(minutes: 2),
        clock: () => now,
      );
      addTearDown(controller.detach);
      controller.attach(onLock: () => lockRequested = true);

      // Activité récente : pas de verrouillage.
      controller.notifyInteraction();
      controller.evaluateInactivity();
      expect(vault.lockCalled, isFalse);

      // Au-delà du délai d'inactivité : verrouillage.
      now = now.add(const Duration(minutes: 3));
      controller.evaluateInactivity();
      expect(vault.lockCalled, isTrue);
      expect(lockRequested, isTrue);
    });

    test('does not lock immediately after a fresh unlock with a stale clock', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final vault = FakeVaultService()..unlocked = false;
      final controller = AppLockController(
        vaultService: vault,
        inactivityTimeout: const Duration(minutes: 2),
        clock: () => now,
      );
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      // Temps qui passe alors que le coffre est verrouillé.
      now = now.add(const Duration(hours: 1));
      controller.evaluateInactivity();
      expect(vault.lockCalled, isFalse);

      // Le coffre vient d'être déverrouillé : l'horloge d'activité est remise à
      // zéro, donc pas de verrouillage immédiat malgré le timestamp obsolète.
      vault.unlocked = true;
      controller.evaluateInactivity();
      expect(vault.lockCalled, isFalse);
    });

    test('exposes a background lock reason after a background lock', () {
      final vault = FakeVaultService()..unlocked = true;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(controller.takePendingMessage(), LockReason.background);
    });

    test('exposes an inactivity lock reason after an inactivity lock', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final vault = FakeVaultService()..unlocked = true;
      final controller = AppLockController(
        vaultService: vault,
        inactivityTimeout: const Duration(minutes: 2),
        clock: () => now,
      );
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      controller.notifyInteraction();
      now = now.add(const Duration(minutes: 3));
      controller.evaluateInactivity();

      expect(controller.takePendingMessage(), LockReason.inactivity);
    });

    test('takePendingMessage consumes the reason (null on second call)', () {
      final vault = FakeVaultService()..unlocked = true;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(controller.takePendingMessage(), LockReason.background);
      expect(controller.takePendingMessage(), isNull);
    });

    test('has no pending message without an automatic lock', () {
      final vault = FakeVaultService()..unlocked = true;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      expect(controller.takePendingMessage(), isNull);
    });

    test('does not set a pending message when already locked', () {
      final vault = FakeVaultService()..unlocked = false;
      final controller = AppLockController(vaultService: vault);
      addTearDown(controller.detach);
      controller.attach(onLock: () {});

      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(controller.takePendingMessage(), isNull);
    });
  });
}
