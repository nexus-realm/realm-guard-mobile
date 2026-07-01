# AGENTS.md — Realm Guard Mobile

> Agent-oriented context file. Dense, factual, scannable. Keep it in sync with the code.
> User-facing strings stay in French (the product language); this doc is in English for AI efficiency.

## 1. Product

- **Realm Guard** — an **offline-first password manager** mobile app.
- Goals, in priority order: **maximum security**, then a **simple / uncluttered UX** adapted to how each user uses it.
- "Offline-first" = no backend, no network sync. All data lives on-device in an **encrypted local database**.
- **Platform: Android only** today. Only `android/` is generated. `.metadata` lists iOS as "unmanaged" but no `ios/` folder exists — do not assume iOS support.
- App id / namespace: `io.github.sachabarbet.realm_guard_mobile`.
- Remote: `github.com/nexus-realm/realm-guard-mobile`.

## 2. Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter (**3.44.4**, stable channel — matches CI) |
| Language | Dart (SDK `^3.10.8`) |
| Routing | `go_router` ^16.3.0 (`MaterialApp.router`, `ShellRoute`) |
| DB | `drift` ^2.31.0 over **SQLCipher** (`sqlcipher_flutter_libs` ^0.6.7, `sqlite3`) |
| Crypto | `cryptography` ^2.9.0 (Argon2id) |
| Secrets | `flutter_secure_storage` ^10.0.0 (OS keystore) |
| Biometrics | `local_auth` ^3.0.1 |
| Fonts | `google_fonts` ^8.0.2 (Plus Jakarta Sans, Space Grotesk) |
| Paths | `path_provider`, `path` |
| Codegen | `drift_dev`, `build_runner` (dev) |
| Lints | `flutter_lints` ^6.0.0 + strict rules (see §9) |
| Commit tooling | Node `husky` + `@commitlint/*` (Conventional Commits) |

No state-management package: state is **manual MVVM** with `ChangeNotifier` / `ListenableBuilder` (see §5).

## 3. Architecture: feature-first + MVVM

```
lib/
  main.dart                 # entrypoint: portrait lock, Android SQLCipher override, MaterialApp.router
  core/                     # cross-cutting infra (no feature logic)
    database/               # Drift AppDatabase, table models, VaultRepository
    security/               # VaultService, UnlockService, KeyDerivator, SaltManager, BiometricStorageService
    routes/                 # AppRoutes (path constants) + app_router (GoRouter + manual DI)
    theme/                  # AppColors, AppTheme (dark only)
    exceptions/             # SecurityException
  features/<feature>/       # onboarding, unlock, home, debug
    data/                   # value objects / enums (e.g. OnboardingStep, password rules)
    service/                # feature services / flow controllers
    viewmodels/             # ChangeNotifier ViewModels
    views/                  # Pages (StatefulWidget)
  shared/                   # reusable across features
    notifiers/              # ChangeNotifier + InheritedNotifier scopes (Fab, Search)
    viewmodels/             # HomeViewModel
    views/home/             # HomeShell (Scaffold chrome: appbar/search, bottom nav, FAB, settings)
    widgets/                # GradientFilledButton, PasswordForm, ViewTitle, NeonBoxDecoration
    animations/             # AppTransitions
```

**Dependency injection is manual.** Long-lived services are instantiated as top-level `final`s in `lib/core/routes/app_router.dart` (`_vaultService`, `_unlockService`, `_onboardingStorageService`) and passed into pages via constructors. When adding a new shared service, follow this pattern.

## 4. Navigation flow

`initialLocation: /startup`. Routes in `lib/core/routes/app_router.dart`, paths in `lib/core/routes/app_routes.dart`.

