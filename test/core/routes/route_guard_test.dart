import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/core/routes/app_routes.dart';
import 'package:realm_guard_mobile/core/routes/route_guard.dart';

void main() {
  group('vaultRouteGuard', () {
    test('redirects to unlock when accessing the protected area locked', () {
      expect(
        vaultRouteGuard(location: AppRoutes.home, isUnlocked: false),
        AppRoutes.unlock,
      );
    });

    test('allows the protected area when unlocked', () {
      expect(
        vaultRouteGuard(location: AppRoutes.home, isUnlocked: true),
        isNull,
      );
    });

    test('never redirects auth-flow routes', () {
      for (final route in const [
        AppRoutes.startup,
        AppRoutes.onboarding,
        AppRoutes.unlock,
      ]) {
        expect(vaultRouteGuard(location: route, isUnlocked: false), isNull);
        expect(vaultRouteGuard(location: route, isUnlocked: true), isNull);
      }
    });

    test('does not gate debug routes (they own their vault instance)', () {
      for (final route in const [
        AppRoutes.debug,
        AppRoutes.securityDebug,
        AppRoutes.vaultDebug,
      ]) {
        expect(vaultRouteGuard(location: route, isUnlocked: false), isNull);
      }
    });

    test('protects nested/unknown routes when locked', () {
      expect(
        vaultRouteGuard(location: '/home/details', isUnlocked: false),
        AppRoutes.unlock,
      );
      expect(
        vaultRouteGuard(location: '/home/details', isUnlocked: true),
        isNull,
      );
    });
  });
}
