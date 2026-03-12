import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Uri _iosManageSubscriptionsUri = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );

  Future<void> _openManageSubscriptions() async {
    try {
      final Uri? manageSubscriptionsUri = await _manageSubscriptionsUri();
      if (manageSubscriptionsUri == null) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Subscription management is available on iOS and Android only.',
        );
        return;
      }

      final didLaunch = await launchUrl(
        manageSubscriptionsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && mounted) {
        showErrorSnackBar(context, 'Could not open subscription management.');
      }
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Could not open subscription management.');
    }
  }

  Future<Uri?> _manageSubscriptionsUri() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _iosManageSubscriptionsUri;
      case TargetPlatform.android:
        const playBaseUrl =
            'https://play.google.com/store/account/subscriptions';
        final packageName = (await PackageInfo.fromPlatform()).packageName
            .trim();
        if (packageName.isEmpty) {
          return Uri.parse('$playBaseUrl?sku=plus_monthly');
        }
        return Uri.parse('$playBaseUrl?sku=plus_monthly&package=$packageName');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final isPlus = state.tier.hasPremium;
            final isLoading = state.isCheckoutInProgress;
            final tierLabel = switch (state.tier) {
              SubscriptionTier.free => 'Free',
              SubscriptionTier.plus => 'Plus',
              SubscriptionTier.platinum => 'Platinum',
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current tier: $tierLabel',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (!isPlus)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<SubscriptionBloc>().add(
                                SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly),
                              );
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  DsColors.surfaceLight,
                                ),
                              ),
                            )
                          : const Text('Upgrade to Crush Plus'),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You have Crush Plus. Enjoy unlimited likes and unsend.',
                        style: TextStyle(color: DsColors.success),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _openManageSubscriptions,
                          child: const Text('Manage Subscription'),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
