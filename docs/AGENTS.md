# AGENTS.md — Realm Guard Mobile

> Agent-oriented context file. Dense, factual, scannable. Keep it in sync with the code.
> User-facing strings stay in French (the product language); this doc is in English for AI efficiency.

## 1. Product

- **Realm Guard** — a **local-first password manager** for Android.
- Goals, in priority order: **maximum security**, then a **simple / uncluttered UX** adapted to how each user uses it.
- **Local-first, sync optional.** All data lives on-device in an **encrypted local database** and the app is **fully usable offline with no account**. On top of that, an **opt-in, end-to-end-encrypted, real-time multi-device sync** is available (zero-knowledge server — see §6/§15). "Offline-first" is still the default posture; the server never sees plaintext.
- **Platform: Android only** today. Only `android/` is generated. `.metadata` lists iOS as "unmanaged" but no `ios/` folder exists — do not assume iOS support.
- App id / namespace: `fr.nexusrealm.realmguard`.
- **Three repos** (the sync backend lives outside this one — see §15):
  - `github.com/nexus-realm/realm-guard-mobile` — this app.
  - `realm-guard-core` — shared Rust core (E2EE crypto + CRDT), consumed here via FFI.
  - `realm-guard-server` — Axum sync server (zero-knowledge delta relay).

## 2. Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter (**3.44.4**, stable channel — matches CI) |
| Language | Dart (SDK `^3.10.8`) |
| Min SDK | **Android 10 (API 29)** — raised from 24 for `flutter_autofill_service`. Kotlin Gradle Plugin 2.2.20 |
| Routing | `go_router` ^16.3.0 (`MaterialApp.router`, `ShellRoute`) |
| DB | `drift` ^2.31.0 over **SQLCipher** (`sqlcipher_flutter_libs`, `sqlite3`) |
| Local crypto | `cryptography` ^2.9.0 (Argon2id) **+ the Rust core via FFI** (see below) |
| Native core | **`flutter_rust_bridge` 2.12.0** + `rust_lib_realmguard` (cargokit, in `rust/` + `rust_builder/`) → the `realm-guard-core` crate (CRDT + crypto) |
| Networking | `http` ^1.2.0 (sync/auth REST) + `dart:io` `WebSocket` (sync nudge socket) |
| Secrets | `flutter_secure_storage` ^10.0.0 (OS keystore) |
| Biometrics | `local_auth` ^3.0.1 |
| QR (pairing / TOTP) | `mobile_scanner` (scan) + `qr_flutter` (display) |
| Autofill | `flutter_autofill_service` ^0.21.0 |
| Fonts | embedded assets (Plus Jakarta Sans, Space Grotesk) — no network |
| Paths | `path_provider`, `path` |
| Codegen | `drift_dev`, `build_runner` (dev) + `flutter_rust_bridge_codegen` (FFI bindings) |
| Lints | `flutter_lints` ^6.0.0 + strict rules (see §9) |
| Commit tooling | Node `husky` + `@commitlint/*` (Conventional Commits) |

No state-management package: state is **manual MVVM** with `ChangeNotifier` / `ListenableBuilder` (see §5).

## 3. Architecture: feature-first + MVVM

```
lib/
  main.dart                 # entrypoint: portrait lock, Android SQLCipher override, MaterialApp.router
  src/rust/                 # flutter_rust_bridge GENERATED bindings (frb_generated.*, api/*) — do not hand-edit
  core/                     # cross-cutting infra (no feature logic)
    database/               # Drift AppDatabase, table models, VaultRepository
    security/               # VaultService, UnlockService, KeyDerivator, SaltManager,
                            #   BiometricStorageService, vault_key_crypto, PasswordValidationRules, AppLockController
    sync/                   # CRDT↔drift plumbing: VaultCrdt, VaultProjection/Reprojector, doc+delta stores,
                            #   crdt_ffi wrapper, Mutex, device-id store, vault_seed
    feature_flags/          # FeatureFlag catalogue + controller (user-toggle UI complexity)
    routes/                 # AppRoutes (path constants) + app_router (GoRouter + manual DI)
    theme/                  # AppColors, AppTheme (dark only), AppSpacing/AppRadius
    exceptions/             # SecurityException
  features/<feature>/       # onboarding, unlock, home, settings, auth, pairing, sync, autofill, debug
    data/                   # value objects / enums / rules
    service/                # feature services / flow controllers
    viewmodels/             # ChangeNotifier ViewModels
    views/                  # Pages (StatefulWidget)
  shared/                   # reusable across features
    notifiers/              # ChangeNotifier + InheritedNotifier scopes (Fab, Search)
    viewmodels/             # HomeViewModel
    views/home/             # HomeShell (Scaffold chrome: appbar/search, bottom nav, FAB, settings)
    widgets/                # GradientElevatedButton, PasswordForm, ViewTitle, ChoiceCard, AppSnackbar, NeonBoxDecoration…
    animations/             # AppTransitions
```

