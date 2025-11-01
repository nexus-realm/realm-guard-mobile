# INSTALL

Ce document décrit les prérequis et les étapes pour mettre en place l'environnement de développement de `realm_guard_mobile` sous Windows.

## Prérequis (Windows)

- Windows 10/11
- Git
- Flutter SDK 3.35.7
- Dart (inclus avec Flutter)
- Android Studio (2025.2.1 ou plus recommandé) avec :
    - Android SDK Tools, Platform tools
    - au moins une Android SDK Platform (API 31+)
    - Android SDK Build-Tools
    - Android Emulator (si vous utilisez un AVD)
- JDK 11 ou + (Java 11)
- Node.js (LTS) et npm (pour les outils front / scripts présents dans `package.json`)
- Espace disque et RAM suffisants pour les émulateurs Android

## Variables d'environnement (exemples Windows)

Adapter les chemins à votre installation.
Il faut que la variable `JAVA_HOME` pointe vers le répertoire racine du JDK,
et que `ANDROID_SDK_ROOT` pointe vers le répertoire racine du SDK Android.
Dans `PATH`, ajouter le répertoire `bin` de Flutter.

## Installation de l'environnement
1. Cloner le dépôt :
   ```bash
   git clone https://github.com/nexus-realm/realm-guard-mobile.git
   cd realm-guard-mobile
   git checkout develop # Recommandé pour un développeur
    ```
2. Installer les dépendances Flutter :
   ```bash
   flutter pub get
    ```

3. Installer les dépendances Node.js (pour husky):
   ```bash
   npm install
    ```
