# IMPROVEMENTS.md — Realm Guard Mobile

> Living register of **possible** improvements across UI/UX, code architecture, performance and
> security. Analysis only — **nothing here has been applied**. Use the `Status` column to track
> evolution over time.
>
> Audited against the codebase on **2026-06-22** (branch `feature/rg-19`). User-facing strings stay
> French; this doc is English (AI efficiency), consistent with `AGENTS.md`.

## How to use this file

- Each item has a stable **ID** (`SEC-n`, `PERF-n`, `ARCH-n`, `UX-n`). IDs never get reused.
- **Status**: `Open` (not started) · `In progress` · `Done` · `Won't do` (with reason).
- **Severity**: `Critical` · `High` · `Medium` · `Low`. **Effort**: `S` (hours) · `M` (1–2 days) · `L` (multi-day).
- When an item ships, set `Status: Done` and add the commit/PR + date next to it; keep the row for history.

## Context — what is already solid (not in scope here)

So the register isn't read as "the app is weak", these were verified as **already well done** and are
deliberately excluded: SQLCipher full-DB encryption with Argon2id (t=3, m=64 MB) key derivation on a
background isolate; hardware-backed Android Keystore wrapping of the derived key (RSA-2048 OAEP-SHA256,
`setUserAuthenticationRequired` + validity window + `setInvalidatedByBiometricEnrollment`); `FLAG_SECURE`
(blocks screenshots/recording, hides app in recents); attempt cooldown + lockout + stale-reset window;
auto-lock on background/inactivity; `allowBackup="false"`; route guard blocking the protected zone while
locked; repository **interfaces** + value-object **drafts** making ViewModels unit-testable.

---

## Priority shortlist

The highest-impact items if/when work resumes (rationale in each entry):

1. **UX-4** — No encrypted backup/export → permanent data loss if the device is lost (offline-first, no cloud).
2. **SEC-4** — Release APK is signed with **debug keys** and ships without R8/obfuscation (publication blocker).
3. **SEC-2** — Clipboard copies of secrets never auto-clear and aren't marked sensitive.
4. **ARCH-1** — Drift `watch` streams have no `onError`; the DB closing under them on auto-lock can throw.
5. **SEC-1** — Per-entry app-level encryption decision still open (defense-in-depth on top of SQLCipher).

---

## Summary table

| ID | Axis | Title | Severity | Effort | Status |
|----|------|-------|----------|--------|--------|
| SEC-1 | Security | App-level per-entry encryption undecided | Medium | L | Open |
| SEC-2 | Security | Clipboard: no auto-clear, not marked sensitive | Medium | S–M | Open |
| SEC-3 | Security | Secret input fields don't disable autocorrect/suggestions | Low–Med | S | Open |
| SEC-4 | Security | Release signed with debug keys; no R8/obfuscation | High | M | Open |
| SEC-5 | Security | Biometric auth not bound to Keystore op via CryptoObject | Low | M | Open |
| SEC-6 | Security | Derived key / secrets can't be wiped from memory (inherent) | Low | L | Open |
| PERF-1 | Performance | TOTP recomputed every second + one Timer per tile | Low–Med | M | Open |
| PERF-2 | Performance | `notifyInteraction()` on every `onPointerMove` | Low | S | Open |
| PERF-3 | Performance | `watch` queries re-read & re-map the whole joined table | Low | M | Open |
| ARCH-1 | Architecture | Drift `watch` streams lack `onError` (DB close on lock) | Medium | S–M | Open |
| ARCH-2 | Architecture | Dead / test-only surface in `HomeViewModel` | Low | S | Open |
| ARCH-3 | Architecture | `VaultRepository` rebuilt on every route build | Low | S | Open |
| ARCH-4 | Architecture | No end-to-end tests despite `integration_test` dep | Low–Med | M | Open |
| ARCH-5 | Architecture | `AGENTS.md` §13 / `INSTALL.md` partly stale | Low | S | Open |
| UX-1 | UI/UX | "Partage" placeholder occupies a primary nav slot | Low–Med | S | Open |
| UX-2 | UI/UX | No password generator | Medium | M | Open |
| UX-3 | UI/UX | Custom field "secret" flag unreachable from the form | Low–Med | S | Open |
| UX-4 | UI/UX | No encrypted backup/export (data-loss risk) | High | L | Open |
| UX-5 | UI/UX | Settings shown as "Bientôt disponible" (auto-lock, theme…) | Low–Med | M | Open |
| UX-6 | UI/UX | Search has no clear button; active on empty "Partage" tab | Low | S | Open |
| UX-7 | UI/UX | Accessibility: semantics, color-only cues, touch targets | Low–Med | M | Open |

