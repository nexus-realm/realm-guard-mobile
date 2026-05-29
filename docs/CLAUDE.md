# CLAUDE.md

Full project context lives in `AGENTS.md` (single source of truth). Import it:

@AGENTS.md

> Note: this file is in `docs/`, so Claude Code does **not** auto-load it. To have it loaded automatically, add a `CLAUDE.md` at the repo root containing `@docs/AGENTS.md`, or run Claude Code from a context that references this file.

## Operating rules for this repo

- **Never hand-edit** `lib/core/database/app_database.g.dart`. After changing a Drift table or `app_database.dart`, run `dart run build_runner build --delete-conflicting-outputs`.
- **Definition of done**: `flutter analyze` is clean and `flutter test` passes. When touching `lib/core/security/*`, also run `flutter test test/core/security/`.
- **Security is the product.** Don't weaken the unlock/derivation chain (Argon2id → SQLCipher), the lockout/cooldown policy, or the Android SQLCipher override in `main.dart`. Use `SecurityException` for security-critical errors.
- **User-facing strings are French.** Route colors/styles through `AppColors` / `AppTheme` (dark theme only).
- **MVVM, manual DI**: ViewModels extend `ChangeNotifier`; long-lived services are top-level `final`s in `core/routes/app_router.dart`. Imports are relative.
- **Commits**: Conventional Commits (husky `commit-msg` runs commitlint). Branches: `feature|fix|chore/rg-<N>` → `develop`.
- Before assuming a feature exists, check §13 of `AGENTS.md` (known gaps) — several home/vault flows are still stubs.
