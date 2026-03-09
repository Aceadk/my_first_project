import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/radius.dart';

/// A glassmorphism card with optional gradient border.
///
/// Features:
/// - Frosted glass effect with BackdropFilter
/// - Optional gradient border for premium look
/// - Theme-aware (light/dark mode)
/// - Configurable blur intensity
///
/// Example:
/// ```dart
/// GlassCard(
///   showGradientBorder: true,
///   child: ListTile(
///     title: Text('Card Title'),
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = DsBlur.light,
    this.borderRadius = DsRadius.card,
    this.padding,
    this.margin,
    this.showGradientBorder = false,
    this.gradientBorder,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.onTap,
    this.elevation = 0,
    this.semanticLabel,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// Blur sigma for the glass effect.
  final double blur;

  /// Border radius of the card.
  final double borderRadius;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Margin outside the card.
  final EdgeInsetsGeometry? margin;

  /// Whether to show a gradient border instead of solid border.
  final bool showGradientBorder;

  /// Custom gradient for the border. Uses default accent gradient if null.
  final LinearGradient? gradientBorder;

  /// Width of the border.
  final double borderWidth;

  /// Override background color (uses theme-aware default if null).
  final Color? backgroundColor;

  /// Tap callback for interactive cards.
  final VoidCallback? onTap;

  /// Elevation for shadow (0 for no shadow).
  final double elevation;

  /// Semantic label for screen readers when card is tappable.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    final shadowColor = effects?.glowColor ?? DsColors.primary;
    final shadowOpacity = effects?.shadowOpacity ?? 0.16;

    final bgColor =
        backgroundColor ??
        DsGlassColors.surfaceFor(
          context,
          strength: DsGlassSurfaceStrength.medium,
        );

    final defaultBorderColor = DsGlassColors.borderFor(context);

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: showGradientBorder
                ? null
                : Border.all(color: defaultBorderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );

    // Wrap with gradient border if enabled
    if (showGradientBorder) {
      final gradient = gradientBorder ?? DsGradients.glassBorderAccent;
      cardContent = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: shadowOpacity),
                    blurRadius: elevation * 5,
                    offset: Offset(0, elevation * 2),
                  ),
                ]
              : null,
        ),
        child: Container(
          margin: EdgeInsets.all(borderWidth),
          child: cardContent,
        ),
      );
    } else if (elevation > 0) {
      cardContent = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(
                alpha: isDark ? 0.35 : (shadowOpacity * 0.75),
              ),
              blurRadius: elevation * 5,
              offset: Offset(0, elevation * 2),
            ),
          ],
        ),
        child: cardContent,
      );
    }

    // Add tap handling
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
      if (semanticLabel != null) {
        cardContent = Semantics(
          button: true,
          label: semanticLabel,
          child: cardContent,
        );
      }
    }

    return Container(margin: margin, child: cardContent);
  }
}

/// A glass card with accent gradient background instead of border.
///
/// Use for CTAs or highlighted content.
class GlassCardAccent extends StatelessWidget {
  const GlassCardAccent({
    super.key,
    required this.child,
    this.blur = DsBlur.light,
    this.borderRadius = DsRadius.xl,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    final gradientToUse =
        gradient ?? effects?.primaryGradient ?? DsGradients.primaryDiagonal;
    final shadowColor = effects?.glowColor ?? DsColors.primary;
    final shadowOpacity = effects?.shadowOpacity ?? 0.3;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradientToUse,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: DsGlassColors.highlightFor(context, strong: true),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
      if (semanticLabel != null) {
        content = Semantics(button: true, label: semanticLabel, child: content);
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: shadowOpacity),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}
