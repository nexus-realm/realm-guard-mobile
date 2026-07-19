import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/server_config.dart';
import '../../features/auth/service/auth_service.dart';
import '../../features/auth/service/opaque_client.dart';
import '../../features/auth/service/session_store.dart';
import '../../features/auth/service/vault_key_cipher.dart';
import '../../features/auth/views/sync_page.dart';
import '../../features/auth/views/vault_recovery_page.dart';
import '../../features/debug/views/security_debug_page.dart';
import '../../features/debug/views/vault_debug_page.dart';
import '../../features/home/views/add_credential_page.dart';
import '../../features/home/views/add_profile_page.dart';
import '../../features/home/views/add_totp_page.dart';
import '../../features/home/views/credential_detail_page.dart';
import '../../features/home/views/home_tab.dart';
import '../../features/home/views/profile_detail_page.dart';
import '../../features/home/views/profiles_page.dart';
import '../../features/home/views/totp_detail_page.dart';
import '../../features/onboarding/service/onboarding_storage_service.dart';
import '../../features/onboarding/views/onboarding_page.dart';
import '../../features/onboarding/views/startup_gate_page.dart';
import '../../features/pairing/service/device_key_ffi.dart';
import '../../features/pairing/service/device_key_store.dart';
import '../../features/pairing/service/devices_service.dart';
import '../../features/pairing/service/pairing_ffi.dart';
import '../../features/pairing/service/pairing_service.dart';
import '../../features/pairing/views/add_device_page.dart';
import '../../features/pairing/views/devices_page.dart';
import '../../features/pairing/views/paired_setup_page.dart';
import '../../features/pairing/views/receive_device_page.dart';
import '../../features/settings/data/legal_documents.dart';
import '../../features/settings/service/app_reset_service.dart';
import '../../features/sync/service/sync_api.dart';
import '../../features/sync/service/sync_session_controller.dart';
import '../../features/sync/service/sync_socket.dart';
import '../../features/settings/views/about_page.dart';
import '../../features/settings/views/change_password_page.dart';
import '../../features/settings/views/legal_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/unlock/views/unlock_page.dart';
import '../../shared/views/home/home_shell.dart';
import '../../core/database/vault_repository.dart';
import '../feature_flags/feature_flags_controller.dart';
import '../security/app_lock_controller.dart';
import '../security/biometric_storage_service.dart';
import '../security/salt_manager.dart';
import '../security/unlock_service.dart';
import '../security/vault_service.dart';
import '../security/wrapped_vault_key_store.dart';
import 'app_routes.dart';
import 'route_guard.dart';

final OnboardingStorageService _onboardingStorageService =
    OnboardingStorageService();
final VaultService _vaultService = VaultService();
final UnlockService _unlockService = UnlockService(vaultService: _vaultService);
final AppLockController appLockController = AppLockController(
  vaultService: _vaultService,
);

/// Préférences de fonctionnalités (ex. activation de la gestion des TOTP).
/// Chargé au démarrage dans `main()`, consommé par l'accueil et les paramètres.
final FeatureFlagsController featureFlagsController = FeatureFlagsController();

/// Service d'authentification / synchronisation (v2, OPAQUE) — opt-in via Réglages.
final AuthService _authService = AuthService(
  opaque: const FrbOpaqueClient(),
  vaultKey: const FrbVaultKeyCipher(),
  httpClient: http.Client(),
  session: const SecureSessionStore(FlutterSecureStorage()),
  config: const ServerConfig.dev(),
);

/// Sauvegarde la VaultKey **déjà enrobée par la KEK** sur le serveur, re-scellée
/// sous la clé exportée OPAQUE : sans le mot de passe du compte **et** le mot de
/// passe maître, une fuite de la base serveur reste inexploitable.
///
/// Renvoie `false` si le coffre n'existe pas encore (compte créé à l'onboarding
/// **avant** le mot de passe maître) : il n'y a alors rien à sauvegarder.
Future<bool> _backupWrappedVaultKey(Uint8List exportKey) async {
  const store = SecureWrappedVaultKeyStore(FlutterSecureStorage());
  final wrapped = await store.read();
  if (wrapped == null) return false;
  await _authService.uploadVaultKey(
    exportKey: exportKey,
    wrappedVaultKey: wrapped,
    salt: await SaltManager.getOrGenerateSalt(),
  );
  return true;
}

/// Gestion du registre d'appareils (liste / renommage / révocation). Retente une
/// auth par clé d'appareil si la session manque (cas d'un appareil fraîchement
/// appairé, inscrit par la source seulement après confirmation du SAS).
final DevicesService _devicesService = DevicesService(
  httpClient: http.Client(),
  session: const SecureSessionStore(FlutterSecureStorage()),
  config: const ServerConfig.dev(),
  deviceKeyStore: const SecureDeviceKeyStore(FlutterSecureStorage()),
  ensureSession: () => _pairingService.authenticateDevice(),
);

