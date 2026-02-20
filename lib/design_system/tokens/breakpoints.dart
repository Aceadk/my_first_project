import 'package:flutter/widgets.dart';

/// Responsive breakpoints for adaptive layouts.
class DsBreakpoints {
  DsBreakpoints._();

  // ==========================================================================
  // BREAKPOINT VALUES
  // ==========================================================================

  /// Compact mobile (< 360px) - small phones
  static const double compactMax = 360;

  /// Mobile max width (< 600px)
  static const double mobileMax = 600;

  /// Tablet max width (< 1024px)
  static const double tabletMax = 1024;

  /// Desktop max width (< 1440px)
  static const double desktopMax = 1440;

  // ==========================================================================
  // BREAKPOINT CHECKS
  // ==========================================================================

  static bool isCompact(double width) => width < compactMax;
  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) => width >= mobileMax && width < tabletMax;
  static bool isDesktop(double width) =>
      width >= tabletMax && width < desktopMax;
  static bool isLargeDesktop(double width) => width >= desktopMax;

  /// Check if current screen is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if current screen is in portrait orientation.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ==========================================================================
  // RESPONSIVE VALUE HELPERS
  // ==========================================================================

  /// Get a value based on current screen width.
  static T responsiveValue<T>(
    double width, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(width) || isLargeDesktop(width)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(width)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Get a value based on BuildContext.
  static T of<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    return responsiveValue(
      width,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // ==========================================================================
  // GRID COLUMN COUNTS
  // ==========================================================================

  /// Get recommended grid columns for current width.
  static int gridColumns(double width) {
    if (isLargeDesktop(width)) return 4;
    if (isDesktop(width)) return 3;
    if (isTablet(width)) return 2;
    return 1;
  }

  /// Get recommended grid columns from context.
  static int gridColumnsOf(BuildContext context) {
    return gridColumns(MediaQuery.of(context).size.width);
  }

  // ==========================================================================
  // CONTENT MAX WIDTHS
  // ==========================================================================

  /// Maximum content width for mobile (no constraint)
  static const double contentMaxMobile = double.infinity;

  /// Maximum content width for tablet (720px)
  static const double contentMaxTablet = 720;

  /// Maximum content width for desktop (960px)
  static const double contentMaxDesktop = 960;

  /// Maximum content width for large desktop (1200px)
  static const double contentMaxLargeDesktop = 1200;

  /// Get maximum content width for current screen.
  static double contentMaxWidth(double width) {
    if (isLargeDesktop(width)) return contentMaxLargeDesktop;
    if (isDesktop(width)) return contentMaxDesktop;
    if (isTablet(width)) return contentMaxTablet;
    return contentMaxMobile;
  }
}
