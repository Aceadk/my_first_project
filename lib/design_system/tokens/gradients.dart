import 'package:flutter/material.dart';
import 'colors.dart';

/// Gradient definitions for the design system.
///
/// Contains brand gradients, glass overlays, and tab-specific gradients.
class DsGradients {
  DsGradients._();

  // ============================================
  // Brand Gradients (Pink to Purple)
  // ============================================

  /// Primary brand gradient - vertical (top to bottom)
  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [DsColors.primary, DsColors.secondary],
  );

  /// Primary brand gradient - horizontal (left to right)
  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [DsColors.primary, DsColors.secondary],
  );

  /// Primary brand gradient - diagonal (top-left to bottom-right)
  static const LinearGradient primaryDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [DsColors.primary, DsColors.secondary],
  );

  // ============================================
  // Tab-Specific Gradients
  // ============================================

  /// Discover tab gradient (red-orange flame)
  static const LinearGradient discover = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
  );

  /// Matches tab gradient (pink-rose)
  static const LinearGradient matches = LinearGradient(
    colors: [DsColors.primary, Color(0xFFFF6B9D)],
  );

  /// Chats tab gradient (purple)
  static const LinearGradient chats = LinearGradient(
    colors: [DsColors.secondary, Color(0xFF9D6BFF)],
  );

  /// Profile tab gradient (blue)
  static const LinearGradient profile = LinearGradient(
    colors: [Color(0xFF6B8BFF), Color(0xFF5B7AEA)],
  );

  // ============================================
  // Glass Overlay Gradients
  // ============================================

  /// Glass shimmer overlay for light theme
  static LinearGradient glassOverlayLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.25),
      Colors.white.withValues(alpha: 0.05),
    ],
  );

  /// Glass shimmer overlay for dark theme
  static LinearGradient glassOverlayDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.15),
      Colors.white.withValues(alpha: 0.02),
    ],
  );

  // ============================================
  // Background Gradients
  // ============================================

  /// Subtle mesh background gradient
  static const LinearGradient meshBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x10FF4081), // 6% pink
      Color(0x107C4DFF), // 6% purple
      Color(0x10FF4081), // 6% pink
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Radial mesh background for screens
  static const RadialGradient meshRadial = RadialGradient(
    center: Alignment.topRight,
    radius: 1.5,
    colors: [
      Color(0x15FF4081), // 8% pink
      Color(0x10FF4081), // 6% pink
      Colors.transparent,
    ],
    stops: [0.0, 0.3, 1.0],
  );

  /// Secondary radial gradient for layered effect
  static const RadialGradient meshRadialSecondary = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [
      Color(0x127C4DFF), // 7% purple
      Color(0x0A7C4DFF), // 4% purple
      Colors.transparent,
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // ============================================
  // Glass Border Gradients
  // ============================================

  /// Gradient border for glass cards (light theme)
  static const LinearGradient glassBorderLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x60FFFFFF), // 38% white
      Color(0x20FFFFFF), // 12% white
    ],
  );

  /// Gradient border for glass cards (dark theme)
  static const LinearGradient glassBorderDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF), // 25% white
      Color(0x10FFFFFF), // 6% white
    ],
  );

  /// Accent gradient border with brand colors
  static const LinearGradient glassBorderAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x60FF4081), // 38% pink
      Color(0x607C4DFF), // 38% purple
    ],
  );

  /// Get glass overlay based on theme brightness
  static LinearGradient glassOverlay(Brightness brightness) =>
      brightness == Brightness.dark ? glassOverlayDark : glassOverlayLight;

  /// Get glass border gradient based on theme brightness
  static LinearGradient glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? glassBorderDark : glassBorderLight;
}
