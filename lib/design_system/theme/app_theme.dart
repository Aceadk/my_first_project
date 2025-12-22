import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../tokens/elevation.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromARGB(255, 230, 56, 114),
      onPrimary: Colors.white,
      secondary: Color.fromARGB(255, 103, 60, 220),
      onSecondary: Color.fromARGB(237, 255, 255, 255),
      surface: Color.fromARGB(243, 255, 255, 255),
      onSurface: DsColors.textPrimaryLight,
      error: DsColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: DsTypography.fontFamily,
      scaffoldBackgroundColor: DsColors.backgroundLight,
      textTheme: DsTypography.textTheme(isDark: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsColors.backgroundLight,
        foregroundColor: DsColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DsColors.surfaceLight,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.xl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DsColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.lg,
          vertical: DsSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xl,
            vertical: DsSpacing.md,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DsColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsColors.borderLight,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsColors.primary,
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: DsColors.primary,
      onPrimary: Colors.white,
      secondary: DsColors.secondary,
      onSecondary: Colors.white,
      surface: DsColors.surfaceDark,
      onSurface: DsColors.textPrimaryDark,
      error: DsColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: DsTypography.fontFamily,
      scaffoldBackgroundColor: DsColors.backgroundDark,
      textTheme: DsTypography.textTheme(isDark: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsColors.backgroundDark,
        foregroundColor: DsColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: DsColors.surfaceDark,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.xl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DsColors.inputFillDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.lg,
          vertical: DsSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.md),
          borderSide: const BorderSide(color: DsColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xl,
            vertical: DsSpacing.md,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DsColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsColors.borderDark,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsColors.primary,
      ),
    );
  }
}
