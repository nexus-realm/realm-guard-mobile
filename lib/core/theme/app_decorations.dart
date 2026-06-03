import 'package:flutter/widgets.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Effets de profondeur centralisés (ombres, glow), volontairement **subtils**
/// pour rester lisibles sur le fond très sombre.
abstract final class AppDecorations {
  /// Ombre douce pour décoller une carte du fond (décollement discret).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Décoration d'une carte « surface » avec coins arrondis + ombre douce.
  static BoxDecoration surfaceCard({Color? color}) => BoxDecoration(
    color: color ?? AppColors.secondaryBackground,
    borderRadius: AppRadius.mdAll,
    boxShadow: cardShadow,
  );

  /// Glow néon doux (accent jaune) — réservé aux éléments mis en avant
  /// (favori, sélection). À utiliser ponctuellement.
  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.mainColor.withValues(alpha: 0.45),
      blurRadius: 8,
      spreadRadius: 0.5,
    ),
  ];
}
