import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/debug/views/security_debug_page.dart';
import '../../features/debug/views/vault_debug_page.dart';
import '../../features/home/views/home_tab.dart';
import '../../features/onboarding/service/onboarding_storage_service.dart';
import '../../features/onboarding/views/onboarding_page.dart';
import '../../features/onboarding/views/startup_gate_page.dart';
import '../../features/unlock/views/unlock_page.dart';
import '../../shared/views/home/home_shell.dart';
import '../security/unlock_service.dart';
import '../security/vault_service.dart';
import 'app_routes.dart';

final OnboardingStorageService _onboardingStorageService =
    OnboardingStorageService();
final VaultService _vaultService = VaultService();
final UnlockService _unlockService = UnlockService(vaultService: _vaultService);

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.startup,
  routes: [
    GoRoute(
      path: AppRoutes.startup,
      name: 'startup',
      builder: (context, state) =>
          StartupGatePage(onboardingStorageService: _onboardingStorageService),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => OnboardingPage(
        onboardingStorageService: _onboardingStorageService,
        vaultService: _vaultService,
      ),
    ),
    GoRoute(
      path: AppRoutes.unlock,
      name: 'unlock',
      builder: (context, state) => UnlockPage(unlockService: _unlockService),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => HomeTab(vaultService: _vaultService),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.debug,
      name: 'debug',
      redirect: (context, state) => _debugGuard(context, state),
      routes: [
        GoRoute(
          path: AppRoutes.securityDebug,
          name: 'securityDebug',
          builder: (context, state) => const SecurityDebugPage(),
        ),
        GoRoute(
          path: AppRoutes.vaultDebug,
          name: 'vaultDebug',
          builder: (context, state) => const VaultDebugPage(),
        ),
      ],
    ),
  ],
);

String? _debugGuard(BuildContext context, GoRouterState state) {
  if (!kDebugMode) {
    return AppRoutes.home;
  }
  return null;
}
