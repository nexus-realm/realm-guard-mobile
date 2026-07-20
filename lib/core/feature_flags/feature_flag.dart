import 'package:flutter/material.dart';

/// Catalogue des fonctionnalités activables / désactivables par l'utilisateur,
/// pour adapter la complexité de l'interface à son usage.
///
/// **Point d'extension unique** : ajouter une fonctionnalité = ajouter une
/// entrée ici (clé de stockage, valeur par défaut, libellés). Le service et le
/// contrôleur la prennent en charge automatiquement, et l'écran des paramètres
/// l'affiche sans code supplémentaire (rendu générique sur `FeatureFlag.values`).
enum FeatureFlag {
  /// Gestion des codes TOTP (2FA) : onglet et écrans associés.
  totp(
    storageKey: 'feature_totp_enabled_v1',
    defaultEnabled: true,
    label: 'Gestion des TOTP',
    description:
        'Afficher l\'onglet et les écrans de codes à usage unique (2FA).',
    icon: Icons.timer_outlined,
  );

  const FeatureFlag({
    required this.storageKey,
    required this.defaultEnabled,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Clé de persistance dans le secure storage. Versionnée ; ne jamais la
  /// renommer ni la réutiliser pour une autre fonctionnalité.
  final String storageKey;

  /// État par défaut tant qu'aucune valeur n'est enregistrée. Mettre `true`
  /// pour qu'un utilisateur déjà installé conserve la fonctionnalité après une
  /// mise à jour.
  final bool defaultEnabled;

  /// Libellé court (titre dans les paramètres / l'onboarding).
  final String label;

  /// Description affichée sous le libellé.
  final String description;

  /// Icône représentant la fonctionnalité.
  final IconData icon;
}
