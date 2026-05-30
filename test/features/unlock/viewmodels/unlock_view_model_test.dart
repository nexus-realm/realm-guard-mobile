import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/security/unlock_service.dart';
import 'package:realm_guard_mobile/features/unlock/viewmodels/unlock_view_model.dart';

/// Fake qui compte les lectures du lockout et force la stratégie mot de passe
/// (pas de tentative biométrique automatique au démarrage).
class FakeUnlockService extends UnlockService {
  FakeUnlockService();

  int getRemainingLockoutCalls = 0;
  Duration remaining = Duration.zero;

  @override
  Future<UnlockStrategy> determineUnlockStrategy() async =>
      UnlockStrategy.password;

  @override
  Future<Duration> getRemainingLockout() async {
    getRemainingLockoutCalls++;
    return remaining;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnlockViewModel - décompte de lockout (P4)', () {
    test('ne lit le stockage qu\'une fois, pas à chaque tick', () async {
      // > 1s : franchit le garde `inSeconds > 0` qui démarre le timer.
      final service = FakeUnlockService()
        ..remaining = const Duration(milliseconds: 1100);
      final vm = UnlockViewModel(
        unlockService: service,
        lockoutTick: const Duration(milliseconds: 50),
      );
      addTearDown(vm.dispose);

      await vm.initialize();

      // Une seule lecture (pendant initialize) pour amorcer le décompte.
      expect(service.getRemainingLockoutCalls, 1);
      expect(vm.remainingLockout!.inMilliseconds, greaterThan(0));

      // Après plusieurs ticks et l'expiration : le compteur de lectures n'a PAS
      // bougé, et le décompte est arrivé à zéro en mémoire.
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      expect(service.getRemainingLockoutCalls, 1);
      expect(vm.remainingLockout, Duration.zero);
    });

    test('décompte la durée restante en mémoire', () async {
      final service = FakeUnlockService()
        ..remaining = const Duration(seconds: 2);
      final vm = UnlockViewModel(
        unlockService: service,
        lockoutTick: const Duration(milliseconds: 20),
      );
      addTearDown(vm.dispose);

      await vm.initialize();
      final initial = vm.remainingLockout!;

      await Future<void>.delayed(const Duration(milliseconds: 200));

      // La valeur a diminué sans nouvelle lecture du stockage.
      expect(vm.remainingLockout!, lessThan(initial));
      expect(service.getRemainingLockoutCalls, 1);
    });
  });
}
