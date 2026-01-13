import 'package:flutter/material.dart';

class DsColors {
  DsColors._();

  // Brand colors
  static const Color primary = Color(0xFFFF4081);
  static const Color secondary = Color(0xFF7C4DFF);

  // Light theme colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1B1B1B);
  static const Color textMutedLight = Color(0xFF6B6B6B);
  static const Color borderLight = Color(0xFFE6E6E6);
  static const Color inputFillLight = Color(0xFFF5F5F7);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0B0B0C);
  static const Color surfaceDark = Color(0xFF121214);
  static const Color textPrimaryDark = Color(0xFFF3F3F4);
  static const Color textMutedDark = Color(0xFFB1B1B6);
  static const Color borderDark = Color(0xFF2A2A2E);
  static const Color inputFillDark = Color(0xFF1C1C20);

  // Status colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = Color(0xFF0288D1);

  // Semantic colors for chat/messaging
  static const Color messageOutgoing = primary;
  static const Color messageIncoming = Color(0xFF2A2A2E);
  static const Color messageIncomingLight = Color(0xFFE8E8EA);

  // Status indicators
  static const Color onlineIndicator = Color(0xFF4CAF50);
  static const Color offlineIndicator = Color(0xFF9E9E9E);
  static const Color busyIndicator = Color(0xFFFF9800);

  // Action button colors for deck/discovery
  static const Color actionPass = Color(0xFFE0E0E0);
  static const Color actionPassDark = Color(0xFF424242);
  static const Color actionLike = primary;
  static const Color actionSuperLike = Color(0xFF2196F3);
  static const Color actionMessage = secondary;
  static const Color actionRewind = Color(0xFFFFB300); // Amber/gold for rewind

  // Safety/verification colors
  static const Color verified = success;
  static const Color safetyWarning = warning;
  static const Color safetyBlocked = error;

  // Skeleton loading colors
  static const Color skeletonLight = Color(0xFFE0E0E0);
  static const Color skeletonDark = Color(0xFF424242);

  // Overlay colors
  static const Color overlayLight = Color(0x1A000000);
  static const Color overlayMedium = Color(0x4D000000);
  static const Color overlayDark = Color(0x80000000);

  // Divider colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2A2A2E);
}

/// Glassmorphism color tokens for frosted glass effects
class DsGlassColors {
  DsGlassColors._();

  // Glass surfaces (light theme)
  static const Color surfaceLight = Color(0x40FFFFFF); // 25% white
  static const Color surfaceMediumLight = Color(0x66FFFFFF); // 40% white
  static const Color surfaceHeavyLight = Color(0x99FFFFFF); // 60% white

  // Glass surfaces (dark theme)
  static const Color surfaceDark = Color(0x30FFFFFF); // 19% white
  static const Color surfaceMediumDark = Color(0x4D1C1C20); // 30% dark
  static const Color surfaceHeavyDark = Color(0x80121214); // 50% dark

  // Glass borders
  static const Color borderLight = Color(0x40FFFFFF); // 25% white border
  static const Color borderDark = Color(0x30FFFFFF); // 19% white border

  // Gradient overlays for glass
  static const Color gradientPinkOverlay = Color(0x30FF4081); // 19% pink
  static const Color gradientPurpleOverlay = Color(0x307C4DFF); // 19% purple

  // Shimmer highlights for glass edges
  static const Color highlight = Color(0x40FFFFFF);
  static const Color highlightStrong = Color(0x66FFFFFF);

  // Frosted backdrop
  static const Color frostLight = Color(0xB3FFFFFF); // 70% white
  static const Color frostDark = Color(0x99000000); // 60% black

  /// Get glass surface color based on theme brightness
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  /// Get glass border color based on theme brightness
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;
}