```
/startup  (StartupGatePage)
   └─ StartupGateViewModel: loadProgress + isBiometricAvailable
        ├─ onboarding incomplete ──▶ /onboarding
        └─ onboarding complete   ──▶ /unlock
/onboarding (OnboardingPage)
   └─ steps: welcome → masterPassword → biometricChoice  (biometric step skipped if unavailable)
        └─ all steps done ──▶ /home
/unlock (UnlockPage)
   └─ UnlockViewModel: determineUnlockStrategy
        ├─ biometric (auto-attempt; after 3 in-session biometric failures ──▶ password)
        └─ password
             └─ success ──▶ /home
ShellRoute(HomeShell)
   └─ /home (HomeTab)        # the only shell child today
/debug                       # redirect ──▶ /home when !kDebugMode (_debugGuard)
   ├─ /security-debug
   └─ /vault-debug
```

`StartupRouteTarget.home` exists in the enum but the gate VM never produces it today (only `onboarding` / `unlock`).

## 5. State management pattern (follow this exactly)

- ViewModels extend `ChangeNotifier`. Views are `StatefulWidget`.
- View lifecycle: create VM in `initState` (or `didChangeDependencies` when it needs an inherited dependency, e.g. `HomeTab`), `addListener(_onViewModelUpdated)` **or** wrap UI in `ListenableBuilder`, call `viewModel.initialize()`, then in `dispose` `removeListener` + `viewModel.dispose()`.
- `OnboardingViewModel` is a thin facade over `OnboardingFlowController` (also a `ChangeNotifier`) and forwards notifications.
- **Cross-widget state uses `InheritedNotifier` scopes**, provided by `HomeShell`:
  - `SearchNotifierScope` / `SearchNotifier` — the app-bar search query.
  - `FabNotifierScope` / `FabNotifier` — the shell's FAB. A tab `register(...)`s its FAB action in a `postFrameCallback` and `unregister()`s in `dispose`. The shell renders the FAB from the notifier.
- Navigation side effects (`context.go(...)`) happen inside `_onViewModelUpdated`, guarded by `if (!mounted) return;` and often deferred with `addPostFrameCallback`.

## 6. Security model (the core of the product — treat with care)

**Key derivation & vault unlock chain:**

1. `SaltManager.getOrGenerateSalt()` — 32-byte salt from `Random.secure()`, persisted to `realmguard_security_metadata.salt` in the app support dir. Not secret, but must stay unique/persistent. Throws `SecurityException` if an existing salt file isn't 32 bytes.
2. `KeyDerivator.deriveKeyFromPassword(password, salt)` — **Argon2id**, params: `iterations=3`, `memory=65536` KB (64 MB), `parallelism=1`, `hashLength=32` ⇒ 256-bit key. Throws `ArgumentError` on blank password.
3. `VaultService.unlockWithMasterPassword(pw)` — derives key, opens `AppDatabase(keyBytes)`, runs `SELECT 1` to validate, then caches the derived key via `BiometricStorageService.saveDerivedKey` (base64). On any failure: close + null the DB and throw.
4. `AppDatabase` opens a `NativeDatabase` with `PRAGMA key = "x'<hexKey>'"` and `PRAGMA cipher_page_size = 4096` ⇒ full-DB SQLCipher encryption. The DB file is `realm_guard_vault.sqlite` in the app support dir.
5. Biometric unlock: `BiometricStorageService.getDerivedKeyWithBiometrics` checks the cached key exists + biometrics available, runs `local_auth.authenticate(biometricOnly: true, sensitiveTransaction: true)`, and on success reads the cached key and opens the DB. Returns `null`/`false` on any failure → caller falls back to password.

**`UnlockService` attempt/lockout policy** (constants in `lib/core/security/unlock_service.dart`):

| Constant | Value | Meaning |
|---|---|---|
| `_keyValidityDuration` | 7 days | cached biometric key considered usable |
| `_biometricPromptInterval` | 7 days | re-require password periodically |
| `_attemptCooldown` | 2 s | enforced delay before each attempt |
| `_lockoutDuration` | 5 min | lockout after too many failures |
| `_maxFailedAttempts` | 5 | failures before lockout |

- `determineUnlockStrategy()` → `biometric` only if (key not expired) AND (biometrics available) AND (biometric failures < 5) AND (no periodic re-prompt due); else `password`.
- `attempt*Unlock()` check lockout first, apply cooldown, record failures, and arm the 5-min lockout once `_maxFailedAttempts` is reached. `getRemainingLockout()` self-cleans expired/invalid lockout timestamps.
- `UnlockViewModel` runs a 1-second `Timer` to count down the lockout and switches to password after 3 in-session biometric failures.

