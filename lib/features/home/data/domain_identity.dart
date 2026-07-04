import 'package:flutter/material.dart';

import 'profile_colors.dart';

/// Identité visuelle d'un identifiant dérivée **localement** de son URL (ou, à
/// défaut, de son titre) : une initiale + une couleur déterministe.
///
/// Aucun accès réseau : on ne récupère pas de favicon (ce qui trahirait
/// l'offline-first et fuiterait les sites stockés). La couleur est calculée par
/// hachage du domaine pour rester stable d'une session à l'autre.
class DomainIdentity {
  const DomainIdentity({required this.initial, required this.color});

  final String initial;
  final Color color;

  /// Construit l'identité à partir de l'URL puis du titre en repli.
  factory DomainIdentity.from({String? uri, String? title}) {
    final domain = extractDomain(uri);
    final source = domain ?? (title ?? '').trim();
    final initial = source.isNotEmpty ? source[0].toUpperCase() : '?';
    return DomainIdentity(initial: initial, color: _colorFor(source));
  }

  /// Extrait le domaine « nu » d'une URL : retire le schéma, `www.`, le chemin
  /// et le port. Retourne `null` si rien d'exploitable.
  static String? extractDomain(String? uri) {
    if (uri == null) return null;
    var value = uri.trim().toLowerCase();
    if (value.isEmpty) return null;

    // Retire le schéma.
    final schemeIndex = value.indexOf('://');
    if (schemeIndex != -1) value = value.substring(schemeIndex + 3);

    // Coupe au premier /, ? ou #.
    value = value.split(RegExp(r'[/?#]')).first;

    // Retire le port et le préfixe www.
    value = value.split(':').first;
    if (value.startsWith('www.')) value = value.substring(4);

    return value.isEmpty ? null : value;
  }

  /// Couleur déterministe issue de la palette, par hachage stable de [source].
  static Color _colorFor(String source) {
    if (source.isEmpty) return ProfileColors.palette.first;
    var hash = 0;
    for (final unit in source.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return ProfileColors.palette[hash % ProfileColors.palette.length];
  }
}
