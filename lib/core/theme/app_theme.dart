import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color primaryGreen = Color(0xFF1A6B3A);
  static const Color darkGreen = Color(0xFF0F4023);
  static const Color lightGreen = Color(0xFF2E8B57);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundCream = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF4A4A6A);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF1565C0);
  static const Color purple = Color(0xFF6A1B9A);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Nastaleeq',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 2.0,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Noto',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Noto',
    fontSize: 15,
    color: textMedium,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Noto',
    fontSize: 12,
    color: textGrey,
    height: 1.5,
  );

  static const TextStyle price = TextStyle(
    fontFamily: 'Noto',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: primaryGreen,
    height: 1.3,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        surface: backgroundWhite,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      fontFamily: 'Noto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Noto',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Noto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: textGrey,
          fontSize: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