**Persistent storage map:**

| Location | What |
|---|---|
| app support dir / `realm_guard_vault.sqlite` (+ `-wal`, `-shm`) | encrypted vault DB |
| app support dir / `realmguard_security_metadata.salt` | 32-byte salt |
| secure storage `derived_vault_key` | base64 derived key (biometric fast unlock) |
| secure storage `onboarding_progress_v1` | onboarding progress JSON |
| secure storage `last_key_timestamp_v1`, `last_biometric_prompt_v1`, `failed_attempts_count_v1`, `lockout_timestamp_v1`, `biometric_failures_count_v1` | `UnlockService` state |

- Android requires the SQLCipher override in `main.dart` (`open.overrideFor(OperatingSystem.android, openCipherOnAndroid)`). **Do not remove** without a platform alternative.
- Use `SecurityException` (`lib/core/exceptions/security_exception.dart`) for security-critical failures.
- "Supprimer toutes les données" (Settings → "Zone de danger", available to **all** users, confirm by typing `SUPPRIMER`) wipes secure storage + the Android Keystore key + DB files (+`-wal`/`-shm`/`-journal`) + salt, then routes to `/startup` → onboarding. `SettingsViewModel.deleteAllData` awaits `VaultService.closeVault()` before `AppResetService.wipeAllData()`.

## 7. Data layer (Drift)

Tables in `lib/core/database/models/`:

- **Profiles**: `id` (autoIncrement PK), `name` (text), `emails` (text = **JSON list** of emails).
- **Credentials**: `id` (autoIncrement PK), `title` (text), `encryptedData` (text), `profileId` (int, nullable, FK → `Profiles.id`).

`schemaVersion = 2`. Migration v1→v2 (`app_database.dart`): rename old `vault_entries` table to `credentials`, add `profileId` column, create `profiles` table.

`VaultRepository` (`lib/core/database/vault_repository.dart`) wraps all queries: profile/credential CRUD, `getCredentialsForProfile`, and `getCredentialsWithProfiles()` (left outer join → `CredentialWithProfile(credential, profile?)`).

> ⚠️ **`Credentials.encryptedData` per-entry encryption is UNDECIDED.** Today the column stores whatever string is passed; the only encryption in place is SQLCipher at the DB level. Do **not** assume a second app-level encryption layer exists. If asked to add one (defense-in-depth on top of SQLCipher), confirm scope first.

## 8. Theming & UI

- **Dark theme only** (`ThemeMode.dark`, `AppTheme.darkTheme`). Orientation locked to portrait.
- Centralize colors in `AppColors` and text/component styles in `AppTheme` — don't hardcode. Accent (`mainColor`) is `darkYellow #DAEE00`; background near-black `#0e0e0e`.
- Fonts via `google_fonts`: Space Grotesk for titles, Plus Jakarta Sans for body/labels.
- Shared widgets: `GradientFilledButton` (+ `.icon`), `PasswordForm` (live rule checklist when a confirmation field is present), `ViewTitle`, `NeonBoxDecoration`, `AppTransitions.fadeSlide` (note: defined but **not** currently wired into `appRouter`).
- Master-password rules (`PasswordValidationRules`): ≥12 chars, ≥1 uppercase, ≥1 lowercase, ≥1 digit, ≥1 special. `OnboardingFlowController` additionally enforces ≥12 and confirmation match.

## 9. Code conventions

- **Relative imports only** (`prefer_relative_imports`, enforced).
- Strict lints (`analysis_options.yaml`): `prefer_final_locals`, `prefer_const_constructors`, `avoid_print`, `use_build_context_synchronously`, `no_leading_underscores_for_local_identifiers`, `avoid_unnecessary_containers`, `prefer_interpolation_to_compose_strings`, `prefer_is_empty`/`prefer_is_not_empty`, etc.
- **Never hand-edit generated files** (`lib/core/database/app_database.g.dart`). Regenerate instead (§10).
- User-facing strings / messages: **French**. Code identifiers: English; some docstrings are English.
- Commits: **Conventional Commits** (commitlint `config-conventional`, husky `commit-msg` hook).

