import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/luxury.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../tokens/elevation.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DsColors.primary,
      onPrimary: Colors.white,
      secondary: DsColors.secondary,
      onSecondary: Colors.white,
      tertiary: DsColors.accent,
      onTertiary: DsColors.ink900,
      surface: DsColors.surfaceLight,
      onSurface: DsColors.textPrimaryLight,
      surfaceContainerHighest: DsColors.backgroundLight,
      error: DsColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: DsTypography.bodyFontFamily,
      scaffoldBackgroundColor: DsColors.backgroundLight,
      textTheme: DsTypography.textTheme(isDark: false),
      iconTheme: const IconThemeData(color: DsColors.textPrimaryLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsColors.backgroundLight,
        foregroundColor: DsColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: DsColors.surfaceLight,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.card),
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
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.round),
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
      chipTheme: ChipThemeData(
        backgroundColor: DsColors.surfaceLight,
        selectedColor: DsColors.primary,
        secondarySelectedColor: DsColors.secondary,
        labelStyle: const TextStyle(
          color: DsColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          side: const BorderSide(color: DsColors.borderLight),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DsColors.ink800,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsColors.borderLight,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsColors.primary,
      ),
      extensions: const [
        CrushThemeEffects(
          glowColor: DsColors.primary,
          glassSurface: DsGlassColors.surfaceLight,
          glassBorder: DsGlassColors.borderLight,
          shadowOpacity: 0.16,
          motionScale: 1.0,
          primaryGradient: DsGradients.primaryHorizontal,
        ),
      ],
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: DsColors.primary,
      onPrimary: Colors.white,
      secondary: DsColors.secondary,
      onSecondary: Colors.white,
      tertiary: DsColors.accent,
      onTertiary: Colors.black,
      surface: DsColors.surfaceDark,
      onSurface: DsColors.textPrimaryDark,
      surfaceContainerHighest: DsColors.backgroundDark,
      error: DsColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: DsTypography.bodyFontFamily,
      scaffoldBackgroundColor: DsColors.backgroundDark,
      textTheme: DsTypography.textTheme(isDark: true),
      iconTheme: const IconThemeData(color: DsColors.textPrimaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsColors.backgroundDark,
        foregroundColor: DsColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: DsColors.surfaceDark,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.card),
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
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.round),
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
      chipTheme: ChipThemeData(
        backgroundColor: DsColors.surfaceDark,
        selectedColor: DsColors.primary,
        secondarySelectedColor: DsColors.secondary,
        labelStyle: const TextStyle(
          color: DsColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          side: const BorderSide(color: DsColors.borderDark),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DsColors.surfaceElevatedDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsColors.borderDark,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsColors.primary,
      ),
      extensions: const [
        CrushThemeEffects(
          glowColor: DsColors.primary,
          glassSurface: DsGlassColors.surfaceDark,
          glassBorder: DsGlassColors.borderDark,
          shadowOpacity: 0.2,
          motionScale: 1.0,
          primaryGradient: DsGradients.primaryHorizontal,
        ),
      ],
    );
  }

  static ThemeData darkLuxury() => darkLuxuryClassic();

  static ThemeData darkLuxuryClassic() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: DsLuxuryColors.goldPrimary,
      onPrimary: DsLuxuryColors.textOnGold,
      secondary: DsLuxuryColors.goldSoft,
      onSecondary: DsLuxuryColors.textOnGold,
      tertiary: DsLuxuryColors.goldDark,
      onTertiary: DsLuxuryColors.textOnGold,
      surface: DsLuxuryColors.surface,
      onSurface: DsLuxuryColors.textPrimary,
      surfaceContainerHighest: DsLuxuryColors.background,
      error: DsColors.error,
      onError: DsLuxuryColors.textOnGold,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: DsTypography.bodyFontFamily,
      scaffoldBackgroundColor: DsLuxuryColors.background,
      textTheme: DsTypography.luxuryTextTheme(),
      iconTheme: const IconThemeData(color: DsLuxuryColors.iconPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsLuxuryColors.background,
        foregroundColor: DsLuxuryColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: DsLuxuryColors.card,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DsLuxuryColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.lg,
          vertical: DsSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsLuxuryColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsLuxuryColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide:
              const BorderSide(color: DsLuxuryColors.goldPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsLuxuryColors.goldPrimary,
          foregroundColor: DsLuxuryColors.textOnGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.round),
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
          foregroundColor: DsLuxuryColors.goldPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DsLuxuryColors.card,
        selectedColor: DsLuxuryColors.goldPrimary,
        secondarySelectedColor: DsLuxuryColors.goldSoft,
        labelStyle: const TextStyle(
          color: DsLuxuryColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          side: const BorderSide(color: DsLuxuryColors.glassBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DsLuxuryColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: DsLuxuryColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsLuxuryColors.glassBorder,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsLuxuryColors.goldPrimary,
      ),
      extensions: const [
        CrushThemeEffects(
          glowColor: DsLuxuryColors.glowGold,
          glassSurface: DsLuxuryColors.glass,
          glassBorder: DsLuxuryColors.glassBorder,
          shadowOpacity: 0.28,
          motionScale: 1.2,
          primaryGradient: DsLuxuryGradients.goldSheen,
        ),
      ],
    );
  }

  static ThemeData darkLuxuryModern() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: DsLuxuryModernColors.goldPrimary,
      onPrimary: DsLuxuryModernColors.textOnGold,
      secondary: DsLuxuryModernColors.goldSoft,
      onSecondary: DsLuxuryModernColors.textOnGold,
      tertiary: DsLuxuryModernColors.goldDark,
      onTertiary: DsLuxuryModernColors.textOnGold,
      surface: DsLuxuryModernColors.surface,
      onSurface: DsLuxuryModernColors.textPrimary,
      surfaceContainerHighest: DsLuxuryModernColors.background,
      error: DsLuxuryModernColors.error,
      onError: DsLuxuryModernColors.textOnGold,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: DsTypography.bodyFontFamily,
      scaffoldBackgroundColor: DsLuxuryModernColors.background,
      textTheme: DsTypography.luxuryTextTheme(),
      iconTheme: const IconThemeData(color: DsLuxuryModernColors.iconPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: DsLuxuryModernColors.background,
        foregroundColor: DsLuxuryModernColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: DsLuxuryModernColors.card,
        elevation: DsElevation.mid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DsLuxuryModernColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.lg,
          vertical: DsSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsLuxuryModernColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsLuxuryModernColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(
              color: DsLuxuryModernColors.goldPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide: const BorderSide(color: DsLuxuryModernColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadius.input),
          borderSide:
              const BorderSide(color: DsLuxuryModernColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DsLuxuryModernColors.goldPrimary,
          foregroundColor: DsLuxuryModernColors.textOnGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.round),
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
          foregroundColor: DsLuxuryModernColors.goldPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DsLuxuryModernColors.card,
        selectedColor: DsLuxuryModernColors.goldPrimary,
        secondarySelectedColor: DsLuxuryModernColors.goldSoft,
        labelStyle: const TextStyle(
          color: DsLuxuryModernColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          side: const BorderSide(color: DsLuxuryModernColors.glassBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DsLuxuryModernColors.surfaceElevated,
        contentTextStyle:
            const TextStyle(color: DsLuxuryModernColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DsLuxuryModernColors.glassBorder,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DsLuxuryModernColors.goldPrimary,
      ),
      extensions: const [
        CrushThemeEffects(
          glowColor: DsLuxuryModernColors.glowGold,
          glassSurface: DsLuxuryModernColors.glass,
          glassBorder: DsLuxuryModernColors.glassBorder,
          shadowOpacity: 0.24,
          motionScale: 1.2,
          primaryGradient: DsLuxuryModernGradients.goldSheen,
        ),
      ],
    );
  }
}
