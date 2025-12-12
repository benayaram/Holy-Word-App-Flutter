import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        tertiary: AppConstants.accentColor,
        background: AppConstants.backgroundColor,
        surface: AppConstants.backgroundColor,
        error: AppConstants.errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppConstants.textPrimaryColor,
        displayColor: AppConstants.textPrimaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      /* cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ), */
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryLightColor, // Lighter for dark mode
        secondary: AppConstants.secondaryLightColor,
        tertiary: AppConstants.accentColor,
        background: AppConstants.darkBackgroundColor,
        surface: const Color(0xFF374151), // Slightly lighter than background
        error: AppConstants.errorColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppConstants.darkBackgroundColor,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppConstants.textWhiteColor,
        displayColor: AppConstants.textWhiteColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.darkBackgroundColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      /* cardTheme: CardTheme(
        color: const Color(0xFF374151),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ), */
    );
  }
}
