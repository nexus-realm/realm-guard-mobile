# Mise à jour des dépendances — realm-guard-mobile

Deux voies : **Dependabot** (automatique) pour le gros, une **procédure manuelle**
pour ce qui est couplé ou délibéré.

## Automatique — Dependabot (`.github/dependabot.yml`)

- **Alertes de sécurité** (CVE) : activer une fois dans *Settings → Code security →
  Dependabot alerts* **+** *Dependabot security updates*.
- **PR de version** — **mensuelles**, **groupées** minor+patch par écosystème
  (majors en PR séparées) pour `pub`, `npm`, `github-actions`. Elles ciblent
  `develop` depuis des branches `dependabot/*` (autorisées par `check-branches`).
- **Prérequis secret** : ajouter `CORE_REPO_DEPLOY_KEY` dans *Settings → Secrets and
  variables → **Dependabot*** (store **distinct** des secrets Actions). La CI
  construit l'APK, qui compile le cœur **privé** ; sans ce secret les PR Dependabot
  échouent au build.

## Manuel — ce que Dependabot ne gère pas

| Quoi | Pourquoi | Comment |
|---|---|---|
| Crate `rust/` (`flutter_rust_bridge`) | doit rester aligné avec le paquet **Dart** `flutter_rust_bridge` (runtime ⇄ codegen) | bumper **les deux** ensemble puis `flutter_rust_bridge_codegen generate` |
| **Pin du cœur** (`rust/Cargo.toml` `tag=vX`) | geste de release délibéré (coordination inter-repos) | changer le tag + `cargo update -p realm-guard-core` dans `rust/` + committer `Cargo.lock` |
| **SDK Flutter** (3.44.4) | non modélisé comme dépendance ; doit matcher la CI | bumper dans `.github/workflows/*` **et** localement, re-tester |

Voir l'état :

```bash
flutter pub outdated        # deps Dart / Flutter
npm outdated                # husky / commitlint
```

## Avant de merger (toute PR de deps)

Le gate habituel doit être **vert** :

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Pour une mise à jour **manuelle**, créer une branche `chore/rg-<N>` (Dependabot,
lui, utilise `dependabot/*`, déjà autorisé). Cadence : passer en revue les PR
Dependabot **une fois par mois** ; appliquer les majors séparément après lecture
des changelogs.