**Feature map:** `onboarding` (first-run flow), `unlock` (lock screen), `home` (vault: credentials/TOTP/profiles), `settings`, `auth` (OPAQUE account + VaultKey backup + recovery), `pairing` (device-to-device linking), `sync` (real-time delta sync engine), `autofill` (Android Autofill fill/save), `debug` (dev-only screens).

**Dependency injection is manual.** Long-lived services are instantiated as top-level `final`s in `lib/core/routes/app_router.dart` (`_vaultService`, `_unlockService`, `_onboardingStorageService`, `_authService`, `_pairingService`, `_syncApi`, `syncSessionController`, …) and passed into pages via constructors. When adding a new shared service, follow this pattern.

## 4. Navigation flow

`initialLocation: /startup`. Routes in `lib/core/routes/app_router.dart`, paths in `lib/core/routes/app_routes.dart` (~25 routes). `vaultRouteGuard` redirects to `/unlock` when the vault is locked; `pairedSetup` / `vaultRecovery` are in `_authRoutes` (reachable while locked/onboarding).

```
/startup  (StartupGatePage) — loadProgress + isBiometricAvailable
   ├─ onboarding incomplete ──▶ /onboarding
   └─ onboarding complete   ──▶ /unlock
/onboarding (OnboardingPage)
   └─ steps: welcome → syncChoice → masterPassword → biometricChoice → totpChoice
        · syncChoice: "Activer la synchronisation" (→ inline "En ligne" sub-page: créer compte /
          lier appareil (QR) / récupérer) OR "Continuer hors-ligne"
        · SYNC COMES BEFORE the master password (a linked device receives a vault by pairing and
          must not first create a local one) — see onboarding_step.dart
/unlock (UnlockPage) — biometric (auto) or master password; lockout countdown
/pairedSetup (PairedSetupPage)   — new device: show QR, receive VaultKey, set local master password
/vaultRecovery (VaultRecoveryPage) — restore vault from the server backup (needs account + master pw)
ShellRoute(HomeShell)
   └─ /home (HomeTab)  — Identifiants / TOTP tabs; pull-to-refresh = manual sync
/settings … /settings/{change-password, sync, pairing/add, pairing/receive, devices, about, privacy, cgu, legal}
/debug → /security-debug, /vault-debug   (redirect to /home when !kDebugMode via _debugGuard)
```

After a pushed sub-flow that changes onboarding progress (pairing / recovery), **re-enter via `/startup`** (reloads progress fresh), never `context.go(/onboarding)` — the old onboarding page stays mounted with stale in-memory progress (documented bug + fix in `paired_setup_page.dart`).

## 5. State management pattern (follow this exactly)

- ViewModels extend `ChangeNotifier`. Views are `StatefulWidget`.
- View lifecycle: create VM in `initState` (or `didChangeDependencies` when it needs an inherited dependency, e.g. `HomeTab`), `addListener(_onViewModelUpdated)` **or** wrap UI in `ListenableBuilder`, call `viewModel.initialize()`, then in `dispose` `removeListener` + `viewModel.dispose()`.
- `OnboardingViewModel` is a thin facade over `OnboardingFlowController` (also a `ChangeNotifier`) and forwards notifications.
- **Cross-widget state uses `InheritedNotifier` scopes**, provided by `HomeShell`: `SearchNotifierScope` / `SearchNotifier` (app-bar query) and `FabNotifierScope` / `FabNotifier` (a tab `register(...)`s its FAB action in a `postFrameCallback`, `unregister()`s in `dispose`; the shell renders it).
- Navigation side effects (`context.go(...)`) happen inside `_onViewModelUpdated`, guarded by `if (!mounted) return;` and often deferred with `addPostFrameCallback`.
- **Snackbars go through `AppSnackbar.{error,success,info}`** (`shared/widgets/app_snackbar.dart`) — never hand-roll `ScaffoldMessenger…showSnackBar` (consistent styling: red error / green success / neutral info).

