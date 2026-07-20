import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  AppTheme._();

  // Polices embarquées (assets/fonts), déclarées dans pubspec `fonts:`.
  // Résolution native par Flutter : aucun téléchargement réseau (offline-first).
  static const String _fontBody = 'Plus Jakarta Sans';
  static const String _fontTitle = 'Space Grotesk';

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBackground,
      primaryColor: AppColors.mainColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mainColor,
        secondary: AppColors.secondaryColor,
        error: AppColors.error,
        surface: AppColors.secondaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mainBackground,
        surfaceTintColor: AppColors.mainBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.mainText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.mainBackground,
        selectedItemColor: AppColors.mainColor,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.mainColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
        ),
      ),
      textTheme: const TextTheme(
        // Valeur principale (ex. contenu d'un champ) : claire, lisible.
        bodyLarge: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.mainText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        // Texte courant secondaire.
        bodyMedium: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 14,
          height: 1.35,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 12,
        ),
        // Libellé de champ : petit, gris, espacé — contraste avec la valeur.
        labelMedium: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.mainText,
          fontSize: 16,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontTitle,
          color: AppColors.mainText,
          fontWeight: FontWeight.bold,
          height: 1.25,
          fontSize: 42,
        ),
        titleSmall: TextStyle(
          fontFamily: _fontTitle,
          color: AppColors.mainColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.25,
        ),
        // Titre de section (cartes de réglages, en-têtes de groupe).
        titleMedium: TextStyle(
          fontFamily: _fontTitle,
          color: AppColors.mainText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(
            fontFamily: _fontBody,
            fontWeight: FontWeight.bold,
          ),
          shadowColor: AppColors.secondaryColor,
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.mainBackground,
          foregroundColor: AppColors.mainText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: const BorderSide(color: AppColors.mainColor),
          textStyle: const TextStyle(
            fontFamily: _fontBody,
            fontWeight: FontWeight.bold,
          ),
          shadowColor: AppColors.secondaryColor,
          elevation: 3,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        hintStyle: TextStyle(color: AppColors.secondaryText),
        labelStyle: TextStyle(color: AppColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.mainColor),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        // Description (sous-titre) volontairement plus discrète que le libellé :
        // couleur secondaire et taille légèrement réduite pour la hiérarchie.
        subtitleTextStyle: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }
}
