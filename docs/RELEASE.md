# Release & distribution runbook — Realm Guard Mobile

> How signed builds are produced and shipped. Android only. Keep in sync with
> `.github/workflows/*` and `android/app/build.gradle.kts`.

## Distribution channels

| Channel | Artifact | Where |
|---|---|---|
| **A — GitHub Release** | signed **APK** | GitHub Releases (direct download / sideload) |
| **B — Google Play** | signed **AAB** | Play Store: **closed testing** (beta) → **production** |

## Branch → track flow

Build the release candidate **once** on `staging`, ship it to beta, and when it's
validated **promote that same build** to production — no rebuild, so production
gets exactly the binary that was tested ("ship what you tested").

```
staging (push)                     promote (staging → main merge OR manual dispatch)
  │                                   │
  ├─ Channel A: GitHub pre-release ──▶├─ Channel A: GitHub full release (same APK)
  └─ Channel B: AAB → closed testing ─┴─ Channel B: promote closed testing → production
```

Branch shape: `feature → develop → staging → main`. `staging` = beta, `main` /
manual dispatch = production promotion. The prod step is **manually gated** (a
security app should never auto-ship to all users); a **staged rollout** (e.g. 20 %
first) is available on the production track.

## One-time setup

### 1. Upload keystore — required for signed builds (Channels A & B)

Generate an upload key (keep the `.jks` and passwords safe and backed up — losing
them means you can't ship updates unless enrolled in Play App Signing):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

**Local builds** — create `android/key.properties` (git-ignored, never commit):

```properties
storeFile=C:/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

**CI builds** — add these **GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Value |
|---|---|
| `RG_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (the keystore, base64-encoded) |
| `RG_STORE_PASSWORD` | keystore password |
| `RG_KEY_ALIAS` | key alias (e.g. `upload`) |
| `RG_KEY_PASSWORD` | key password |

The release workflow decodes the keystore into `android/app/` and exports the
`RG_*` env vars the Gradle build reads (see *Signing internals* below):

```yaml
- name: Decode keystore
  env: { RG_KEYSTORE_BASE64: ${{ secrets.RG_KEYSTORE_BASE64 }} }
  run: echo "$RG_KEYSTORE_BASE64" | base64 -d > android/app/upload-keystore.jks
# then build with:
#   RG_STORE_FILE=upload-keystore.jks   (relative to android/app)
#   RG_STORE_PASSWORD / RG_KEY_ALIAS / RG_KEY_PASSWORD from Secrets
```

### 2. Google Play — Channel B (OFF by default)

The Play channel is **disabled** until the repo variable `PLAY_ENABLED=true` is set.
Until then a `staging` release runs **Channel A (GitHub APK) only**, and the Play
jobs are **skipped** (green runs — no red failures). Enable it once the steps below
are done:

- Create the app in the **Play Console** and **enrol in Play App Signing** (Google
  holds the app-signing key; your keystore above is only the *upload* key).
- Create a **Google Cloud service account** with Play Console access (release
  manager), generate a JSON key → store as secret `PLAY_SERVICE_ACCOUNT_JSON`.
- **Upload the very first AAB manually** in the Console — build it locally with
  `flutter build appbundle --release` (signed with your upload keystore via
  `android/key.properties`). ⚠️ The **GitHub APK can't be reused**: a new app
  requires an **AAB**, and the Play Developer API (used by CI) can only publish
  once an initial release exists. Keep this first `versionCode` low (the default)
  so the CI's `git rev-list --count` numbers stay above it.
- Turn the channel on:
  `gh variable set PLAY_ENABLED --body true --repo nexus-realm/realm-guard-mobile`.

## Signing internals

`android/app/build.gradle.kts` resolves the release signing key in this order:

1. `android/key.properties` (local dev) —
2. `RG_STORE_FILE` / `RG_STORE_PASSWORD` / `RG_KEY_ALIAS` / `RG_KEY_PASSWORD` env (CI) —
3. **fallback: debug key**, so `flutter build apk --release` still works with no
   keystore configured. ⚠️ A debug-signed artifact is **not distributable** — never
   publish it to the Store or attach it to an official GitHub release.

R8 (shrinking + obfuscation) is **on** for release builds; keep rules live in
`android/app/proguard-rules.pro`.

## Versioning

`versionName` comes from `pubspec.yaml` `version` (bumped by
`conventional-changelog` on the `staging` cut). `versionCode` must strictly
increase for every Play upload; CI derives it from `git rev-list --count HEAD`
(monotonic, stable across workflow re-creation, and identical between channels A
and B for the same commit) and passes it via `flutter build … --build-number=<n>`.

## Operating the release (`.github/workflows/release.yml`)

One workflow drives **both** channels. The version is cut **once** in a shared
`prepare` job (Conventional Commits bump + tag), then two channel jobs build the
**same tag**, so the APK and AAB carry identical `versionName`/`versionCode`.
(A single workflow is required here: two parallel workflows can't share one
version bump without a race.)

### Cut a beta — merge into `staging`
- `prepare` bumps the version + changelog and tags `vX.Y.Z`.
- **Channel A** (`github-apk`): signed **universal APK** → GitHub **pre-release**
  `vX.Y.Z (beta)`.
- **Channel B** (`play-aab`): signed **AAB** → Play **closed testing** (`alpha`)
  via fastlane.

### Promote to production — merge `staging → main`, or run the workflow manually
`workflow_dispatch` inputs: `tag` (which release to promote; default = pubspec
version, or the latest pre-release) and `rollout` (Play staged rollout, e.g. `0.2`).
- **Channel A** (`promote-github`): flips the pre-release to a **full release** —
  same APK, no rebuild.
- **Channel B** (`promote-play`): promotes the closed-testing build to
  **production** (fastlane `track_promote_to`) — same AAB, no rebuild. A `rollout`
  fraction makes it a staged rollout.

### Notes
- **Channel toggle:** Channel A (GitHub) always runs; Channel B (Play) runs only
  when the repo variable `PLAY_ENABLED=true`. With it off, `play-aab`/`promote-play`
  are skipped (green) and `prepare` only requires `RG_KEYSTORE_BASE64`; with it on,
  `PLAY_SERVICE_ACCOUNT_JSON` becomes required too. `prepare` fails fast on a missing
  required secret **before** the bump (no tag/commit left behind).
- The GitHub APK is **universal** (all ABIs, ~85 MB) for one-tap sideloading; add
  `--split-per-abi` for smaller per-ABI files. Play/AAB delivers optimised sizes.
- fastlane lives in `android/` (`Gemfile`, `fastlane/Appfile`, `fastlane/Fastfile`).
  Run `bundle install` in `android/` once and commit `Gemfile.lock` for reproducible
  fastlane versions. Closed-testing track = `alpha` (override with `PLAY_BETA_TRACK`).
- ⚠️ `staging` must let the `GITHUB_TOKEN` push the `chore(release)` commit (don't
  require PR review for Actions on `staging`, or use a PAT).

## Implementation status

- [x] **B1** — signing foundation (`build.gradle.kts`, `proguard-rules.pro`)
- [x] **B2** — Channel A (GitHub Release + APK)
- [x] **B3** — Channel B (Play Store + AAB) — fastlane + `release.yml`

Both channels are wired in `.github/workflows/release.yml`. Before the first real
run: complete §1 (keystore + `RG_*` secrets) and §2 (Play App Signing, service
account, first manual AAB upload).