## 10. Dev workflows

```bash
flutter pub get                                            # Flutter deps
npm install                                                # husky / commitlint hooks
flutter run                                                # run on Android device/emulator
dart run build_runner build --delete-conflicting-outputs  # regen Drift *.g.dart after schema edits
flutter analyze                                            # static analysis (CI gate)
flutter test                                               # unit tests (CI gate)
flutter build apk --release                                # release APK (currently signed with DEBUG keys — TODO real signing)
```

Local setup details (Windows toolchain): see `docs/INSTALL.md`.

## 11. Testing

- `test/` **mirrors** `lib/`.
- DI in tests uses **hand-written `Fake`/`InMemory` subclasses** (e.g. `InMemoryOnboardingStorageService`, `FakeBiometricStorageService`) — no mocking library.
- Existing coverage: `test/core/security/{key_derivator,salt_manager}_test.dart`; `test/features/onboarding/{services,viewmodels}/*`.
- Run focused security tests when touching crypto: `flutter test test/core/security/`.

## 12. Git & CI

- **GitFlow**, branch names enforced by `.github/workflows/common-ci.yml`:
  - `feature|fix|chore/rg-<N>` → `develop`
  - `develop` → `main`
  - `hotfix/rg-<N>` → `main`
  - `<N>` is numeric only. `rg-<N>` = the issue/ticket key.
- PR CI: `flutter analyze` + `flutter test` (Flutter 3.44.4).
- Release (`.github/workflows/release.yml`): on push to `home` or `release/*` → `conventional-changelog-action` bumps `pubspec.yaml` `version`, builds APK, publishes a GitHub release with `CHANGELOG.md`. (The `home` trigger is unusual — verify before relying on it.)

## 13. Known gaps / open questions (as of this writing)

1. **`encryptedData` per-entry encryption: undecided** (see §7).
2. `HomeViewModel._addProfile` / `_addCredential` are **empty stubs** — the "add profile / add credential" bottom-sheet actions do nothing yet.
3. **Home list mismatch**: `HomeViewModel.results` holds `Credential` objects, but `HomeTab` only renders `Profile` and `CredentialWithProfile` → credentials currently don't display. Reconcile when wiring the vault list (likely switch the VM to `getCredentialsWithProfiles()`).
4. `HomeShell.actions` has 1 entry but the `BottomNavigationBar` has 2 tabs (both routing to `/home`); selecting "Partage" (index 1) indexes `actions[1]` → `RangeError`. The "Partage" tab is unimplemented.
5. `AppTransitions` exists but isn't wired into `appRouter`.
6. Duplicate (unused) `CategoryFilter` enum in both `home_shell.dart` and `home_tab.dart`.
7. Release build signs with **debug keys** (`android/app/build.gradle.kts` TODO).
8. Toolchain pinned to Flutter **3.44.4** across CI, the release workflow, and INSTALL.md (aligned).

## 14. When you change X, do Y

- Touch `lib/core/security/*` → run `test/core/security/*`; reason explicitly about cooldown / lockout / strategy. For `UnlockService`, cover lockout, cooldown, and both strategies.
- Change a Drift table or `app_database.dart` → bump `schemaVersion`, add a migration step, **regenerate** `*.g.dart`, then run tests. Preserve the flow: master password → derive → open DB → cache key for biometrics.
- Add a route → add a constant to `AppRoutes` and a `GoRoute`; put tab screens under the `ShellRoute`; keep debug screens behind `_debugGuard`.
- Add a feature → `features/<name>/{data,service,viewmodels,views}`, ViewModel extends `ChangeNotifier`, inject services via constructor.
- Add a long-lived service → instantiate it as a top-level `final` in `app_router.dart` (current DI pattern).
- Any user-facing copy → **French**; route colors/styles through `AppColors` / `AppTheme`.
