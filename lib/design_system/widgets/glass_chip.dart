import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/gradients.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A small glass-styled chip/tag for displaying labels, interests, etc.
///
/// Example:
/// ```dart
/// GlassChip(label: 'Music')
/// GlassChip.selected(label: 'Travel', onTap: () => {})
/// GlassChip.icon(icon: Icons.verified, label: 'Verified')
/// ```
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.blur = DsBlur.subtle,
    this.height = 32,
  });

  /// Creates a selected/active chip with gradient background.
  const GlassChip.selected({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.blur = DsBlur.subtle,
    this.height = 32,
  }) : isSelected = true;

  /// Creates a chip with an icon.
  const GlassChip.icon({
    super.key,
    required this.label,
    required IconData this.icon,
    this.isSelected = false,
    this.onTap,
    this.blur = DsBlur.subtle,
    this.height = 32,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final double blur;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor =
        isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight;

    final borderColor =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    final textColor = isSelected
        ? Colors.white
        : (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight);

    Widget chip = ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? null : bgColor,
            gradient: isSelected ? DsGradients.primaryHorizontal : null,
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: isSelected ? null : Border.all(color: borderColor, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: DsSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }

    return chip;
  }
}

/// A row of glass chips with horizontal scrolling.
class GlassChipRow extends StatelessWidget {
  const GlassChipRow({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.padding,
  });

  final List<GlassChip> chips;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

/// A wrap of glass chips for multi-line display.
class GlassChipWrap extends StatelessWidget {
  const GlassChipWrap({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<GlassChip> chips;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}

/// A status badge with glass styling (e.g., "Online", "Verified").
class GlassStatusBadge extends StatelessWidget {
  const GlassStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.blur = DsBlur.subtle,
  });

  /// Creates an "Online" status badge.
  factory GlassStatusBadge.online() => const GlassStatusBadge(
        label: 'Online',
        color: DsColors.onlineIndicator,
        icon: Icons.circle,
      );

  /// Creates a "Verified" status badge.
  factory GlassStatusBadge.verified() => const GlassStatusBadge(
        label: 'Verified',
        color: DsColors.verified,
        icon: Icons.verified,
      );

  final String label;
  final Color? color;
  final IconData? icon;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor =
        isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight;

    final borderColor =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    final textColor = color ??
        (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: textColor),
                const SizedBox(width: DsSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
