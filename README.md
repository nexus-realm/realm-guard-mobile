# Realm Guard

Gestionnaire de mots de passe **local-first** pour Android. Toutes les données
sont stockées localement dans une base chiffrée et l'application est **pleinement
utilisable hors ligne, sans compte**. Une **synchronisation multi-appareils
chiffrée de bout en bout** (zero-knowledge) est disponible **en option**. Le
projet privilégie la **sécurité** avant tout, puis une **interface simple**
adaptée à l'usage de chacun.

## Fonctionnalités

- **Coffre chiffré** — base SQLCipher chiffrée par une clé de coffre, elle-même
  protégée par le mot de passe maître (Argon2id).
- **Déverrouillage** par biométrie (empreinte / visage) ou mot de passe maître,
  avec temporisation et verrouillage après plusieurs échecs.
- **Identifiants** — titre, nom d'utilisateur, mot de passe, URL, notes, champs
  personnalisés et favoris, avec indicateur de force du mot de passe.
- **Profils** — regrouper des identifiants et consulter les éléments liés.
- **TOTP (2FA)** — génération de codes à usage unique (RFC 6238), ajout manuel
  ou par scan de QR code ; fonctionnalité activable ou non.
- **Synchronisation multi-appareils (en option)** — chiffrée de bout en bout et
  **zero-knowledge** : le serveur ne voit jamais vos données en clair. Création
  d'un compte (protocole OPAQUE), **appairage d'appareils** par QR code + code de
  vérification, mise à jour en temps réel, et récupération depuis une sauvegarde
  chiffrée. L'app reste 100 % fonctionnelle sans jamais créer de compte.
- **Remplissage automatique système** — proposer et enregistrer les identifiants
  dans les autres applications et navigateurs (Android Autofill).
- **Verrouillage automatique** (arrière-plan / inactivité), changement du mot de
  passe maître, suppression complète des données.

## Sécurité

- Dérivation de clé **Argon2id** (64 Mo, 3 itérations) protégeant une **clé de
  coffre** aléatoire, qui chiffre l'intégralité de la base via **SQLCipher**.
- La clé de déverrouillage rapide (biométrie) est protégée par une clé matérielle
  de l'**Android Keystore** ; elle n'est jamais stockée en clair.
- Synchronisation **chiffrée de bout en bout** : authentification **OPAQUE**
  (le mot de passe du compte ne quitte jamais l'appareil), appairage vérifié par
  **SAS** à 6 chiffres, deltas chiffrés côté client. Le serveur est
  **zero-knowledge**. Le mot de passe du compte est **distinct** du mot de passe
  maître.
- `FLAG_SECURE` (captures d'écran bloquées, contenu masqué dans le multitâche),
  temporisation et verrouillage des tentatives, effacement total des données.
- **Aucune cryptographie maison** : primitives issues de bibliothèques auditées et
  d'un cœur Rust partagé (`realm-guard-core`).

Le modèle de sécurité détaillé est décrit dans [`docs/AGENTS.md`](docs/AGENTS.md).

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.44.4 (canal stable) · Dart |
| Plateforme | Android uniquement · minSdk 29 (Android 10) |
| Base de données | `drift` sur SQLCipher (`sqlcipher_flutter_libs`) |
| Cryptographie | `cryptography` (Argon2id) **+ cœur Rust** via `flutter_rust_bridge` |
| Cœur partagé | `realm-guard-core` (CRDT + crypto E2EE) consommé en FFI |
| Réseau (sync) | `http` (REST) + WebSocket (`dart:io`) pour les notifications temps réel |
| Stockage sécurisé | `flutter_secure_storage` · Android Keystore |
| Biométrie | `local_auth` |
| Navigation | `go_router` |
| Autofill / QR | `flutter_autofill_service` · `mobile_scanner` · `qr_flutter` |

Architecture **feature-first + MVVM** (`ChangeNotifier`), injection de
dépendances manuelle, thème sombre uniquement. La synchronisation s'appuie sur
un serveur externe ([`realm-guard-server`](https://github.com/nexus-realm/realm-guard-server))
et le cœur partagé ([`realm-guard-core`](https://github.com/nexus-realm/realm-guard-core)).

## Démarrage

Prérequis : Flutter 3.44.4, une **toolchain Rust** (le cœur est compilé en natif),
et un appareil ou émulateur **Android 10+**. L'installation complète (Windows) est
décrite dans [`docs/INSTALL.md`](docs/INSTALL.md).

```bash
flutter pub get   # dépendances Flutter
npm install       # hooks husky / commitlint
flutter run       # lancer sur un appareil Android (compile aussi le cœur Rust)
```

> La synchronisation nécessite en plus le serveur (Postgres + Redis + Axum) —
> voir [`realm-guard-server`](https://github.com/nexus-realm/realm-guard-server).
> Sans lui, l'app fonctionne normalement en mode local.

## Développement

```bash
flutter analyze                                           # analyse statique (gate CI)
flutter test                                              # tests unitaires et widget (gate CI)
dart format lib test                                      # formatage (gate CI séparé)
flutter build apk --debug                                 # build de vérification
dart run build_runner build --delete-conflicting-outputs  # régénérer le code Drift (*.g.dart)
flutter_rust_bridge_codegen generate                     # régénérer les bindings FFI
```

- **Définition de « terminé »** : `dart format`, `flutter analyze` propre,
  `flutter test` au vert et build APK.
- **Ne jamais éditer** les fichiers générés (`*.g.dart`, `lib/src/rust/`) : les
  régénérer.
- Chaînes destinées à l'utilisateur en **français**, identifiants de code en
  anglais.

## Structure

```
lib/
  core/        # infrastructure transverse (database, security, sync, routes, theme)
  features/    # onboarding, unlock, home, settings, auth, pairing, sync, autofill, debug
  shared/      # widgets, notifiers et vues réutilisables
  src/rust/    # bindings FFI générés (ne pas éditer)
```

## Conventions

- **GitFlow** : `feature|fix|chore/rg-<N>` → `develop` → `staging` → `main`.
- **Conventional Commits**, vérifiés par husky / commitlint.

## Documentation

- [`docs/AGENTS.md`](docs/AGENTS.md) — contexte technique détaillé (source de vérité).
- [`docs/INSTALL.md`](docs/INSTALL.md) — installation de l'environnement.
- [`docs/RELEASE.md`](docs/RELEASE.md) — build signé et distribution (GitHub / Play).
- [`docs/SYNC_MAPPING.md`](docs/SYNC_MAPPING.md) — format de synchronisation (durable).
- [`docs/IMPROVEMENTS.md`](docs/IMPROVEMENTS.md) — pistes d'amélioration suivies.
