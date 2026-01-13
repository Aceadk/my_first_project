import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

/// A simple glassmorphism container with frosted blur effect.
///
/// Use this for basic glass backgrounds. For more features like gradient
/// borders, use [GlassCard] instead.
///
/// Example:
/// ```dart
/// GlassContainer(
///   blur: DsBlur.medium,
///   borderRadius: DsRadius.lg,
///   padding: EdgeInsets.all(16),
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = DsBlur.medium,
    this.borderRadius = DsRadius.lg,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.clipBehavior = Clip.antiAlias,
  });

  /// The widget to display inside the glass container.
  final Widget child;

  /// The blur sigma for the frosted glass effect.
  final double blur;

  /// The border radius of the container.
  final double borderRadius;

  /// Padding inside the container.
  final EdgeInsetsGeometry? padding;

  /// Margin outside the container.
  final EdgeInsetsGeometry? margin;

  /// Override the default glass background color.
  final Color? backgroundColor;

  /// Override the default border color.
  final Color? borderColor;

  /// Width of the border.
  final double borderWidth;

  /// Clip behavior for the container.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight);

    final borderClr = borderColor ??
        (isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight);

    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: clipBehavior,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderClr,
                  width: borderWidth,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass container with a gradient shimmer overlay.
///
/// Provides a more premium glass effect with a subtle gradient highlight.
class GlassContainerShimmer extends StatelessWidget {
  const GlassContainerShimmer({
    super.key,
    required this.child,
    this.blur = DsBlur.medium,
    this.borderRadius = DsRadius.lg,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor =
        isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight;

    final borderClr =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderClr, width: 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                    Colors.white.withValues(alpha: isDark ? 0.02 : 0.05),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
