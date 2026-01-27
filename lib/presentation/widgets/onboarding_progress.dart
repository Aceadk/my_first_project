import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';

/// Shared onboarding progress indicator used across splash/auth/setup screens.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.caption,
  });

  /// Zero-based index into [onboardingSteps].
  final int currentStep;
  final String? caption;

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
            Text(stepLabel, style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: DsSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(DsRadius.chip),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: (isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight)
                .withValues(alpha: 0.2),
            color: DsColors.primary,
          ),
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          caption ?? nextLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color:
                isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
