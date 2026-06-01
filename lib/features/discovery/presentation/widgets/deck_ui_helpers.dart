import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A glassmorphism-styled action button for the deck screen.
///
/// Features frosted glass background with gradient border on press,
/// scale animation, and haptic feedback.
///
/// Accessibility (DISC-UI-003):
/// * The interactive hit area is never smaller than
///   [kMinInteractiveDimension] (48dp) even when the visual circle is smaller
///   (e.g. the 44dp rewind button), satisfying Material / WCAG 2.5.5
///   touch-target guidance — the visual size is preserved, only the hit area
///   is expanded.
/// * The control is exposed to assistive technologies as a button whose
///   [Semantics.enabled] state tracks [enabled], so the unavailable state is
///   conveyed non-visually as well as via dimming/colour.
/// * A [Tooltip] (defaulting to [semanticLabel]) gives pointer, hover
///   (web/desktop), and long-press users the same affordance label that screen
///   readers announce.
class DeckActionButton extends StatefulWidget {
  const DeckActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.tooltip,
    this.size = 64,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Label announced by assistive technologies and used as the default tooltip.
  final String semanticLabel;

  /// Optional supplementary hint announced after [semanticLabel].
  final String? semanticHint;

  /// Optional tooltip text. Falls back to [semanticLabel] when null.
  final String? tooltip;

  final double size;
  final bool enabled;

  @override
  State<DeckActionButton> createState() => _DeckActionButtonState();
}

class _DeckActionButtonState extends State<DeckActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // When disabled, fall back to a muted grey so the unavailable state is
    // conveyed by colour as well as by the reduced opacity below.
    final effectiveColor = isEnabled ? widget.color : DsColors.ink300;

    // Softer glass background with subtle color tint.
    final bgColor = DsGlassColors.surfaceFor(context);

    // The visual circle (e.g. the 44dp rewind button) may be smaller than the
    // platform's minimum interactive dimension. Expand the *hit* area to at
    // least [kMinInteractiveDimension] (48dp) so the control still satisfies
    // Material / WCAG 2.5.5 touch-target guidance without changing how it looks.
    final double hitExtent = widget.size < kMinInteractiveDimension
        ? kMinInteractiveDimension
        : widget.size;

    final Widget visual = AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            // Soft, subtle shadows only - no heavy outlines
            boxShadow: [
              // Main soft shadow
              BoxShadow(
                color: DsColors.ink900.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              // Inner glow when pressed
              if (_pressed)
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: effectiveColor,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );

    // Tooltip mirrors the semantic label so pointer, hover, and long-press
    // users get the same affordance that screen readers announce.
    final String tooltipMessage = widget.tooltip ?? widget.semanticLabel;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltipMessage,
        child: GestureDetector(
          // Opaque so the full padded hit area (not just the visual circle)
          // responds to taps.
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled ? (_) => _setPressed(true) : null,
          onTapCancel: isEnabled ? () => _setPressed(false) : null,
          onTapUp: isEnabled ? (_) => _setPressed(false) : null,
          onTap: isEnabled
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                }
              : null,
          child: SizedBox(
            width: hitExtent,
            height: hitExtent,
            child: Center(child: visual),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }
}

/// A glassmorphism-styled status bar for the deck screen.
///
/// Shows loading state, retry countdown, or profile completeness progress
/// with frosted glass backgrounds.
class DeckStatusBar extends StatelessWidget {
  const DeckStatusBar({
    super.key,
    required this.isLoading,
    required this.retryInSeconds,
    required this.completeness,
  });

  final bool isLoading;
  final int? retryInSeconds;
  final ProfileCompletenessSummary completeness;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DsSpacing.xs),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.subtle,
            sigmaY: DsBlur.subtle,
          ),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DsColors.primary.withValues(alpha: 0.3),
                  DsColors.secondary.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              minHeight: 4,
            ),
          ),
        ),
      );
    }

    if (retryInSeconds != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DsSpacing.sm),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.light,
              sigmaY: DsBlur.light,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: DsColors.warning.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(DsSpacing.sm),
                border: Border.all(
                  color: DsColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh, size: 18, color: DsColors.warning),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(
                      'Retrying in ~${retryInSeconds}s…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DsColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!completeness.meetsSwipeMinimum) {
      final percent = (completeness.score * 100).round();
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DsSpacing.sm),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.light,
              sigmaY: DsBlur.light,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DsSpacing.md),
              decoration: BoxDecoration(
                color: DsGlassColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(DsSpacing.sm),
                border: Border.all(
                  color: DsGlassColors.borderFor(context),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: DsColors.primary,
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Text(
                          'Profile completeness: $percent%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DsSpacing.xs),
                    child: LinearProgressIndicator(
                      value: completeness.score,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? DsColors.borderDark
                          : DsColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation(
                        DsColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xs),
                  Text(
                    'Finish your profile to start swiping and messaging.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 2);
  }
}

/// A glassmorphism-styled banner for extended search or passport mode.
///
/// Shows when the user's local deck is exhausted and search has been
/// expanded, or when Passport mode is active.
class DeckSearchModeIndicator extends StatelessWidget {
  const DeckSearchModeIndicator({
    super.key,
    required this.localDeckExhausted,
    required this.passportModeActive,
    this.passportLocation,
    this.currentDistanceKm,
    this.onTapPassport,
  });

  final bool localDeckExhausted;
  final bool passportModeActive;
  final String? passportLocation;
  final double? currentDistanceKm;
  final VoidCallback? onTapPassport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Don't show anything if in normal mode
    if (!localDeckExhausted && !passportModeActive) {
      return const SizedBox.shrink();
    }

    // Passport mode indicator
    if (passportModeActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onTapPassport,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsSpacing.sm),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DsBlur.light,
                  sigmaY: DsBlur.light,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                    vertical: DsSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DsColors.info.withValues(alpha: isDark ? 0.2 : 0.15),
                        DsColors.secondary.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DsSpacing.sm),
                    border: Border.all(
                      color: DsColors.info.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DsColors.info.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [DsColors.info, DsColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 14,
                          color: DsColors.surfaceLight,
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Passport Mode',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: DsColors.info,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              passportLocation ?? 'Exploring globally',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: DsColors.info.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Extended search indicator (local deck exhausted)
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsSpacing.sm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DsColors.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
                  DsColors.primary.withValues(alpha: isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(DsSpacing.sm),
              border: Border.all(
                color: DsColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DsColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.explore,
                    size: 14,
                    color: DsColors.secondary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expanded Search',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DsColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentDistanceKm != null
                            ? 'Showing people up to ${currentDistanceKm!.round()} km away'
                            : 'Showing people beyond your usual area',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: DsColors.secondary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
