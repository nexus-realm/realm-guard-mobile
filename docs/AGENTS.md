# AGENTS.md

## But du projet
- Application Flutter mobile de gestion de coffre-fort (`realm_guard_mobile`) avec base locale chiffrée SQLCipher.
- Point d'entree: `lib/main.dart` (orientation portrait forcee + activation SQLCipher Android via `openCipherOnAndroid`).

## Architecture utile à comprendre vite
- UI -> Routing: `MaterialApp.router` utilise `appRouter` (`lib/core/routes/app_router.dart`) avec `ShellRoute` (`HomeShell`) pour la navigation principale.
- Pages debug se trouvent sous `/debug/*` et sont bloquées en release par `_debugGuard` (`kDebugMode`).
- Flux de déverrouillage coffre: `UnlockService` (`lib/core/security/unlock_service.dart`) gère les stratégies et tentatives, utilisant `VaultService` (`lib/core/security/vault_service.dart`) qui orchestre `SaltManager` + `KeyDerivator` + `BiometricStorageService`.
- Onboarding: `OnboardingStorageService` + `OnboardingProgress` suivent les étapes (welcome, masterPassword, biometricChoice) via `flutter_secure_storage`.
- Dérivation de clé: `KeyDerivator.deriveKeyFromPassword` (Argon2id) -> 32 bytes.
- Stockage persistant:
  - Salt fichier: `realmguard_security_metadata.salt` (`SaltManager`).
  - DB chiffrée: `realm_guard_vault.sqlite` (`AppDatabase` + `PRAGMA key`).
  - Clé dérivée biométrie: `flutter_secure_storage` (clé `derived_vault_key`).

## Conventions de code specifiques au repo
- Imports relatifs privilegies (`analysis_options.yaml`: `prefer_relative_imports`).
- Lints stricts: `prefer_final_locals`, `prefer_const_constructors`, `use_build_context_synchronously`, etc.
- Ne jamais modifier `lib/core/database/app_database.g.dart` a la main (fichier genere).
- Exceptions sécurité explicites via `SecurityException` (`lib/core/exceptions/security_exception.dart`).
- Style UI centralise dans `lib/core/theme/app_theme.dart` et `lib/core/theme/app_colors.dart`.

## Workflows dev critiques
- Installation locale: voir `docs/INSTALL.md` (Flutter 3.35.7, Android toolchain, Node/npm pour Husky).
- Recuperer deps Flutter:
  - `flutter pub get`
- Regenerer Drift apres modification de `app_database.dart`:
  - `dart run build_runner build --delete-conflicting-outputs`
- Tests cibles sécurité existants:
  - `flutter test test/core/security/key_derivator_test.dart`
  - `flutter test test/core/security/salt_manager_test.dart`
- Hooks/commitlint Node presents via `package.json` (`husky`, `@commitlint/*`).

## Points d'integration sensibles
- `local_auth` + `flutter_secure_storage` peuvent retourner `null`/echec: conserver le fallback mot de passe (`unlockWithBiometrics` retourne `false`).
- SQLCipher Android depend de l'override dans `main.dart`; ne pas retirer sans alternative plateforme.
- `UnlockService` impose cooldown entre tentatives et lockout de 5 min après 5 échecs; gérer les états locked.
- Onboarding utilise `flutter_secure_storage` pour persister le progrès; nettoyer si nécessaire.
- `HomePage` declenche un ecran debug via `context.goNamed('vaultDebug')`: comportement valide surtout en mode debug.

## Quand vous modifiez le code
- Si vous touchez `lib/core/security/*`, verifier au minimum les 2 tests `test/core/security/*`.
- Si vous modifiez `UnlockService`, tester les scénarios de lockout, cooldown et stratégies de déverrouillage.
- Si schema Drift change, regenerer `*.g.dart` puis re-lancer les tests.
- Preserver le flux: mot de passe maitre -> derivation -> ouverture DB -> stockage cle pour biometrie.