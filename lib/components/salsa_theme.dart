import 'package:flutter/material.dart';

class SalsaTheme {
  // 🌞 Light Mode
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFD2E3ED),
      primaryColor: const Color(0xFF4DA5F0),
      primaryColorLight: const Color(0xFFB7DBF6),
      primaryColorDark: const Color(0xFF007ACC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4DA5F0),
        onPrimary: Colors.white,
        secondary: Color(0xFFB7DBF6),
        surface: Color(0xFFEAF4FB),
        onSurface: Color(0xFF222831),
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4DA5F0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007ACC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      inputDecorationTheme: _lightInputTheme(),
      textTheme: _baseTextTheme(const Color(0xFF222831), const Color(0xFFAAB6C3)),
    );
  }

  // 🌙 Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121D26), // abu gelap kebiruan
      primaryColor: const Color(0xFF4DA5F0),
      primaryColorLight: const Color(0xFF8ECFFF),
      primaryColorDark: const Color(0xFF0062A3),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4DA5F0),
        onPrimary: Colors.white,
        secondary: Color(0xFF8ECFFF),
        surface: Color(0xFF121D26),
        onSurface: Colors.white,
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2A38),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007ACC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      inputDecorationTheme: _darkInputTheme(),
      textTheme: _baseTextTheme(Colors.white, const Color(0xFFB0BEC5)),
    );
  }

  static InputDecorationTheme _lightInputTheme() => InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFD9E8F3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFD9E8F3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF4DA5F0), width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFFAAB6C3)),
    labelStyle: const TextStyle(color: Color(0xFF222831)),
  );

  static InputDecorationTheme _darkInputTheme() => InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E2E3A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF37474F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF37474F)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF4DA5F0), width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
    labelStyle: const TextStyle(color: Colors.white),
  );

  static TextTheme _baseTextTheme(Color primaryColor, Color hintColor) => TextTheme(
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
    bodyLarge: TextStyle(fontSize: 16, color: primaryColor),
    bodyMedium: TextStyle(fontSize: 14, color: primaryColor),
    bodySmall: TextStyle(fontSize: 12, color: hintColor),
  );
}
