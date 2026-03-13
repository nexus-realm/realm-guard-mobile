# AGENTS.md

## But du projet
- Application Flutter mobile de gestion de coffre-fort (`realm_guard_mobile`) avec base locale chiffree SQLCipher.
- Point d'entree: `lib/main.dart` (orientation portrait forcee + activation SQLCipher Android via `openCipherOnAndroid`).

## Architecture utile a comprendre vite
- UI -> Routing: `MaterialApp.router` utilise `appRouter` (`lib/core/routes/app_router.dart`) avec `ShellRoute` (`MainPage`) pour la navigation principale.
- Pages debug se trouvent sous `/debug/*` et sont bloquees en release par `_debugGuard` (`kDebugMode`).
- Flux de de-verrouillage coffre: `VaultService` (`lib/core/security/vault_service.dart`) orchestre `SaltManager` + `KeyDerivator` + `BiometricStorageService`.
- Derivation de cle: `KeyDerivator.deriveKeyFromPassword` (Argon2id) -> 32 bytes.
- Stockage persistant:
  - Salt fichier: `realmguard_security_metadata.salt` (`SaltManager`).
  - DB chiffree: `realm_guard_vault.sqlite` (`AppDatabase` + `PRAGMA key`).
  - Cle derivee biometrie: `flutter_secure_storage` (cle `derived_vault_key`).

## Conventions de code specifiques au repo
- Imports relatifs privilegies (`analysis_options.yaml`: `prefer_relative_imports`).
- Lints stricts: `prefer_final_locals`, `prefer_const_constructors`, `use_build_context_synchronously`, etc.
- Ne jamais modifier `lib/core/database/app_database.g.dart` a la main (fichier genere).
- Exceptions securite explicites via `SecurityException` (`lib/core/exceptions/security_exception.dart`).
- Style UI centralise dans `lib/core/theme/app_theme.dart` et `lib/core/theme/app_colors.dart`.

## Workflows dev critiques
- Installation locale: voir `docs/INSTALL.md` (Flutter 3.35.7, Android toolchain, Node/npm pour Husky).
- Recuperer deps Flutter:
  - `flutter pub get`
- Regenerer Drift apres modification de `app_database.dart`:
  - `dart run build_runner build --delete-conflicting-outputs`
- Tests cibles securite existants:
  - `flutter test test/core/security/key_derivator_test.dart`
  - `flutter test test/core/security/salt_manager_test.dart`
- Hooks/commitlint Node presents via `package.json` (`husky`, `@commitlint/*`).

## Points d'integration sensibles
- `local_auth` + `flutter_secure_storage` peuvent retourner `null`/echec: conserver le fallback mot de passe (`unlockWithBiometrics` retourne `false`).
- SQLCipher Android depend de l'override dans `main.dart`; ne pas retirer sans alternative plateforme.
- `HomePage` declenche un ecran debug via `context.goNamed('vaultDebug')`: comportement valide surtout en mode debug.

## Quand vous modifiez le code
- Si vous touchez `lib/core/security/*`, verifier au minimum les 2 tests `test/core/security/*`.
- Si schema Drift change, regenerer `*.g.dart` puis re-lancer les tests.
- Preserver le flux: mot de passe maitre -> derivation -> ouverture DB -> stockage cle pour biometrie.