## 6. Security model (the core of the product — treat with care)

### 6.1 Local vault unlock (offline path — unchanged v1 chain)

1. `SaltManager.getOrGenerateSalt()` — 32-byte salt from `Random.secure()`, persisted to `realmguard_security_metadata.salt` in the app support dir. Not secret, but must stay unique/persistent. Throws `SecurityException` if an existing salt file isn't 32 bytes.
2. `KeyDerivator.deriveKeyFromPassword(password, salt)` — **Argon2id**, `iterations=3`, `memory=65536` KB (64 MB), `parallelism=1`, `hashLength=32` ⇒ 256-bit **KEK**.
3. `VaultService.unlockWithMasterPassword(pw)` — derives the KEK, opens `AppDatabase`, validates, caches the derived key via `BiometricStorageService` for fast biometric unlock. On any failure: close + null the DB and throw.
4. `AppDatabase` opens a `NativeDatabase` with `PRAGMA key = "x'<hexKey>'"` + `PRAGMA cipher_page_size = 4096` ⇒ full-DB SQLCipher encryption (`realm_guard_vault.sqlite`).
5. Biometric unlock: `BiometricStorageService.getDerivedKeyWithBiometrics` gates on `local_auth.authenticate(biometricOnly: true, sensitiveTransaction: true)`; the cached key is wrapped by a hardware Android Keystore key. Returns `null`/`false` on any failure → caller falls back to password.

### 6.2 Key hierarchy for sync (v2)

- **Two password roles, three-ish UI mentions:** (a) the **master password** = the *local unlock password* per device (Argon2id → KEK). (b) the **account password** = the OPAQUE credential for the sync account (per account, syncs the identity, **never** derives the vault key). They are independent.
- The KEK does **not** encrypt the DB directly. It **wraps a random root `VaultKey`** (independent of the password). The VaultKey is the SQLCipher key **and** encrypts CRDT field values (per-entry sub-key via HKDF). Changing the master password = re-wrap the VaultKey (no re-encrypt). `vault_key_crypto.dart` handles the local wrap.
- **Account (OPAQUE):** `AuthService` register/login (zero-knowledge; server never sees the password). Login yields a stable `export_key` used to **seal a server backup of the wrapped VaultKey** (`PUT /vault/key`). Recovery needs **both** the account password (fetch backup) and the master password (unwrap).
- **Pairing (device-to-device, passwordless):** the primary way to add a device. New device shows a QR (X25519 sealed-box + a 6-digit **SAS**); the existing device scans, confirms the SAS (two-round handshake — the source seals the VaultKey **only after** SAS confirmation), and transmits the VaultKey. A **biometric/device-credential gate** authorises the transfer. See `features/pairing/`.
- **Device registry / device-auth (Ed25519):** each device has an Ed25519 key registered in the account; the sync client authenticates via a device-auth challenge (`/auth/device/*`) to get a session — so sync works without re-entering the account password.

### 6.3 `UnlockService` attempt/lockout policy (constants in `lib/core/security/unlock_service.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_keyValidityDuration` | 7 days | cached biometric key considered usable |
| `_biometricPromptInterval` | 7 days | re-require password periodically |
| `_attemptCooldown` | 2 s | enforced delay before each attempt |
| `_lockoutDuration` | 5 min | lockout after too many failures |
| `_maxFailedAttempts` | 5 | failures before lockout |

`determineUnlockStrategy()` → `biometric` only if (key not expired) AND (biometrics available) AND (biometric failures < 5) AND (no periodic re-prompt due); else `password`. `AppLockController` auto-locks on background / inactivity.

### 6.4 Persistent storage map

