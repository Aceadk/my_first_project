import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

class DsColors {
  DsColors._();

  // Brand colors (2026 refresh)
  static const Color primary = Color(0xFFFF4D6D); // Romantic rose
  static const Color primaryDark = Color(0xFFE03B5F);
  static const Color secondary = Color(0xFF7B6CFF); // Premium plum
  static const Color accent = Color(0xFF4DD6A7); // Trust mint

  // Neutral ink scale
  static const Color ink900 = Color(0xFF0B0B10);
  static const Color ink800 = Color(0xFF14141B);
  static const Color ink700 = Color(0xFF1E1E28);
  static const Color ink600 = Color(0xFF2A2A36);
  static const Color ink500 = Color(0xFF3A3A4A);
  static const Color ink400 = Color(0xFF4A4A5E);
  static const Color ink300 = Color(0xFF6D6D86);
  static const Color ink200 = Color(0xFFA0A0B8);
  static const Color ink100 = Color(0xFFD6D6E6);
  static const Color ink50 = Color(0xFFF5F5FA);

  // Light theme colors
  static const Color backgroundLight = Color(0xFFF8F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFDFDFF);
  static const Color textPrimaryLight = ink900;
  static const Color textMutedLight = ink300;
  static const Color borderLight = Color(0xFFE6E4F2);
  static const Color inputFillLight = Color(0xFFF3F2F7);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0D0E12);
  static const Color surfaceDark = Color(0xFF14141B);
  static const Color surfaceElevatedDark = Color(0xFF1E1E28);
  static const Color textPrimaryDark = ink50;
  static const Color textMutedDark = ink200;
  static const Color borderDark = ink600;
  static const Color inputFillDark = Color(0xFF1B1C24);

  // Status colors
  static const Color error = Color(0xFFFF5A6E);
  static const Color success = Color(0xFF43C59E);
  static const Color warning = Color(0xFFF7B955);
  static const Color info = Color(0xFF5BB3FF);

  // Semantic colors for chat/messaging
  static const Color messageOutgoing = primary;
  static const Color messageIncoming = Color(0xFF20202A);
  static const Color messageIncomingLight = Color(0xFFF0EFF6);

  // Status indicators
  static const Color onlineIndicator = accent;
  static const Color offlineIndicator = ink300;
  static const Color busyIndicator = warning;

  // Action button colors for deck/discovery
  static const Color actionPass = ink700;
  static const Color actionPassDark = ink900;
  static const Color actionLike = primary;
  static const Color actionSuperLike = secondary;
  static const Color actionMessage = accent;
  static const Color actionRewind = warning;

  // Safety/verification colors
  static const Color verified = success;
  static const Color safetyWarning = warning;
  static const Color safetyBlocked = error;

  // Skeleton loading colors
  static const Color skeletonLight = Color(0xFFE6E4F2);
  static const Color skeletonDark = Color(0xFF2A2A36);

  // Overlay colors
  static const Color overlayLight = Color(0x14000000);
  static const Color overlayMedium = Color(0x33000000);
  static const Color overlayDark = Color(0x66000000);

  // Divider colors
  static const Color dividerLight = Color(0xFFE6E4F2);
  static const Color dividerDark = Color(0xFF2A2A36);
}

/// Glassmorphism color tokens for frosted glass effects
class DsGlassColors {
  DsGlassColors._();

  // Glass surfaces (light theme)
  static const Color surfaceLight = Color(0xB8FFFFFF); // 72% white
  static const Color surfaceMediumLight = Color(0xCCFFFFFF); // 80% white
  static const Color surfaceHeavyLight = Color(0xE6FFFFFF); // 90% white

  // Glass surfaces (dark theme)
  static const Color surfaceDark = Color(0xB314141B); // 70% dark
  static const Color surfaceMediumDark = Color(0xCC14141B); // 80% dark
  static const Color surfaceHeavyDark = Color(0xE61E1E28); // 90% dark

  // Glass borders
  static const Color borderLight = Color(0x40FFFFFF); // 25% white border
  static const Color borderDark = Color(0x26FFFFFF); // 15% white border

  // Gradient overlays for glass
  static const Color gradientPinkOverlay = Color(0x1AFF4D6D); // 10% rose
  static const Color gradientPurpleOverlay = Color(0x1A7B6CFF); // 10% plum

  // Shimmer highlights for glass edges
  static const Color highlight = Color(0x33FFFFFF);
  static const Color highlightStrong = Color(0x55FFFFFF);

  // Frosted backdrop
  static const Color frostLight = Color(0xD9FFFFFF); // 85% white
  static const Color frostDark = Color(0xB3000000); // 70% black

  /// Get glass surface color based on theme brightness
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  /// Get glass border color based on theme brightness
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;

  /// Get glass surface color based on theme + luxury effects.
  static Color surfaceFor(
    BuildContext context, {
    DsGlassSurfaceStrength strength = DsGlassSurfaceStrength.light,
  }) {
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    if (effects != null) {
      return _surfaceFromBase(effects.glassSurface, strength);
    }

    final brightness = Theme.of(context).brightness;
    switch (strength) {
      case DsGlassSurfaceStrength.light:
        return brightness == Brightness.dark ? surfaceDark : surfaceLight;
      case DsGlassSurfaceStrength.medium:
        return brightness == Brightness.dark ? surfaceMediumDark : surfaceMediumLight;
      case DsGlassSurfaceStrength.heavy:
        return brightness == Brightness.dark ? surfaceHeavyDark : surfaceHeavyLight;
    }
  }

  /// Get glass border color based on theme + luxury effects.
  static Color borderFor(BuildContext context) {
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    if (effects != null) return effects.glassBorder;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? borderDark : borderLight;
  }

  /// Get glass shimmer highlight color based on theme + luxury effects.
  static Color highlightFor(BuildContext context, {bool strong = false}) {
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    if (effects != null) {
      final base = effects.glowColor;
      return base.withValues(alpha: strong ? 0.5 : 0.32);
    }
    return strong ? highlightStrong : highlight;
  }

  static Color _surfaceFromBase(
    Color base,
    DsGlassSurfaceStrength strength,
  ) {
    final alpha = base.opacity;
    final boost = switch (strength) {
      DsGlassSurfaceStrength.light => 0.0,
      DsGlassSurfaceStrength.medium => 0.12,
      DsGlassSurfaceStrength.heavy => 0.22,
    };
    return base.withValues(alpha: (alpha + boost).clamp(0.0, 1.0));
  }
}

enum DsGlassSurfaceStrength {
  light,
  medium,
  heavy,
}
