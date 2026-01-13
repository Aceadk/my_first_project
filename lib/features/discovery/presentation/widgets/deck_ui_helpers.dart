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
class DeckActionButton extends StatefulWidget {
  const DeckActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.size = 64,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;
  final String? semanticHint;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.enabled;

    // When disabled, use grey color
    final effectiveColor = isEnabled ? widget.color : Colors.grey;

    // Glass background color with the action color tint
    final glassBg = effectiveColor.withValues(alpha: isDark ? 0.25 : 0.2);
    final glassOverlay =
        isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        onTap: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onTap();
              }
            : null,
        child: AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: AnimatedScale(
            scale: _pressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DsBlur.medium,
                  sigmaY: DsBlur.medium,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        glassBg,
                        glassOverlay,
                      ],
                    ),
                    border: Border.all(
                      color: _pressed
                          ? effectiveColor.withValues(alpha: 0.8)
                          : (isDark
                              ? DsGlassColors.borderDark
                              : DsGlassColors.borderLight),
                      width: _pressed ? 2.5 : 1.5,
                    ),
                    boxShadow: _pressed
                        ? [
                            BoxShadow(
                              color: effectiveColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
            ),
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
          filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
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
            filter:
                ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(DsSpacing.sm),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(
                      'Retrying in ~${retryInSeconds}s…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade300,
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
            filter:
                ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DsSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? DsGlassColors.surfaceDark
                    : DsGlassColors.surfaceLight,
                borderRadius: BorderRadius.circular(DsSpacing.sm),
                border: Border.all(
                  color: isDark
                      ? DsGlassColors.borderDark
                      : DsGlassColors.borderLight,
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
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
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
        child: GestureDetector(
          onTap: onTapPassport,
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
                      Colors.cyan.withValues(alpha: isDark ? 0.2 : 0.15),
                      Colors.blue.withValues(alpha: isDark ? 0.15 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DsSpacing.sm),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.1),
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
                          colors: [Colors.cyan, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        size: 14,
                        color: Colors.white,
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
                              color: Colors.cyan,
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
                      color: Colors.cyan.shade300,
                    ),
                  ],
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