---

## Security (SEC)

### SEC-1 — App-level per-entry encryption is still undecided
- **Status:** Open · **Severity:** Medium · **Effort:** L
- **Files:** `lib/core/database/models/credentials.dart`, `models/totps.dart`, `vault_repository.dart`; `AGENTS.md` §7
- **Finding:** `password`, `notes`, `uri`, custom-field values and the TOTP `secret` are stored as
  **plaintext columns inside the SQLCipher database**. The only encryption is SQLCipher at the DB level:
  once the vault is unlocked, every secret is in cleartext in the DB and in process memory. There is no
  second, app-level layer. `AGENTS.md` §7 already flags this as an open decision.
- **Direction:** Decide the threat model and scope explicitly. *Option A (defense-in-depth):* encrypt only
  the most sensitive columns (`password`, TOTP `secret`, secret custom fields) with the derived key via
  AES-GCM, decrypting only on demand (view/copy) to shrink the plaintext window. *Option B:* keep
  SQLCipher-only and document why. Confirm scope before implementing (per `AGENTS.md` §7). Pairs with **UX-4**.

### SEC-2 — Clipboard: no auto-clear and not marked sensitive
- **Status:** Open · **Severity:** Medium · **Effort:** S–M
- **Files:** `lib/features/home/views/credential_detail_page.dart` (`_copy`), `views/widgets/credential_form.dart` (`_CopyButton`), `views/widgets/totp_list_tile.dart` (`_copyCode`)
- **Finding:** copying a password / username / TOTP code / secret custom field uses `Clipboard.setData`
  with **no expiry** and **no Android 13+ sensitive flag**. Copied secrets persist in the system clipboard,
  are readable by other apps, and can surface in clipboard history / cross-device clipboard.
- **Direction:** auto-clear the clipboard after a short delay (e.g. 30–90 s) when the copied value was a
  secret; mark entries sensitive on Android 13+ (`ClipDescription.EXTRA_IS_SENSITIVE`, via a small platform
  call or a maintained package). Surface a countdown in the snackbar so the user knows it will clear.

### SEC-3 — Secret input fields don't disable autocorrect / suggestions
- **Status:** Open · **Severity:** Low–Medium · **Effort:** S
- **Files:** `lib/shared/widgets/password_form.dart`, `lib/features/home/views/widgets/credential_form.dart`, `views/widgets/totp_form.dart`
- **Finding:** master-password, credential-password, custom-field and TOTP-secret fields set `obscureText`
  but not `autocorrect: false` / `enableSuggestions: false`. On some keyboards, secrets can be learned by
  the dictionary or shown in the suggestion strip despite obscuring.
- **Direction:** set `autocorrect: false`, `enableSuggestions: false` (and `keyboardType: visiblePassword`
  where appropriate) on every secret field.

### SEC-4 — Release build signed with debug keys; no R8 / obfuscation
- **Status:** Open · **Severity:** High · **Effort:** M
- **Files:** `android/app/build.gradle.kts` (release `buildType`)
- **Finding:** `signingConfig = signingConfigs.getByName("debug")` (TODO in file) — a debug-signed APK can't
  be published to a store and weakens the trust chain. There is no `isMinifyEnabled` / `isShrinkResources`
  / ProGuard config, so the release ships **un-shrunk and un-obfuscated** (readable symbols, larger APK).
- **Direction:** create a real upload keystore + git-ignored `key.properties`, wire a proper release
  `signingConfig`; enable R8 (`isMinifyEnabled = true`, `isShrinkResources = true`) with keep rules for
  drift / sqlcipher / local_auth / the `secure_keystore` method channel. Release blocker before any publish.

