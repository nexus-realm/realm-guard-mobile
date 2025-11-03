import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
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
        backgroundColor: AppColors.secondaryBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.mainText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.mainText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.mainText),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
        bodySmall: TextStyle(color: AppColors.secondaryText),
        titleLarge: TextStyle(
          color: AppColors.mainText,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryButton,
          foregroundColor: AppColors.mainText,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.mainColor,
        foregroundColor: AppColors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mainColor),
        ),
      ),
    );
  }
}
