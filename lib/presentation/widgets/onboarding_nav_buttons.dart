import 'package:flutter/material.dart';
import 'primary_button.dart';

class OnboardingNavButtons extends StatelessWidget {
  const OnboardingNavButtons({
    super.key,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Next',
    this.backLabel = 'Previous',
    this.nextLoading = false,
    this.showBack = true,
  });

  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final String backLabel;
  final bool nextLoading;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    if (!showBack) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: nextLabel,
          loading: nextLoading,
          onPressed: onNext,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            child: Text(backLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: nextLabel,
            loading: nextLoading,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