### SEC-5 — Biometric auth not cryptographically bound to the Keystore op
- **Status:** Open · **Severity:** Low · **Effort:** M
- **Files:** `android/app/src/main/java/.../KeystoreKeyGuard.java`, `lib/core/security/biometric_storage_service.dart`
- **Finding:** the key uses time-window auth (`setUserAuthenticationValidityDurationSeconds(30)`); the app
  authenticates via `local_auth` and then unwraps within the window. The biometric prompt is **not** bound
  to the specific decrypt through a `BiometricPrompt.CryptoObject`, so within 30 s any unwrap call succeeds.
  Acceptable because the app controls all call sites, but it's the deprecated model.
- **Direction (optional hardening):** migrate to API 30+ `setUserAuthenticationParameters(0, AUTH_BIOMETRIC_STRONG)`
  with a `CryptoObject`-bound `BiometricPrompt`, so authentication gates the exact crypto operation. Low
  priority; current design is reasonable.

### SEC-6 — Secrets / derived key can't be reliably wiped from memory (inherent)
- **Status:** Open · **Severity:** Low · **Effort:** L
- **Files:** `lib/core/security/vault_service.dart` (`_currentKey`), key-derivation path
- **Finding:** the derived key lives in `_currentKey` (and inside SQLCipher), and passwords are Dart
  `String`s — immutable and GC-managed, so neither can be zeroed. Plaintext secrets remain in memory while
  unlocked. This is an inherent Dart/Flutter limitation, logged for completeness.
- **Direction:** minimise lifetime and number of copies; keep relying on `FLAG_SECURE` + auto-lock (already
  present). No clean full fix in pure Dart — likely **Won't do**, accept + document.

---

## Performance (PERF)

### PERF-1 — TOTP recomputed every second, one Timer per tile
- **Status:** Open · **Severity:** Low–Medium (scales with TOTP count) · **Effort:** M
- **Files:** `lib/features/home/views/widgets/totp_list_tile.dart`
- **Finding:** every `TotpListTile` runs its own `Timer.periodic(1 s)` and recomputes the HMAC code on each
  tick, even though the code only changes once per `period` (30 s). N visible tiles → N timers + N HMACs/s +
  N `setState`/s. Only the validity ring actually needs 1 s granularity.
- **Direction:** drive all rings from a single shared 1 s ticker; recompute the code only at period rollover.
  Removes ~97 % of the HMAC work and most rebuilds. Minor today (few TOTP), grows with the list.

### PERF-2 — `notifyInteraction()` fired on every `onPointerMove`
- **Status:** Open · **Severity:** Low · **Effort:** S
- **Files:** `lib/main.dart`
- **Finding:** the top-level `Listener` calls `appLockController.notifyInteraction()` on both `onPointerDown`
  and `onPointerMove`. During scroll/drag, `onPointerMove` fires very frequently; each call does
  `DateTime.now()` + a field write. Negligible CPU but needless churn.
- **Direction:** throttle (only update if >1 s since last) or drop `onPointerMove` and rely on `onPointerDown`
  + a scroll notification. Micro-optimisation.

### PERF-3 — `watch` queries re-read and re-map the whole joined table
- **Status:** Open · **Severity:** Low · **Effort:** M
- **Files:** `lib/core/database/vault_repository.dart` (`watchCredentialsWithProfiles`, `watchTotpsWithProfiles`)
- **Finding:** each watcher re-runs the full left-join and re-maps every row on any insert/update/delete —
  O(n) per change. Fine at the expected scale (tens–hundreds of entries); just noted for large-vault futures.
- **Direction:** acceptable now; if vaults grow large, paginate or scope queries. Monitor, low priority.

---

## Architecture / organisation (ARCH)

### ARCH-1 — Drift `watch` streams have no `onError` (DB closes on lock)
- **Status:** Open · **Severity:** Medium · **Effort:** S–M
- **Files:** `lib/shared/viewmodels/home_view_model.dart`, `lib/features/home/viewmodels/credential_detail_view_model.dart` (and the TOTP/profile detail VMs)
- **Finding:** ViewModels call `repository.watch…().listen((v){…})` with **no `onError`**. When auto-lock
  closes the DB (`VaultService.lockVault` → `_database.close()`) while a watcher is still active, the Drift
  stream can emit an error → unhandled async exception. The lock flow navigates to `/unlock` and disposes the
  pages, but there's a race window between "DB closed" and "page disposed".
