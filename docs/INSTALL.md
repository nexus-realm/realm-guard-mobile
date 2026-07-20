# INSTALL

Ce document décrit les prérequis et les étapes pour mettre en place
l'environnement de développement de `realmguard` sous Windows.

## Prérequis (Windows)

- Windows 10/11
- Git
- **Flutter SDK 3.44.4** (canal stable — doit correspondre à la CI)
- Dart (inclus avec Flutter)
- Android Studio (2025.2.1 ou plus recommandé) avec :
    - Android SDK Tools, Platform tools
    - au moins une Android SDK Platform (**API 29+**, l'app cible minSdk 29)
    - Android SDK Build-Tools
    - **Android NDK** (nécessaire pour compiler le cœur Rust — installable via
      *SDK Manager → SDK Tools → NDK (Side by side)*)
    - Android Emulator (si vous utilisez un AVD)
- JDK 17 (fourni avec Android Studio ; `JAVA_HOME` doit pointer dessus)
- **Toolchain Rust** (le cœur `realm-guard-core` est compilé en natif et lié en
  FFI) — voir la section dédiée ci-dessous.
- Node.js (LTS) et npm (hooks husky / commitlint de `package.json`)
- Espace disque et RAM suffisants pour les émulateurs Android

## Variables d'environnement (exemples Windows)

Adapter les chemins à votre installation :

- `JAVA_HOME` → répertoire racine du JDK.
- `ANDROID_SDK_ROOT` (ou `ANDROID_HOME`) → répertoire racine du SDK Android.
- Ajouter dans `PATH` : le répertoire `bin` de Flutter, `~/.cargo/bin` (Rust),
  et les outils de plateforme Android.

## Toolchain Rust (cœur natif)

Le build Android compile automatiquement `realm-guard-core` via **cargokit** ;
il faut donc Rust et les cibles Android installées **une fois** :

```bash
# 1. Installer rustup (https://rustup.rs) puis les cibles Android :
rustup target add aarch64-linux-android armv7-linux-androideabi \
                  x86_64-linux-android i686-linux-android
```

- Le cœur est épinglé dans `rust/Cargo.toml` (dépendance git sur
  `realm-guard-core`). Après la fusion d'un nouveau symbole du cœur, exécuter
  `cargo update -p realm-guard-core` dans `rust/` et committer le `Cargo.lock`.
- Régénérer les bindings FFI (seulement après un changement de signature du
  cœur) : `cargo install flutter_rust_bridge_codegen` puis
  `flutter_rust_bridge_codegen generate`. Ne **jamais** éditer `lib/src/rust/` à
  la main.

## Installation de l'environnement

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/nexus-realm/realm-guard-mobile.git
   cd realm-guard-mobile
   git checkout develop   # recommandé pour un développeur
   ```
2. Installer les dépendances Flutter :
   ```bash
   flutter pub get
   ```
3. Installer les dépendances Node.js (hooks husky) :
   ```bash
   npm install
   ```
4. Vérifier l'environnement :
   ```bash
   flutter doctor           # doit être vert (Android toolchain, NDK, etc.)
   flutter run              # premier build : compile aussi le cœur Rust (plus long)
   ```

## Serveur de synchronisation (optionnel)

La synchronisation multi-appareils nécessite le serveur
([`realm-guard-server`](https://github.com/nexus-realm/realm-guard-server) :
Postgres + Redis + Axum). **Sans lui, l'application fonctionne normalement en
mode local** — inutile pour développer les fonctionnalités hors ligne.

Pour développer la sync : lancer la stack `docker-compose` du dépôt serveur, puis
laisser l'app pointer sur `ServerConfig.dev()` (depuis un émulateur Android,
l'hôte est `10.0.2.2:8080`). Détails dans le dépôt serveur.

## Dépannage

- **Le build Android échoue sur la compilation Rust** → vérifier `rustc`/`cargo`
  dans le `PATH`, les cibles Android (`rustup target list --installed`) et
  l'installation du NDK (`flutter doctor`).
- **Version de Flutter** : le projet est figé sur **3.44.4** (CI + release). Une
  autre version peut faire diverger l'analyse ou le build — utiliser `fvm` ou
  aligner la version installée.
