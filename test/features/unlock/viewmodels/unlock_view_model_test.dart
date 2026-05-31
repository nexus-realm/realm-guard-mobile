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

  group('UnlockViewModel.formatLockout (U6)', () {
    test('formate en mm:ss avec zéros de remplissage', () {
      expect(UnlockViewModel.formatLockout(const Duration(minutes: 5)), '05:00');
      expect(
        UnlockViewModel.formatLockout(
          const Duration(minutes: 4, seconds: 30),
        ),
        '04:30',
      );
      expect(UnlockViewModel.formatLockout(const Duration(seconds: 9)), '00:09');
    });

    test('arrondit les secondes au supérieur (pas de 00:00 prématuré)', () {
      expect(
        UnlockViewModel.formatLockout(const Duration(milliseconds: 4500)),
        '00:05',
      );
      expect(
        UnlockViewModel.formatLockout(const Duration(milliseconds: 1)),
        '00:01',
      );
    });

    test('retourne 00:00 pour une durée nulle ou négative', () {
      expect(UnlockViewModel.formatLockout(Duration.zero), '00:00');
      expect(
        UnlockViewModel.formatLockout(const Duration(seconds: -5)),
        '00:00',
      );
    });
  });
}