/// Service de pairing d'appareil (v2) — opt-in via Réglages.
final PairingService _pairingService = PairingService(
  ffi: const FrbPairingFfi(),
  deviceKeyFfi: const FrbDeviceKeyFfi(),
  deviceKeyStore: const SecureDeviceKeyStore(FlutterSecureStorage()),
  httpClient: http.Client(),
  session: const SecureSessionStore(FlutterSecureStorage()),
  config: const ServerConfig.dev(),
);

/// Client du log de synchronisation (`/sync/*`), gated par session (ré-auth par
/// clé d'appareil à la volée).
final SyncApi _syncApi = SyncService(
  httpClient: http.Client(),
  session: const SecureSessionStore(FlutterSecureStorage()),
  config: const ServerConfig.dev(),
  ensureSession: () => _pairingService.authenticateDevice(),
);

/// Cycle de vie de la synchronisation temps réel. Attaché au démarrage
/// (`main.dart`) ; ne démarre la pile qu'une fois le coffre déverrouillé
/// (déclenché par `HomeTab`), la coupe au verrouillage.
final SyncSessionController syncSessionController = SyncSessionController(
  vaultService: _vaultService,
  api: _syncApi,
  socketFactory: () => WsSyncSocket(
    session: const SecureSessionStore(FlutterSecureStorage()),
    config: const ServerConfig.dev(),
    ensureSession: () => _pairingService.authenticateDevice(),
  ),
  // Ne proposer la synchro manuelle (pull-to-refresh) que si un compte de
  // synchronisation est actif sur cet appareil.
  isSyncEnabled: _authService.isLoggedIn,
);

/// Un `VaultRepository` câblé sur la session CRDT (write-through de la synchro).
/// La session est résolue paresseusement à la première écriture ; les repos en
/// lecture seule (accueil, autofill-fill) n'en ont pas besoin.
VaultRepository _vaultRepository() => VaultRepository(
  _vaultService.db,
  crdtSession: _vaultService.ensureCrdtSession,
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
        featureFlagsController: featureFlagsController,
        authService: _authService,
      ),
    ),
    GoRoute(
      path: AppRoutes.pairedSetup,
      name: 'pairedSetup',
      builder: (context, state) => PairedSetupPage(
        pairingService: _pairingService,
        vaultService: _vaultService,
        onboardingStorageService: _onboardingStorageService,
      ),
    ),
    GoRoute(
      path: AppRoutes.vaultRecovery,
      name: 'vaultRecovery',
      builder: (context, state) => VaultRecoveryPage(
        authService: _authService,
        vaultService: _vaultService,
        onboardingStorageService: _onboardingStorageService,
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
      builder: (context, state, child) => HomeShell(
        onRemoteChange: syncSessionController.onRemoteChange,
        remoteChangeCount: () => syncSessionController.lastRemoteChangeCount,
        child: child,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => HomeTab(
            vaultService: _vaultService,
            featureFlagsController: featureFlagsController,
            syncSessionController: syncSessionController,
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addProfile,
      name: 'addProfile',
      builder: (context, state) =>
          AddProfilePage(repository: _vaultRepository()),
    ),
    GoRoute(
      path: AppRoutes.addCredential,
      name: 'addCredential',
      builder: (context, state) =>
          AddCredentialPage(repository: _vaultRepository()),
    ),
    GoRoute(
      path: '${AppRoutes.credentialDetail}/:id',
      name: 'credentialDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CredentialDetailPage(
          repository: _vaultRepository(),
          credentialId: id,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.profiles,
      name: 'profiles',
      builder: (context, state) => ProfilesPage(repository: _vaultRepository()),
    ),
    GoRoute(
      path: '${AppRoutes.profileDetail}/:id',
      name: 'profileDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ProfileDetailPage(
          repository: _vaultRepository(),
          profileId: id,
          featureFlagsController: featureFlagsController,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addTotp,
      name: 'addTotp',
      builder: (context, state) => AddTotpPage(repository: _vaultRepository()),
    ),
    GoRoute(
      path: '${AppRoutes.totpDetail}/:id',
      name: 'totpDetail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TotpDetailPage(repository: _vaultRepository(), totpId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => SettingsPage(
        vaultService: _vaultService,
        biometricService: BiometricStorageService(),
        resetService: AppResetService(),
        featureFlagsController: featureFlagsController,
      ),
      routes: [
        GoRoute(
          path: 'change-password',
          name: 'settingsChangePassword',
          builder: (context, state) =>
              ChangePasswordPage(vaultService: _vaultService),
        ),
        GoRoute(
          path: 'sync',
          name: 'settingsSync',
          builder: (context, state) => SyncPage(
            authService: _authService,
            backupVaultKey: _backupWrappedVaultKey,
          ),
        ),
        GoRoute(
          path: 'pairing-add',
          name: 'settingsPairingAdd',
          builder: (context, state) => AddDevicePage(
            pairingService: _pairingService,
            vaultService: _vaultService,
            authService: _authService,
          ),
        ),
        GoRoute(
          path: 'pairing-receive',
          name: 'settingsPairingReceive',
          builder: (context, state) =>
              ReceiveDevicePage(pairingService: _pairingService),
        ),
        GoRoute(
          path: 'devices',
          name: 'settingsDevices',
          builder: (context, state) =>
              DevicesPage(devicesService: _devicesService),
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
