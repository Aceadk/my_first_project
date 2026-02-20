import 'package:flutter/material.dart';
import '../tokens/sizes.dart';
import '../tokens/colors.dart';
import '../utils/haptics.dart';

/// An accessible icon button that ensures proper tap target size
/// and semantic labeling for screen readers.
class DsAccessibleIconButton extends StatelessWidget {
  const DsAccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.size = DsIconButtonSize.medium,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.enabled = true,
    this.enableHaptics = true,
    this.focusNode,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final DsIconButtonSize size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool enabled;
  final bool enableHaptics;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonSize = _getButtonSize();
    final iconSize = _getIconSize();

    final effectiveColor =
        color ??
        (enabled
            ? (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight)
            : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight));

    Widget button = Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: enabled,
      child: Focus(
        focusNode: focusNode,
        child: Material(
          color: backgroundColor ?? Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    if (enableHaptics) {
                      DsHaptics.light();
                    }
                    onPressed?.call();
                  }
                : null,
            customBorder: const CircleBorder(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: buttonSize,
                minHeight: buttonSize,
              ),
              child: Center(
                child: Icon(icon, size: iconSize, color: effectiveColor),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  double _getButtonSize() {
    return switch (size) {
      DsIconButtonSize.small => DsSizes.tapTargetMin,
      DsIconButtonSize.medium => DsSizes.tapTargetPreferred,
      DsIconButtonSize.large => DsSizes.tapTargetLarge,
    };
  }

  double _getIconSize() {
    return switch (size) {
      DsIconButtonSize.small => DsSizes.iconMd,
      DsIconButtonSize.medium => DsSizes.iconDefault,
      DsIconButtonSize.large => DsSizes.iconLg,
    };
  }
}

/// Sizes for icon buttons.
enum DsIconButtonSize { small, medium, large }

/// An accessible action button for the discovery deck.
class DsActionButton extends StatelessWidget {
  const DsActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.size = DsActionButtonSize.medium,
    this.color,
    this.backgroundColor,
    this.enabled = true,
    this.enableHaptics = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final DsActionButtonSize size;
  final Color? color;
  final Color? backgroundColor;
  final bool enabled;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonSize = _getButtonSize();
    final iconSize = _getIconSize();

    final effectiveColor = color ?? Colors.white;
    final effectiveBgColor =
        backgroundColor ??
        (isDark ? DsColors.surfaceElevatedDark : DsColors.surfaceElevatedLight);

    return Semantics(
      label: semanticLabel,
      hint: semanticHint ?? 'Double tap to activate',
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: enabled
              ? effectiveBgColor
              : effectiveBgColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    if (enableHaptics) {
                      DsHaptics.medium();
                    }
                    onPressed?.call();
                  }
                : null,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: enabled
                    ? effectiveColor
                    : effectiveColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getButtonSize() {
    return switch (size) {
      DsActionButtonSize.small => DsSizes.actionButtonSm,
      DsActionButtonSize.medium => DsSizes.actionButtonMd,
      DsActionButtonSize.large => DsSizes.actionButtonLg,
    };
  }

  double _getIconSize() {
    return switch (size) {
      DsActionButtonSize.small => DsSizes.iconDefault,
      DsActionButtonSize.medium => DsSizes.iconLg,
      DsActionButtonSize.large => DsSizes.iconXl,
    };
  }
}

/// Sizes for action buttons.
enum DsActionButtonSize { small, medium, large }

/// A labeled action button for discovery deck.
class DsLabeledActionButton extends StatelessWidget {
  const DsLabeledActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DsActionButton(
          icon: icon,
          onPressed: onPressed,
          semanticLabel: label,
          color: color,
          backgroundColor: backgroundColor,
          enabled: enabled,
          size: DsActionButtonSize.medium,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: enabled
                ? (Theme.of(context).brightness == Brightness.dark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight)
                : (Theme.of(context).brightness == Brightness.dark
                      ? DsColors.textMutedDark.withValues(alpha: 0.5)
                      : DsColors.textMutedLight.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
