import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A primary button with gradient background and glass shimmer overlay.
///
/// Use for main CTAs and important actions.
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.isLoading = false,
    this.isExpanded = false,
    this.height = 52,
    this.borderRadius = DsRadius.round,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient? gradient;
  final bool isLoading;
  final bool isExpanded;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final gradientToUse = gradient ?? DsGradients.primaryHorizontal;
    final isDisabled = onPressed == null || isLoading;

    Widget buttonContent = AnimatedOpacity(
      opacity: isDisabled ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
        decoration: BoxDecoration(
          gradient: gradientToUse,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: gradientToUse.colors.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glass shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: IconTheme(
                        data: const IconThemeData(color: Colors.white),
                        child: child,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (isExpanded) {
      buttonContent = SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                HapticService.mediumTap();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(borderRadius),
        child: buttonContent,
      ),
    );
  }
}

/// An outlined button with glass background and subtle border.
///
/// Use for secondary actions.
class GlassOutlinedButton extends StatelessWidget {
  const GlassOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.blur = DsBlur.light,
    this.isLoading = false,
    this.isExpanded = false,
    this.height = 52,
    this.borderRadius = DsRadius.round,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final bool isLoading;
  final bool isExpanded;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight);

    final borderClr = borderColor ??
        (isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight);

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    final isDisabled = onPressed == null || isLoading;

    Widget buttonContent = AnimatedOpacity(
      opacity: isDisabled ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderClr, width: 1.5),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(textColor),
                      ),
                    )
                  : DefaultTextStyle(
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: textColor),
                        child: child,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    if (isExpanded) {
      buttonContent = SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                HapticService.lightTap();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(borderRadius),
        child: buttonContent,
      ),
    );
  }
}

/// A circular glass icon button.
///
/// Use for toolbar actions and secondary interactions.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.blur = DsBlur.light,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final double iconSize;
  final double blur;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight);

    final borderColor =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    final iconClr = iconColor ??
        (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight);

    Widget button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(icon, size: iconSize, color: iconClr),
        ),
      ),
    );

    button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticService.lightTap();
                onPressed?.call();
              },
        customBorder: const CircleBorder(),
        child: button,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// A large circular action button with gradient and glass effects.
///
/// Use for main deck actions (like, pass, message).
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.gradient,
    this.size = 64,
    this.iconSize = 28,
    this.iconColor = Colors.white,
    this.tooltip,
    this.showShadow = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final LinearGradient? gradient;
  final double size;
  final double iconSize;
  final Color iconColor;
  final String? tooltip;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final gradientToUse = gradient ?? DsGradients.primaryHorizontal;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradientToUse,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: gradientToUse.colors.first.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Glass shimmer overlay
          Positioned.fill(
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),
          ),
          // Icon
          Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ],
      ),
    );

    button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticService.mediumTap();
                onPressed?.call();
              },
        customBorder: const CircleBorder(),
        child: button,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// A small glass button for secondary actions in compact spaces.
class GlassSmallButton extends StatelessWidget {
  const GlassSmallButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.blur = DsBlur.subtle,
    this.height = 36,
    this.borderRadius = DsRadius.round,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double blur;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor =
        isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight;

    final borderColor =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticService.lightTap();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: textColor, size: 18),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
