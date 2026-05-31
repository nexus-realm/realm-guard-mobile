import 'package:flutter/material.dart';

import 'app_colors.dart';

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
        bodyLarge: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.mainText,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontBody,
          color: AppColors.secondaryText,
        ),
        bodySmall: TextStyle(fontFamily: _fontBody, color: AppColors.mainText),
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
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          side: const BorderSide(color: AppColors.mainColor),
          textStyle: const TextStyle(
            fontFamily: _fontBody,
            fontWeight: FontWeight.bold,
          ),
          shadowColor: AppColors.secondaryColor,
          elevation: 3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mainColor),
        ),
      ),
    );
  }
}
