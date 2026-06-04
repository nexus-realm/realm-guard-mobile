import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/debug/views/security_debug_page.dart';
import '../../features/debug/views/vault_debug_page.dart';
import '../../features/home/views/add_credential_page.dart';
import '../../features/home/views/add_profile_page.dart';
import '../../features/home/views/credential_detail_page.dart';
import '../../features/home/views/home_tab.dart';
import '../../features/home/views/profile_detail_page.dart';
import '../../features/home/views/profiles_page.dart';
import '../../features/onboarding/service/onboarding_storage_service.dart';
import '../../features/onboarding/views/onboarding_page.dart';
import '../../features/onboarding/views/startup_gate_page.dart';
import '../../features/settings/data/legal_documents.dart';
import '../../features/settings/service/app_reset_service.dart';
import '../../features/settings/views/about_page.dart';
import '../../features/settings/views/change_password_page.dart';
import '../../features/settings/views/legal_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/unlock/views/unlock_page.dart';
import '../../shared/views/home/home_shell.dart';
import '../../core/database/vault_repository.dart';
import '../security/app_lock_controller.dart';
import '../security/biometric_storage_service.dart';
import '../security/unlock_service.dart';
import '../security/vault_service.dart';
import 'app_routes.dart';
import 'route_guard.dart';

final OnboardingStorageService _onboardingStorageService =
    OnboardingStorageService();
final VaultService _vaultService = VaultService();
final UnlockService _unlockService = UnlockService(vaultService: _vaultService);
final AppLockController appLockController = AppLockController(
  vaultService: _vaultService,
);

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.startup,
  redirect: (context, state) => vaultRouteGuard(
    location: state.matchedLocation,
    isUnlocked: _vaultService.isUnlocked,
  ),
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
      builder: (context, state) => UnlockPage(
        unlockService: _unlockService,
        lockController: appLockController,
      ),
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
      path: AppRoutes.addProfile,
      name: 'addProfile',
      builder: (context, state) =>
          AddProfilePage(repository: VaultRepository(_vaultService.db)),
    ),
    GoRoute(
      path: AppRoutes.addCredential,
      name: 'addCredential',
      builder: (context, state) =>
          AddCredentialPage(repository: VaultRepository(_vaultService.db)),
    ),
    GoRoute(
      path: '${AppRoutes.credentialDetail}/:id',
      name: 'credentialDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CredentialDetailPage(
          repository: VaultRepository(_vaultService.db),
          credentialId: id,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.profiles,
      name: 'profiles',
      builder: (context, state) =>
          ProfilesPage(repository: VaultRepository(_vaultService.db)),
    ),
    GoRoute(
      path: '${AppRoutes.profileDetail}/:id',
      name: 'profileDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ProfileDetailPage(
          repository: VaultRepository(_vaultService.db),
          profileId: id,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => SettingsPage(
        vaultService: _vaultService,
        biometricService: BiometricStorageService(),
        resetService: AppResetService(),
      ),
      routes: [
        GoRoute(
          path: 'change-password',
          name: 'settingsChangePassword',
          builder: (context, state) =>
              ChangePasswordPage(vaultService: _vaultService),
        ),
        GoRoute(
          path: 'about',
          name: 'settingsAbout',
          builder: (context, state) => const AboutPage(),
          routes: [
            GoRoute(
              path: 'privacy',
              name: 'settingsPrivacy',
              builder: (context, state) =>
                  const LegalPage(document: LegalDocuments.privacy),
            ),
            GoRoute(
              path: 'cgu',
              name: 'settingsCgu',
              builder: (context, state) =>
                  const LegalPage(document: LegalDocuments.cgu),
            ),
            GoRoute(
              path: 'legal',
              name: 'settingsLegal',
              builder: (context, state) =>
                  const LegalPage(document: LegalDocuments.legalNotice),
            ),
          ],
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
