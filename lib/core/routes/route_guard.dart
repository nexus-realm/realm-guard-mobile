import 'app_routes.dart';

/// Routes qui doivent rester accessibles coffre verrouillé (flux d'auth).
const Set<String> _authRoutes = <String>{
  AppRoutes.startup,
  AppRoutes.onboarding,
  // Installation par pairing : fait partie de l'onboarding, donc atteignable
  // coffre verrouillé (le coffre n'existe pas encore sur cet appareil).
  AppRoutes.pairedSetup,
  // Récupération : le coffre n'existe pas encore, donc verrouillé par nature.
  AppRoutes.vaultRecovery,
  AppRoutes.unlock,
};

/// Les écrans de debug gèrent leur propre instance de `VaultService` et ne
/// doivent donc pas être filtrés par l'état de verrouillage global.
bool _isDebugLocation(String location) {
  return location == AppRoutes.debug ||
      location == AppRoutes.securityDebug ||
      location == AppRoutes.vaultDebug ||
      location.startsWith('${AppRoutes.debug}/');
}

/// Garde de routage pure.
///
/// À partir de la [location] cible et de l'état [isUnlocked] du coffre, renvoie
/// la route de redirection, ou `null` pour autoriser la navigation.
///
/// La zone protégée (tout ce qui sort du flux d'auth et des écrans de debug)
/// exige un coffre déverrouillé ; sinon l'utilisateur est renvoyé vers
/// [AppRoutes.unlock].
String? vaultRouteGuard({required String location, required bool isUnlocked}) {
  if (_authRoutes.contains(location)) return null;
  if (_isDebugLocation(location)) return null;
  if (!isUnlocked) return AppRoutes.unlock;
  return null;
}
