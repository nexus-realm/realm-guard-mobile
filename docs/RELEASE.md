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

### 2. Google Play — required for Channel B (set up before B3 is used)

- Create the app in the **Play Console** and **enrol in Play App Signing** (Google
  holds the app-signing key; your keystore above is only the *upload* key).
- Create a **Google Cloud service account** with Play Console access (release
  manager), generate a JSON key → store as secret `PLAY_SERVICE_ACCOUNT_JSON`.
- **Upload the very first AAB manually** in the Console. The Play Developer API
  (used by CI) can only publish once the app already has an initial release.

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
`conventional-changelog`). `versionCode` must strictly increase for every Play
upload; CI passes it via `flutter build … --build-number=<n>`.

## Implementation status

- [x] **B1** — signing foundation (this file, `build.gradle.kts`, `proguard-rules.pro`)
- [ ] **B2** — Channel A workflow (GitHub Release + APK)
- [ ] **B3** — Channel B workflow (Play Store + AAB)