| Location | What |
|---|---|
| app support dir / `realm_guard_vault.sqlite` (+ `-wal`, `-shm`) | encrypted vault DB |
| app support dir / `realmguard_security_metadata.salt` | 32-byte salt |
| secure storage `derived_vault_key` | base64 derived KEK (biometric fast unlock) |
| secure storage `onboarding_progress_v1` | onboarding progress JSON |
| secure storage `last_key_timestamp_v1`, `last_biometric_prompt_v1`, `failed_attempts_count_v1`, `lockout_timestamp_v1`, `biometric_failures_count_v1` | `UnlockService` state |
| secure storage — session token, device Ed25519 key, CRDT device-id, account id | sync/auth/pairing state |

- Android requires the SQLCipher override in `main.dart` (`open.overrideFor(OperatingSystem.android, openCipherOnAndroid)`). **Do not remove** without a platform alternative.
- `FLAG_SECURE` (no screenshots, hidden in recents), `allowBackup="false"`. Use `SecurityException` for security-critical failures.
- "Supprimer toutes les données" (Settings → "Zone de danger", confirm by typing `SUPPRIMER`) wipes secure storage + Android Keystore key + DB files (+`-wal`/`-shm`/`-journal`) + salt, then routes to `/startup`. `SettingsViewModel.deleteAllData` awaits `VaultService.closeVault()` before `AppResetService.wipeAllData()`.
- **No custom crypto.** All primitives come from audited libraries (`cryptography`) or the audited Rust core.

## 7. Data layer (Drift)

`schemaVersion = 7`. Tables in `lib/core/database/models/`:

- **Profiles**: `id` (autoIncrement PK), `name`, `emails`/`usernames`/`phoneNumbers` (JSON lists), `color`, `note`, `createdAt`, **`syncId` blob(16) unique**.
- **Credentials**: `id` PK, `title`, `username`, `password`, `uri`, `notes`, `customFields`, `favorite`, `profileId` (FK → Profiles, nullable), `createdAt`, `updatedAt`, **`syncId` blob(16) unique**.
- **Totps**: `id` PK, `label`, `account`, `secret`, `digits`, `period`, `algorithm`, `favorite`, `profileId` (FK, nullable), `createdAt`, `updatedAt`, **`syncId` blob(16) unique**.
- **CrdtDocs**: the persisted CRDT `VaultDoc` (doc bytes + HLC clock + pull cursor), single row.
- **PendingDeltas**: FIFO queue of local deltas awaiting push to the server.

