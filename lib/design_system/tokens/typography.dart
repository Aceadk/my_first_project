import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DsTypography {
  /// Primary body font (clean, modern, readable).
  static String get bodyFontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  /// Display font for hero headings (romantic, premium tone).
  static String get displayFontFamily =>
      GoogleFonts.playfairDisplay().fontFamily!;

  /// CJK-capable fallback font families for Chinese, Japanese, Korean text.
  ///
  /// Plus Jakarta Sans and Playfair Display lack CJK glyphs. These fallbacks
  /// ensure system CJK fonts are used when needed:
  /// - iOS: PingFang SC/TC, Hiragino Sans, Apple SD Gothic Neo
  /// - Android: Noto Sans CJK (bundled with system)
  static const cjkFontFallback = [
    'PingFang SC', // iOS Simplified Chinese
    'PingFang TC', // iOS Traditional Chinese
    'Hiragino Sans', // iOS Japanese
    'Apple SD Gothic Neo', // iOS Korean
    'Noto Sans CJK SC', // Android Chinese
    'Noto Sans CJK JP', // Android Japanese
    'Noto Sans CJK KR', // Android Korean
    'Noto Sans SC', // Fallback
    'sans-serif', // Ultimate fallback
  ];

  /// CJK locales that need adjusted typography (wider line height).
  static const _cjkLocales = {'zh', 'ja', 'ko', 'yue'};

  /// Creates a TextTheme using the 2026 type scale.
  static TextTheme textTheme({required bool isDark}) {
    final textColor = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;
    final mutedColor = isDark
        ? DsColors.textMutedDark
        : DsColors.textMutedLight;

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

    // Apply display font to hero styles and CJK fallback to all styles
    return _applyCjkFallback(
      base.copyWith(
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
      ),
    );
  }

  /// Applies CJK font fallback to all text styles in a theme.
  static TextTheme _applyCjkFallback(TextTheme theme) {
    TextStyle? withFallback(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(fontFamilyFallback: cjkFontFallback);
    }

    return theme.copyWith(
      displayLarge: withFallback(theme.displayLarge),
      displayMedium: withFallback(theme.displayMedium),
      displaySmall: withFallback(theme.displaySmall),
      headlineMedium: withFallback(theme.headlineMedium),
      titleLarge: withFallback(theme.titleLarge),
      titleMedium: withFallback(theme.titleMedium),
      bodyLarge: withFallback(theme.bodyLarge),
      bodyMedium: withFallback(theme.bodyMedium),
      bodySmall: withFallback(theme.bodySmall),
      labelLarge: withFallback(theme.labelLarge),
      labelMedium: withFallback(theme.labelMedium),
      labelSmall: withFallback(theme.labelSmall),
    );
  }

  /// Returns a CJK-optimized text theme with wider line heights for
  /// Chinese, Japanese, Korean, and Cantonese locales.
  ///
  /// CJK characters are wider and taller than Latin, requiring 1.6-1.8x
  /// line height (vs 1.5x for Latin) for comfortable reading.
  static TextTheme cjkAdjusted(TextTheme theme, String languageCode) {
    if (!_cjkLocales.contains(languageCode)) return theme;

    return theme.copyWith(
      bodyLarge: theme.bodyLarge?.copyWith(height: 1.7),
      bodyMedium: theme.bodyMedium?.copyWith(height: 1.7),
      bodySmall: theme.bodySmall?.copyWith(height: 1.65),
      titleLarge: theme.titleLarge?.copyWith(height: 1.5),
      titleMedium: theme.titleMedium?.copyWith(height: 1.5),
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
