import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTheme {
  AppTheme._();

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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mainBackground,
        surfaceTintColor: AppColors.mainBackground,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          textStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.mainText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.mainBackground,
        selectedItemColor: AppColors.mainColor,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.mainColor)),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.secondaryText)),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.mainText)),
        bodyMedium: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.secondaryText)),
        bodySmall: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.mainText)),
        labelLarge: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(color: AppColors.mainText, fontSize: 16)),
        titleLarge: GoogleFonts.spaceGrotesk(
          textStyle: const TextStyle(
            color: AppColors.mainText,
            fontWeight: FontWeight.bold,
            height: 1.25,
            fontSize: 42,
          ),
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          textStyle: const TextStyle(
            color: AppColors.mainColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          textStyle: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          shadowColor: AppColors.secondaryColor,
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.mainBackground,
          foregroundColor: AppColors.mainText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          side: const BorderSide(color: AppColors.mainColor),
          textStyle: GoogleFonts.plusJakartaSans(textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          shadowColor: AppColors.secondaryColor,
          elevation: 3,
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