Migrations (`app_database.dart`): v1→v2 (vault_entries→credentials + profiles), … v4→v5 (`syncId` + unique indexes hand-created in `onCreate` **and** `onUpgrade` + `randomblob` backfill — SQLite can't `ALTER ADD … UNIQUE`), v5→v6 (`crdt_docs`), v6→v7 (`pending_deltas` + cursor).

`VaultRepository` wraps all queries (profile/credential/TOTP CRUD, joins, `getCredentialsWithProfiles()`). Constructed with an optional `crdtSession` → **write-through**: each mutation writes drift first, then best-effort mutates the CRDT doc (non-fatal if sync is unavailable).

> ⚠️ **Per-entry app-level encryption is still SQLCipher-only** at rest locally (the columns above hold plaintext inside the encrypted DB). CRDT field *values* shipped to the server **are** encrypted (VaultKey + HKDF). A second local app-level layer (defense-in-depth) remains an open decision — see `docs/IMPROVEMENTS.md` (SEC-1). Confirm scope before adding one.

## 8. Theming & UI

- **Dark theme only** (`ThemeMode.dark`, `AppTheme.darkTheme`). Orientation locked to portrait.
- Centralize colors in `AppColors`, spacing/radii in `AppSpacing`/`AppRadius`, styles in `AppTheme` — don't hardcode. Accent (`mainColor`) `darkYellow #DAEE00`; background near-black `#0e0e0e`.
- Fonts: Space Grotesk (titles), Plus Jakarta Sans (body/labels), embedded (offline).
- Shared widgets: `GradientElevatedButton` (+ `.icon`), `PasswordForm` (live rule checklist), `ViewTitle`, **`ChoiceCard`** (icon + title + subtitle option cards — used by onboarding "En ligne" and Settings → Sync), **`AppSnackbar`** (error/success/info), `NeonBoxDecoration`.
- Password rules (`core/security/password_validation_rules.dart`): ≥12, ≥1 upper/lower/digit/special. **Account** username rules (`features/auth/data/username_rules.dart`): ≥3 chars, `[A-Za-z0-9._-]` only. Both surfaced via `AccountCredentialRules`.

## 9. Code conventions

- **Relative imports only** (`prefer_relative_imports`, enforced).
- Strict lints (`analysis_options.yaml`): `prefer_final_locals`, `prefer_const_constructors`, `avoid_print`, `use_build_context_synchronously`, `no_leading_underscores_for_local_identifiers`, etc. `analyze` excludes `rust_builder/**`, `lib/src/rust/**`, `*.g.dart`, `build/**`.
- **Never hand-edit generated files** (`*.g.dart`, `lib/src/rust/frb_generated.*`). Regenerate instead (§10).
- User-facing strings / messages: **French**. Code identifiers: English; some docstrings English.
- Commits: **Conventional Commits** (commitlint `config-conventional`, husky `commit-msg`).

## 10. Dev workflows

```bash
flutter pub get                                            # Flutter deps
npm install                                                # husky / commitlint hooks
flutter run                                                # run on Android device/emulator
dart run build_runner build --delete-conflicting-outputs  # regen Drift *.g.dart after schema edits
flutter_rust_bridge_codegen generate                      # regen FFI bindings after a core signature change
flutter analyze                                            # static analysis (CI gate)
flutter test                                               # unit/widget tests (CI gate)
flutter build apk --debug                                  # build gate
flutter build apk --release                                # signed release (key.properties / RG_* env; debug fallback — docs/RELEASE.md)
```

- The Rust core is built automatically by cargokit during the Flutter Android build (needs a Rust toolchain — see `docs/INSTALL.md`). Mobile pins the core crate in `rust/Cargo.toml` (git branch/tag).
- **Sync development** needs the server stack (Postgres + Redis + the Axum server) — run `realm-guard-server`'s `docker-compose` and point the app at it (`ServerConfig.dev()` = `10.0.2.2:8080` from an emulator). See `realm-guard-server` docs.

## 11. Testing

- `test/` **mirrors** `lib/`. DI in tests uses hand-written `Fake`/`InMemory` subclasses — no mocking library.
- **`flutter test` has neither SQLCipher nor the Rust lib** → drift-coupled / FFI-coupled code is **not host-testable** → use fakes + on-device smoke. Pure logic (rules, CRDT wrappers over a fake FFI, sync controllers over fake runners/sockets, view models) **is** unit-tested.
- `Uint8List ==` is **reference** equality in tests → index or compare via `UuidValue`, never `firstWhere(x == otherUint8List)`.
- Run focused security tests when touching crypto: `flutter test test/core/security/`.

## 12. Git & CI

- **GitFlow**, branch names enforced by `.github/workflows/common-ci.yml`: `feature|fix|chore/rg-<N>` → `develop` → `staging` → `main`; `hotfix/rg-<N>` → `main`. `<N>` numeric.
- **PR CI** (`common-ci.yml`): branch-name check → **`dart format --set-exit-if-changed`** + `flutter analyze` + `flutter test` + `flutter build apk --debug` (Flutter 3.44.4). `dart format` is a **separate gate** from analyze — run `dart format lib test` before pushing.
- **Release CD** (`.github/workflows/release.yml`): build-once-then-promote. Push `staging` cuts the version (`conventional-changelog` bump+tag) + ships beta (GitHub pre-release APK; Play closed testing AAB if `PLAY_ENABLED`). Merging `staging→main` (or manual dispatch) **promotes the same build** (full GitHub release; Play production). Signing from `RG_*` secrets. Full flow: **`docs/RELEASE.md`**. `pubspec` `version` is a placeholder on feature/develop branches (the CD computes it).

## 13. Known gaps / open questions (as of this writing)

1. **Per-entry local encryption undecided** (SQLCipher-only at rest locally — see §7 / IMPROVEMENTS SEC-1).
2. **Release build not yet device-tested** end-to-end (signed + R8): smoke the release APK — especially **autofill** (R8-sensitive) — before the first store publish. Channel B (Play) also needs one-time setup (`docs/RELEASE.md` §2).
3. **Recovery kit (BIP39 24 words)** exists in the core crate but has no mobile UI yet; mobile recovery today = pairing or server backup (`vaultRecovery`).
4. **F3 (observed):** a single edit re-emits *all* of an entry's fields (via `clearNulls`) → ~10 deltas per edit; the server log grows until a periodic snapshot compacts it. Harmless (merge is idempotent), just chatty.
5. `AppTransitions` exists but isn't wired into `appRouter`.
6. See `docs/IMPROVEMENTS.md` for the tracked improvement register (backup/export **UX-4**, clipboard auto-clear **SEC-2**, password generator **UX-2**, drift `watch` `onError` **ARCH-1**, …).

## 14. When you change X, do Y

- Touch `lib/core/security/*` → run `test/core/security/*`; reason explicitly about cooldown / lockout / strategy. Preserve the chain: master pw → Argon2id KEK → unwrap VaultKey → open SQLCipher DB → cache key for biometrics.
- Change a Drift table or `app_database.dart` → bump `schemaVersion`, add a migration step (remember: no `ALTER ADD UNIQUE` — hand-create the index in `onCreate` **and** `onUpgrade`), **regenerate** `*.g.dart`, run tests. Keep the `syncId` invariant on synced tables.
- Change a **core FFI signature** → `flutter_rust_bridge_codegen generate`, and after merging a new core symbol bump the pin (`cargo update -p realm-guard-core` in `rust/`, commit `Cargo.lock`) or the APK build breaks.
- Touch the **sync path** (`core/sync/*`, `features/sync/*`) → reason about the shared per-session **`Mutex`** (serialises doc read-modify-write between local writes and pulls), the **write-through** best-effort contract, and the **destructive reprojection** (only after a merge on a **seeded** doc). See `docs/SYNC_MAPPING.md` for the durable wire format.
- Add a route → constant in `AppRoutes` + `GoRoute`; tab screens under the `ShellRoute`; debug screens behind `_debugGuard`; screens reachable while locked go in `_authRoutes`.
- Add a feature → `features/<name>/{data,service,viewmodels,views}`, VM extends `ChangeNotifier`, inject services via constructor; add long-lived services as top-level `final`s in `app_router.dart`.
- Any user-facing copy → **French**; colors/styles through `AppColors` / `AppTheme`; snackbars through `AppSnackbar`.

## 15. Multi-device sync (v2) — architecture summary

- **Model:** drift is a **read projection**; the **CRDT `VaultDoc` is the source of truth** for sync. Every local write goes drift-first then write-through into the doc; the UI keeps reading drift. Pulls merge remote deltas into the doc, then **reproject** the doc back into drift.
- **CRDT:** delta-state (`AddWinsSet` presence + LWW field registers, HLC + `DeviceId` tiebreak), implemented in the Rust core and reached via `crdt_ffi.dart`. The mobile `DeviceId` is a random persisted 16 bytes (not the Ed25519 key).
- **Wire format:** frozen in **`docs/SYNC_MAPPING.md`** (`syncId`⇔EntryId, field-id ranges per kind, tagged value codec, profileId as UUID, favorite + createdAt synced, deletion = remove_entry).
- **Engine:** `SyncEngine` = push pending deltas → pull since cursor → merge → advance HLC → reproject; `SyncController` serialises/coalesces cycles (a `Mutex` prevents double-push, incl. the manual `syncNow()`); `SyncSessionController` starts the stack per unlocked session and triggers on write / foreground / 30 s tick / WS nudge. **Manual sync** = pull-to-refresh on the home lists (`syncNow()` → typed `SyncOutcome`, gated on `isLoggedIn`).
- **Server (`realm-guard-server`):** zero-knowledge, opaque delta log per account indexed by `seq`; snapshot/compaction (410 Gone when the cursor precedes the snapshot); `/sync/ws` is a **nudge only** (never a delivery channel — the client always pulls by cursor).
- **Conflict UX:** the CRDT resolves everything (LWW); a pull that changed the vault surfaces a **passive** snackbar ("N modifications reçues d'un autre appareil"), no blocking prompt.
