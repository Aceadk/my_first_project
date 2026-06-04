import 'package:flutter/material.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

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

  /// Number of onboarding steps; labels are resolved per-locale in [build].
  static const int stepCount = 6;

  /// Localized label for the step at [index].
  static String _stepLabel(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.onboardingStepWelcome;
      case 1:
        return l10n.onboardingStepVerifyPhone;
      case 2:
        return l10n.onboardingStepEnterCode;
      case 3:
        return l10n.onboardingStepBasicInfo;
      case 4:
        return l10n.onboardingStepVerifyId;
      default:
        return l10n.onboardingStepProfileSetup;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    const total = stepCount;
    final clampedStep = currentStep.clamp(0, total - 1);
    final progress = (clampedStep + 1) / total;
    final stepLabel = _stepLabel(l10n, clampedStep);
    final nextLabel = clampedStep + 1 < total
        ? l10n.onboardingProgressNextStep(_stepLabel(l10n, clampedStep + 1))
        : l10n.onboardingProgressAlmostDone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Counter + step name as a single ellipsizable rich text so a long
            // step name or large text scale can't overflow the header row; the
            // Expanded also keeps "Skip" pinned to the trailing edge
            // (ONBOARD-UI-003).
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.onboardingStep(clampedStep + 1, total)}  ',
                      style: theme.textTheme.labelLarge,
                    ),
                    TextSpan(
                      text: stepLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showSkip && onSkip != null)
              Semantics(
                button: true,
                label: l10n.onboardingProgressSkipStep,
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.sm,
                        vertical: DsSpacing.xs,
                      ),
                      child: Text(
                        l10n.commonSkip,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: DsColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
