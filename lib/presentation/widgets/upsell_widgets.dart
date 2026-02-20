import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';

/// A card that promotes upgrading to Plus subscription.
class UpgradeNudgeCard extends StatelessWidget {
  const UpgradeNudgeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark
          ? DsColors.surfaceElevatedDark
          : DsColors.surfaceElevatedLight,
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IntroBadge(),
                DsGap.smH,
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DsSpacing.sm),
            UpsellBullets(items: bullets),
            DsGap.md,
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subState) {
                final loading = subState.isCheckoutInProgress;
                final isPlus = subState.plan == SubscriptionPlan.plus;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading || isPlus
                        ? null
                        : () {
                            context.read<SubscriptionBloc>().add(
                              PlusCheckoutRequested(),
                            );
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isPlus ? 'Thanks for being Plus!' : 'Upgrade now',
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A badge indicating an intro/promotional offer.
class IntroBadge extends StatelessWidget {
  const IntroBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: DsColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DsRadius.chip),
      ),
      child: const Text(
        'Intro offer',
        style: TextStyle(
          color: DsColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// A list of bullet points for upsell messages.
class UpsellBullets extends StatelessWidget {
  const UpsellBullets({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: DsColors.success,
                  ),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