- **Direction:** add `onError` to each `.listen(...)` (log/swallow — the lock flow already redirects), or
  cancel subscriptions before closing the DB, or have `VaultService` pause/close watchers first. Verify
  behavior by auto-locking while a list/detail screen is visible.

### ARCH-2 — Dead / test-only surface in `HomeViewModel`
- **Status:** Open · **Severity:** Low · **Effort:** S
- **Files:** `lib/shared/viewmodels/home_view_model.dart`, `test/shared/viewmodels/home_view_model_test.dart`
- **Finding:** `openAddBottomSheet` + the `_AddAction` enum are unused in `lib/` (the FAB uses the contextual
  `addCredential` / `addTotp`). `results` / `_results` is now consumed **only by tests** — `HomeTab` renders
  from `filteredCredentials` / `filteredTotps` / `filteredProfiles`. The "Home list mismatch" in `AGENTS.md`
  §13 is effectively resolved via the `filtered*` getters.
- **Direction:** remove `openAddBottomSheet` / `_AddAction`; drop `_results` and migrate its tests onto the
  `filtered*` getters; update `AGENTS.md` §13 (see **ARCH-5**).

### ARCH-3 — `VaultRepository` re-instantiated on every route build
- **Status:** Open · **Severity:** Low · **Effort:** S
- **Files:** `lib/core/routes/app_router.dart`
- **Finding:** route builders create `VaultRepository(_vaultService.db)` on every navigation. It's a thin
  wrapper over the singleton DB (no new connection, so it's cheap), but it couples routing to
  `_vaultService.db`, which **throws if the vault is locked** — safe only because the route guard blocks the
  protected zone. That coupling is load-bearing and implicit.
- **Direction:** acceptable as-is; optionally expose a single repository through the DI seam. Keep the route
  guard and `_vaultService.db`-in-builders invariant documented together so they don't drift apart.

### ARCH-4 — No end-to-end tests despite the `integration_test` dependency
- **Status:** Open · **Severity:** Low–Medium · **Effort:** M
- **Files:** `pubspec.yaml` (`integration_test`), `test/` (unit/widget only)
- **Finding:** `integration_test` is a dev dependency but there is no `integration_test/` suite. The critical
  native flows — SQLCipher open, migrations v1→v4, Keystore wrap/unwrap, biometrics, camera/QR — aren't
  exercised by `flutter test` (no native SQLCipher under the Dart VM), and nothing covers them on-device.
- **Direction:** add a minimal on-device `integration_test/` (unlock → add → read → lock), or formalise a
  manual on-device checklist. Complements the three-green gate, whose `flutter test` leg can't reach native paths.

### ARCH-5 — `AGENTS.md` §13 and `INSTALL.md` partly stale
- **Status:** Open · **Severity:** Low · **Effort:** S
- **Files:** `docs/AGENTS.md` §13, `docs/INSTALL.md`
- **Finding:** §13 still lists resolved gaps as open (home-list mismatch, "Partage" `RangeError`, empty
  add-stub actions). `INSTALL.md` says Flutter 3.35.7 while the project standard / CI is 3.38.9.
- **Direction:** refresh §13 to the current state; align `INSTALL.md` to 3.38.9. Pure documentation.

---

## UI / UX (UX)

### UX-1 — "Partage" placeholder occupies a primary navigation slot
- **Status:** Open · **Severity:** Low–Medium · **Effort:** S
- **Files:** `lib/shared/views/home/home_shell.dart`
- **Finding:** the bottom navigation has **Vault** + **Partage**, but "Partage" is a *coming soon* placeholder.
  The search bar also stays visible on that tab while doing nothing. Shipping a dead primary tab is a UX smell
  and burns a nav slot.
- **Direction:** hide the "Partage" tab until it exists (a single destination needs no bottom bar), or gate it
  behind a flag; hide search on tabs that have no list (see **UX-6**).

### UX-2 — No password generator
- **Status:** Open · **Severity:** Medium · **Effort:** M
- **Files:** `lib/features/home/views/widgets/credential_form.dart`
- **Finding:** the credential form has no "generate password" affordance. The app already computes strength
  but can't produce strong values — users must invent or paste them. A generator is a baseline expectation for
  a password manager and is fully local (no network), so it fits offline-first.
- **Direction:** add a generator (length slider; upper/lower/digit/symbol toggles; exclude-ambiguous option)
  reachable from the password field; fill the field and refresh the strength indicator. Use `Random.secure()`.

### UX-3 — Custom-field "secret" flag is unreachable from the form
- **Status:** Open · **Severity:** Low–Medium · **Effort:** S
- **Files:** `lib/features/home/views/widgets/credential_form.dart` (`_CustomFieldRow`, `_CustomFieldControllers`)
- **Finding:** the model and the read view fully support `CustomField.secret` (the value is obscured in
  read-only), but the **form never exposes a toggle**: new fields are always `secret: false` and editing can't
  change it. The capability exists but is dead from the UI.
- **Direction:** add a per-row "secret / masquer" toggle in `_CustomFieldRow`; obscure the value field while
  editing when it's marked secret.

### UX-4 — No encrypted backup / export (data-loss risk)
- **Status:** Open · **Severity:** High · **Effort:** L
- **Files:** `lib/features/settings/views/settings_page.dart`, `android/app/src/main/AndroidManifest.xml` (`allowBackup="false"`)
- **Finding:** offline-first + `allowBackup="false"` + no in-app export means a lost, reset or broken device =
  **permanent loss of every credential and TOTP**. Settings offers no export/import. This is the largest
  product-level risk in the app.
- **Direction:** add an **encrypted** export/import the user can store off-device (password-protected file:
  Argon2id + AEAD; never plaintext), with clear recovery docs. Security constraint cross-refs **SEC-1**: the
  export format must be strongly encrypted and independently openable.

### UX-5 — Several settings are "Bientôt disponible" placeholders
- **Status:** Open · **Severity:** Low–Medium · **Effort:** M (varies)
- **Files:** `lib/features/settings/views/settings_page.dart`, `lib/core/security/app_lock_controller.dart`, `lib/core/security/unlock_service.dart`
- **Finding:** the settings page shows disabled placeholders for **auto-lock delay**, periodic
  **master-password re-prompt**, **theme** and **language**. The auto-lock timeout in particular is a
  security-relevant control users expect — and the controller is *already parameterised*
  (`AppLockController.inactivityTimeout`), it just isn't wired to a persisted setting.
- **Direction:** prioritise wiring the **auto-lock delay** and the re-prompt interval to real, persisted
  settings (secure storage); defer theme/language. Remove placeholders you don't intend to ship soon.

### UX-6 — Search has no clear button and stays active on the empty "Partage" tab
- **Status:** Open · **Severity:** Low · **Effort:** S
- **Files:** `lib/shared/views/home/home_shell.dart`
- **Finding:** the AppBar search field has no clear (✕) affordance; the query persists across tabs and the
  field is shown on "Partage", which has nothing to search.
- **Direction:** add a clear button (suffix icon when the query is non-empty) that resets both the query and
  the controller; hide or disable search when the active tab has no list. Pairs with **UX-1**.

### UX-7 — Accessibility: semantics, color-only cues, touch targets
- **Status:** Open · **Severity:** Low–Medium · **Effort:** M
- **Files:** `lib/features/home/views/widgets/{vault_list_tile,totp_list_tile,credential_avatar,profile_avatar}.dart`, `lib/core/theme/app_theme.dart`
- **Finding:** icon-only actions mostly have tooltips (good — they provide semantics), but list rows and
  avatars lack explicit `Semantics` labels; the TOTP expiry is conveyed by **color only** (ring turns red in
  the last 5 s) with no non-color cue for color-blind users (the numeric countdown exists but isn't announced).
  Text scaling is respected (no `textScaler` override) and contrast is generally strong (yellow on near-black),
  but `secondaryText` (#B0B0B0) at 11–12 px for labels is borderline.
- **Direction:** add `Semantics` labels to list rows ("Identifiant X — profil Y", "Code TOTP de X, expire dans
  N s"); ensure the countdown is announced; verify ≥48 dp touch targets; run the Flutter accessibility scanner
  and bump borderline small-label contrast.

---

## Change log

| Date | Change |
|------|--------|
| 2026-06-22 | Initial register — 21 items (SEC ×6, PERF ×3, ARCH ×5, UX ×7). Nothing applied. |
