import 'package:flutter/material.dart';

class CrushTheme {
  static const _primary = Colors.pinkAccent;
  static const _secondary = Colors.deepPurpleAccent;

  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: _primary,
      colorScheme: base.colorScheme.copyWith(
        primary: _primary,
        secondary: _secondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: _primary,
      colorScheme: base.colorScheme.copyWith(
        primary: _primary,
        secondary: _secondary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
