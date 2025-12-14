import 'package:flutter/material.dart';

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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(stepLabel),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.withAlpha((0.15 * 255).round()),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption ?? nextLabel,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
