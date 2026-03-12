import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/features/subscription/presentation/widgets/promo_code_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsSubscriptionPanelSection extends StatelessWidget {
  const SettingsSubscriptionPanelSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
        }
      },
      builder: (context, subState) {
        final isPlus = subState.tier.hasPremium;
        final loading = subState.isCheckoutInProgress;
        final statusLabel = subState.statusLabel;
        final renewal = subState.nextRenewal;
        final cancelAtPeriodEnd = subState.cancelAtPeriodEnd == true;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: DsColors.primary,
                      ),
                    ),
                    DsGap.mdH,
                    Text(
                      l10n.settingsSubscription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                DsGap.md,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPlus
                        ? DsColors.primary.withValues(alpha: 0.1)
                        : (isDark
                              ? DsColors.surfaceDark
                              : DsColors.surfaceLight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPlus ? l10n.subscriptionPlus : l10n.subscriptionFree,
                    style: TextStyle(
                      color: isPlus ? DsColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (statusLabel != null || renewal != null) ...[
                  DsGap.sm,
                  Text(
                    [
                      if (statusLabel != null)
                        l10n.settingsSubscriptionStatus(
                          statusLabel.toUpperCase(),
                        ),
                      if (renewal != null)
                        cancelAtPeriodEnd
                            ? l10n.settingsSubscriptionAccessEndsOn(
                                _formatDate(renewal),
                              )
                            : l10n.settingsSubscriptionRenewsOn(
                                _formatDate(renewal),
                              ),
                    ].join(' - '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ],
                DsGap.sm,
                Text(
                  isPlus
                      ? l10n.settingsSubscriptionManageBillingSubtitle
                      : l10n.settingsSubscriptionUpgradePitchSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
                if (!isPlus) ...[
                  DsGap.md,
                  Container(
                    padding: DsEdgeInsets.allSm,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.primary.withValues(alpha: 0.1),
                          DsColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer,
                          size: 16,
                          color: DsColors.primary,
                        ),
                        DsGap.smH,
                        Expanded(
                          child: Text(
                            l10n.settingsSubscriptionFirstMonthDiscount,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                DsGap.md,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () {
                            if (isPlus) {
                              context.push(CrushRoutes.subscriptionSettings);
                              return;
                            }
                            context.read<SubscriptionBloc>().add(
                              SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly),
                            );
                          },
                    child: loading
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
                        : Text(
                            isPlus
                                ? l10n.settingsManageSubscription
                                : l10n.upgradeToPlus,
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: subState.isRestoring
                          ? null
                          : () => context.read<SubscriptionBloc>().add(
                              SubscriptionRestoreRequested(),
                            ),
                      child: subState.isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.restore),
                    ),
                    const Text('•', style: TextStyle(color: DsColors.ink300)),
                    TextButton.icon(
                      onPressed: () => PromoCodeSheet.show(context),
                      icon: const Icon(Icons.card_giftcard, size: 16),
                      label: Text(l10n.promoCode),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
