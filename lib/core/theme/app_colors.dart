import 'package:flutter/material.dart';

class AppColors {
  // Base colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightYellow = Color(0xFFF4FF5C);
  static const Color darkYellow = Color(0xFFDAEE00);
  static const Color black = Color(0xFF0e0e0e);
  static const Color darkWhite = Color(0xFFF1F1F1);
  static const Color lightBlack = Color(0xFF1B1B1C);
  static const Color darkGrey = Color(0xFF1B1B1C);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color grey1 = Color(0xFF757575);
  static const Color grey2 = Color(0xFFB0B0B0);
  static const Color orange = Color(0xFFFF7B00);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF2196F3);
  static const Color darkRed = Color(0xFF93000A);
  static const Color lightRed = Color(0xFFFFB4AB);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF2E3300);

  // Dark theme specific
  static const Color mainBackground = black;
  static const Color secondaryBackground = lightBlack;
  static const Color mainText = darkWhite;
  static const Color secondaryText = grey2;
  static const Color buttonText = black;
  static const Color mainColor = darkYellow;
  static const Color secondaryColor = lightYellow;
  static const Color secondaryButton = orange;
  static const Color linkAction = white;
  static const Color error = lightRed;
  static const Color success = lightGreen;

  // --- Couleurs sémantiques d'action ---
  // Action destructive (supprimer, dissocier, reset…).
  static const Color destructive = lightRed;
  // Action positive / primaire (accent de l'app).
  static const Color primaryAction = mainColor;
  // Action neutre (icônes secondaires : copier, masquer…).
  static const Color neutralAction = grey2;
  // Surface légèrement teintée pour signaler une zone de danger.
  static const Color destructiveSurface = darkRed;
}
