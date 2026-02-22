import 'package:flutter/material.dart';
import 'colors.dart';

/// Gradient definitions for the design system.
///
/// Contains brand gradients, glass overlays, and tab-specific gradients.
class DsGradients {
  DsGradients._();

  // ============================================
  // Brand Gradients (Rose to Plum)
  // ============================================

  /// Primary brand gradient - vertical (top to bottom)
  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [DsColors.primary, DsColors.secondary],
  );

  /// Primary brand gradient - horizontal (left to right)
  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [DsColors.primary, DsColors.secondary],
  );

  /// Primary brand gradient - diagonal (top-left to bottom-right)
  static const LinearGradient primaryDiagonal = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [DsColors.primary, DsColors.secondary],
  );

  /// Soft rose gradient (used for subtle accents)
  static const LinearGradient roseSoft = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFFFF6F86), Color(0xFFFFA3B1)],
  );

  // ============================================
  // Tab-Specific Gradients
  // ============================================

  /// Discover tab gradient (red-orange flame)
  static const LinearGradient discover = LinearGradient(
    colors: [Color(0xFFFF4D6D), Color(0xFFFF7A8F)],
  );

  /// Matches tab gradient (pink-rose)
  static const LinearGradient matches = LinearGradient(
    colors: [Color(0xFFFF6F86), Color(0xFFFF9FB1)],
  );

  /// Chats tab gradient (purple)
  static const LinearGradient chats = LinearGradient(
    colors: [DsColors.secondary, Color(0xFF9A8BFF)],
  );

  /// Profile tab gradient (blue)
  static const LinearGradient profile = LinearGradient(
    colors: [Color(0xFF5C87FF), Color(0xFF7B6CFF)],
  );

  // ============================================
  // Glass Overlay Gradients
  // ============================================

  /// Glass shimmer overlay for light theme
  static LinearGradient glassOverlayLight = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Colors.white.withValues(alpha: 0.18),
      Colors.white.withValues(alpha: 0.04),
    ],
  );

  /// Glass shimmer overlay for dark theme
  static LinearGradient glassOverlayDark = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Colors.white.withValues(alpha: 0.12),
      Colors.white.withValues(alpha: 0.02),
    ],
  );

  // ============================================
  // Background Gradients
  // ============================================

  /// Subtle mesh background gradient
  static const LinearGradient meshBackground = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0x12FF4D6D), // 7% rose
      Color(0x127B6CFF), // 7% plum
      Color(0x104DD6A7), // 6% mint
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Radial mesh background for screens
  static const RadialGradient meshRadial = RadialGradient(
    center: AlignmentDirectional.topEnd,
    radius: 1.5,
    colors: [
      Color(0x16FF4D6D), // 9% rose
      Color(0x0FFF4D6D), // 6% rose
      Colors.transparent,
    ],
    stops: [0.0, 0.3, 1.0],
  );

  /// Secondary radial gradient for layered effect
  static const RadialGradient meshRadialSecondary = RadialGradient(
    center: AlignmentDirectional.bottomStart,
    radius: 1.2,
    colors: [
      Color(0x127B6CFF), // 7% plum
      Color(0x0A7B6CFF), // 4% plum
      Colors.transparent,
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // ============================================
  // Glass Border Gradients
  // ============================================

  /// Gradient border for glass cards (light theme)
  static const LinearGradient glassBorderLight = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0x60FFFFFF), // 38% white
      Color(0x26FFFFFF), // 15% white
    ],
  );

  /// Gradient border for glass cards (dark theme)
  static const LinearGradient glassBorderDark = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0x33FFFFFF), // 20% white
      Color(0x12FFFFFF), // 7% white
    ],
  );

  /// Accent gradient border with brand colors
  static const LinearGradient glassBorderAccent = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0x60FF4D6D), // 38% rose
      Color(0x607B6CFF), // 38% plum
    ],
  );

  /// Get glass overlay based on theme brightness
  static LinearGradient glassOverlay(Brightness brightness) =>
      brightness == Brightness.dark ? glassOverlayDark : glassOverlayLight;

  /// Get glass border gradient based on theme brightness
  static LinearGradient glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? glassBorderDark : glassBorderLight;
}
