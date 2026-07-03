# Realm Guard

Gestionnaire de mots de passe **offline-first** pour Android. Toutes les données
sont stockées localement dans une base chiffrée : aucun serveur, aucune
synchronisation réseau. Le projet privilégie la **sécurité** avant tout, puis une
**interface simple** adaptée à l'usage de chacun.

## Fonctionnalités

- **Coffre chiffré** — base SQLCipher dont la clé est dérivée du mot de passe
  maître (Argon2id).
- **Déverrouillage** par biométrie (empreinte / visage) ou mot de passe maître,
  avec temporisation et verrouillage après plusieurs échecs.
- **Identifiants** — titre, nom d'utilisateur, mot de passe, URL, notes, champs
  personnalisés et favoris, avec indicateur de force du mot de passe.
- **Profils** — regrouper des identifiants et consulter les éléments liés.
- **TOTP (2FA)** — génération de codes à usage unique (RFC 6238), ajout manuel
  ou par scan de QR code ; fonctionnalité activable ou non.
- **Remplissage automatique système** — proposer et enregistrer les identifiants
  dans les autres applications et navigateurs (Android Autofill).
- **Verrouillage automatique** (arrière-plan / inactivité), changement du mot de
  passe maître, suppression complète des données.
- **100 % hors ligne** — aucune requête réseau (avatars et force du mot de passe
  calculés localement).

## Sécurité

- Dérivation de clé **Argon2id** (64 Mo, 3 itérations) puis chiffrement
  **SQLCipher** de l'intégralité de la base.
- La clé de déverrouillage rapide (biométrie) est protégée par une clé
  matérielle de l'**Android Keystore** liée à l'authentification ; elle n'est
  jamais stockée en clair.
- `FLAG_SECURE` (captures d'écran bloquées, contenu masqué dans le multitâche),
  temporisation et verrouillage des tentatives, effacement total des données.

Le modèle de sécurité détaillé est décrit dans [`docs/AGENTS.md`](docs/AGENTS.md).

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.44.4 (canal stable) · Dart |
| Plateforme | Android uniquement · minSdk 29 (Android 10) |
| Base de données | `drift` sur SQLCipher (`sqlcipher_flutter_libs`) |
| Cryptographie | `cryptography` (Argon2id, HMAC) |
| Stockage sécurisé | `flutter_secure_storage` · Android Keystore |
| Biométrie | `local_auth` |
| Navigation | `go_router` |
| Autofill / QR | `flutter_autofill_service` · `mobile_scanner` |

Architecture **feature-first + MVVM** (`ChangeNotifier`), injection de
dépendances manuelle, thème sombre uniquement.

## Démarrage

Prérequis : Flutter 3.44.4 et un appareil ou émulateur **Android 10+**.
L'installation complète de l'environnement (Windows) est décrite dans
[`docs/INSTALL.md`](docs/INSTALL.md).

```bash
flutter pub get   # dépendances Flutter
npm install       # hooks husky / commitlint
flutter run       # lancer sur un appareil Android
```

## Développement

```bash
flutter analyze                                           # analyse statique (gate CI)
flutter test                                              # tests unitaires et widget (gate CI)
flutter build apk --debug                                 # build de vérification
dart run build_runner build --delete-conflicting-outputs  # régénérer le code Drift (*.g.dart)
```

- **Définition de « terminé »** : `flutter analyze` propre et `flutter test` au
  vert (build APK en complément).
- **Ne jamais éditer** les fichiers générés (`*.g.dart`) : les régénérer.
- Chaînes destinées à l'utilisateur en **français**, identifiants de code en
  anglais.

## Structure

```
lib/
  core/        # infrastructure transverse (database, security, routes, theme)
  features/    # onboarding, unlock, home, settings, autofill, debug
  shared/      # widgets, notifiers et vues réutilisables
```

## Conventions

- **GitFlow** : `feature|fix|chore/rg-<N>` → `develop`, puis `develop` → `main`.
- **Conventional Commits**, vérifiés par husky / commitlint.

## Documentation

- [`docs/AGENTS.md`](docs/AGENTS.md) — contexte technique détaillé (source de vérité).
- [`docs/INSTALL.md`](docs/INSTALL.md) — installation de l'environnement.
- [`docs/IMPROVEMENTS.md`](docs/IMPROVEMENTS.md) — pistes d'amélioration suivies.
