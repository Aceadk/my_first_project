import 'package:flutter/material.dart';

/// Minimum tap target size for accessibility (WCAG 2.1).
const double kMinTapTargetSize = 44.0;

/// An accessible icon button that ensures proper semantic labels and tap targets.
///
/// Features:
/// - Required semantic label for screen readers
/// - Minimum 44x44 tap target (WCAG 2.1 compliance)
/// - Optional hint text for additional context
/// - Loading state support
class CrushIconButton extends StatelessWidget {
  const CrushIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.size = 24.0,
    this.color,
    this.backgroundColor,
    this.padding,
    this.loading = false,
    this.enabled = true,
    this.tooltip,
  });

  /// The icon to display.
  final IconData icon;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Required label for screen readers.
  final String semanticLabel;

  /// Optional hint describing the action result.
  final String? semanticHint;

  /// Size of the icon.
  final double size;

  /// Color of the icon.
  final Color? color;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Padding around the icon.
  final EdgeInsets? padding;

  /// Whether the button is in a loading state.
  final bool loading;

  /// Whether the button is enabled.
  final bool enabled;

  /// Optional tooltip text.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(8);
    final isEnabled = enabled && !loading && onPressed != null;

    Widget button = Semantics(
      button: true,
      enabled: isEnabled,
      label: loading ? 'Loading, $semanticLabel' : semanticLabel,
      hint: semanticHint,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTapTargetSize,
          minHeight: kMinTapTargetSize,
        ),
        child: Material(
          color: backgroundColor ?? Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: effectivePadding,
              child: loading
                  ? SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      icon,
                      size: size,
                      color: isEnabled
                          ? color
                          : (color ?? Theme.of(context).iconTheme.color)
                                ?.withAlpha((0.38 * 255).round()),
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
}

/// A labeled icon button for action bars and toolbars.
class CrushLabeledIconButton extends StatelessWidget {
  const CrushLabeledIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconSize = 24.0,
    this.color,
    this.enabled = true,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;
    final theme = Theme.of(context);
    final effectiveColor = isEnabled
        ? color ?? theme.iconTheme.color
        : (color ?? theme.iconTheme.color)?.withAlpha((0.38 * 255).round());

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: loading ? 'Loading, $label' : label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTargetSize),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: effectiveColor,
                    ),
                  )
                else
                  Icon(icon, size: iconSize, color: effectiveColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
