import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/presentation/widgets/upsell_widgets.dart';
import 'package:flutter/material.dart';

class DeckErrorStateView extends StatelessWidget {
  const DeckErrorStateView({
    super.key,
    required this.appBar,
    this.retryInSeconds,
    required this.isPlus,
    this.locationLabel,
    this.radiusKm,
    this.onRetry,
    required this.onShowPassportUpsell,
  });

  final PreferredSizeWidget appBar;
  final int? retryInSeconds;
  final bool isPlus;
  final String? locationLabel;
  final double? radiusKm;
  final VoidCallback? onRetry;
  final VoidCallback onShowPassportUpsell;

  @override
  Widget build(BuildContext context) {
    final radiusLabel = radiusKm?.toStringAsFixed(0);
    return Scaffold(
      appBar: appBar,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 72),
              DsGap.md,
              const Text(
                'Trouble loading people',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              DsGap.sm,
              Text(
                'Check your connection and try again.'
                '${locationLabel != null ? '\nLooking near $locationLabel${radiusLabel != null ? ' within ~$radiusLabel km' : ''}.' : ''}',
                textAlign: TextAlign.center,
              ),
              DsGap.lg,
              if (retryInSeconds != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 8),
                  child: Text(
                    'Retrying automatically in ~${retryInSeconds}s',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
                onPressed: onRetry,
              ),
              if (retryInSeconds != null)
                TextButton.icon(
                  icon: const Icon(Icons.timer),
                  label: Text('Auto-retrying in ~${retryInSeconds}s'),
                  onPressed: onRetry,
                ),
              if (!isPlus) ...[
                DsGap.lg,
                OutlinedButton.icon(
                  icon: const Icon(Icons.flight_takeoff),
                  label: Text(AppLocalizations.of(context).tryPassportWithPlus),
                  onPressed: onShowPassportUpsell,
                ),
                DsGap.sm,
                const UpgradeNudgeCard(
                  title: 'Try Plus while we fix this',
                  subtitle:
                      'Unlock offline likes, queue retries, and Passport so you never miss a match.',
                  bullets: [
                    'Intro offer: 50% off your first month',
                    'Unlimited likes & Passport',
                    'Passport to swipe anywhere',
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
