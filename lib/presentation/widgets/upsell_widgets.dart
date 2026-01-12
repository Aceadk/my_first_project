import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
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
    return Card(
      elevation: 0,
      color: Colors.blueGrey.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IntroBadge(),
                DsGap.smH,
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 10),
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
                            context
                                .read<SubscriptionBloc>()
                                .add(PlusCheckoutRequested());
                          },
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isPlus ? 'Thanks for being Plus!' : 'Upgrade now'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Intro offer',
        style: TextStyle(
          color: Colors.pink,
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
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
