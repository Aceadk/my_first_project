import 'package:flutter/material.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';

class OnboardingNavButtons extends StatelessWidget {
  const OnboardingNavButtons({
    super.key,
    required this.onNext,
    this.onBack,
    this.nextLabel,
    this.backLabel,
    this.nextLoading = false,
    this.showBack = true,
  });

  final VoidCallback? onNext;
  final VoidCallback? onBack;

  /// Defaults to a localized "Next" when null.
  final String? nextLabel;

  /// Defaults to a localized "Previous" when null.
  final String? backLabel;
  final bool nextLoading;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nextLabel = this.nextLabel ?? l10n.commonNext;
    final backLabel = this.backLabel ?? l10n.commonPrevious;
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
          child: OutlinedButton(onPressed: onBack, child: Text(backLabel)),
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
