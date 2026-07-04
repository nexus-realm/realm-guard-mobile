import 'package:flutter/material.dart';

/// Palette fixe de couleurs proposées pour les profils. Stockées en `int`
/// (valeur ARGB) dans la base. Une palette fermée garantit une cohérence
/// visuelle (pas de sélecteur libre).
abstract final class ProfileColors {
  static const List<Color> palette = [
    Color(0xFFE57373), // rouge
    Color(0xFFFFB74D), // orange
    Color(0xFFFFD54F), // jaune
    Color(0xFF81C784), // vert
    Color(0xFF4DD0E1), // cyan
    Color(0xFF64B5F6), // bleu
    Color(0xFF9575CD), // violet
    Color(0xFFF06292), // rose
    Color(0xFFA1887F), // brun
    Color(0xFF90A4AE), // gris-bleu
  ];

  /// Retourne la [Color] correspondant à une valeur stockée, ou `null`.
  static Color? fromValue(int? value) => value == null ? null : Color(value);
}
