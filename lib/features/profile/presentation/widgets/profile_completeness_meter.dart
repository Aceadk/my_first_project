import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:flutter/material.dart';

class ProfileCompletenessMeter extends StatelessWidget {
  const ProfileCompletenessMeter({
    super.key,
    required this.profile,
    this.onAction,
  });

  final Profile? profile;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = evaluateProfileCompleteness(profile);
    final percent = (summary.score * 100).round();
    final missing = summary.missing.take(3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Profile completeness',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('$percent%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: summary.score,
              minHeight: 8,
              backgroundColor: DsColors.skeletonLight,
              color: DsColors.primary,
            ),
            const SizedBox(height: 8),
            if (missing.isEmpty)
              Text(
                'Great job! Your profile is ready.',
                style: TextStyle(color: DsColors.success),
              )
            else ...[
              Text(
                'Complete these to unlock messaging and swiping:',
                style: TextStyle(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missing
                    .map(
                      (m) => Chip(
                        label: Text(m),
                        backgroundColor: DsColors.warning
                            .withValues(alpha: isDark ? 0.18 : 0.12),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(
                      missing.isEmpty ? 'Review profile' : 'Finish profile'),
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
