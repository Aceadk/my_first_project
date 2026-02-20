import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';

/// Shared onboarding progress indicator used across splash/auth/setup screens.
///
/// Displays a step label, a linear progress bar, and an optional caption.
/// When [showSkip] is true, a "Skip" text button is displayed next to the
/// step label, invoking [onSkip] when tapped.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.caption,
    this.showSkip = false,
    this.onSkip,
  });

  /// Zero-based index into [onboardingSteps].
  final int currentStep;
  final String? caption;

  /// Whether to show a "Skip" button next to the step label.
  final bool showSkip;

  /// Callback invoked when the user taps "Skip".
  /// Only used when [showSkip] is true.
  final VoidCallback? onSkip;

  static const List<String> onboardingSteps = [
    'Welcome',
    'Verify phone',
    'Enter code',
    'Basic info',
    'Verify ID',
    'Profile setup',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final total = onboardingSteps.length;
    final clampedStep = currentStep.clamp(0, total - 1);
    final progress = (clampedStep + 1) / total;
    final stepLabel = onboardingSteps[clampedStep];
    final nextLabel = clampedStep + 1 < total
        ? 'Next: ${onboardingSteps[clampedStep + 1]}'
        : 'Almost done';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${clampedStep + 1} of $total',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(child: Text(stepLabel, style: theme.textTheme.bodyMedium)),
            if (showSkip && onSkip != null)
              Semantics(
                button: true,
                label: 'Skip this step',
                child: GestureDetector(
                  onTap: onSkip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.sm,
                      vertical: DsSpacing.xs,
                    ),
                    child: Text(
                      'Skip',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: DsColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DsSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor:
                (isDark ? DsColors.textMutedDark : DsColors.textMutedLight)
                    .withValues(alpha: 0.2),
            color: DsColors.primary,
          ),
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          caption ?? nextLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
