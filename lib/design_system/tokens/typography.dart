import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DsTypography {
  /// Primary body font (clean, modern, readable).
  static String get bodyFontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  /// Display font for hero headings (romantic, premium tone).
  static String get displayFontFamily =>
      GoogleFonts.playfairDisplay().fontFamily!;

  /// Creates a TextTheme using the 2026 type scale.
  static TextTheme textTheme({required bool isDark}) {
    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final mutedColor =
        isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    final base = GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          height: 1.12,
          letterSpacing: -0.4,
          color: textColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.21,
          letterSpacing: -0.3,
          color: textColor,
        ),
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.27,
          letterSpacing: -0.2,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.33,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.33,
          color: textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.38,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: textColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: mutedColor,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: textColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: textColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: textColor,
        ),
      ),
    );

    // Apply display font to hero styles
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: base.displayLarge?.fontSize,
        fontWeight: FontWeight.w600,
        height: base.displayLarge?.height,
        letterSpacing: -0.4,
        color: textColor,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: base.displayMedium?.fontSize,
        fontWeight: FontWeight.w600,
        height: base.displayMedium?.height,
        letterSpacing: -0.3,
        color: textColor,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: base.displaySmall?.fontSize,
        fontWeight: FontWeight.w600,
        height: base.displaySmall?.height,
        letterSpacing: -0.2,
        color: textColor,
      ),
    );
  }

  /// Premium typography for luxury mode (slightly heavier, tighter tracking).
  static TextTheme luxuryTextTheme() {
    final base = textTheme(isDark: true);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
