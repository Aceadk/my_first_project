import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class SubscriptionSettingsScreen extends StatelessWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).subscription)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, state) {
                final isPlus = state.plan == SubscriptionPlan.plus;
                final renewal = state.nextRenewal;
                final subtitle = _subtitle(
                  state,
                  Localizations.localeOf(context).toString(),
                );

                return ListView(
                  padding: DsEdgeInsets.allLg,
                  children: [
                    Container(
                      padding: DsEdgeInsets.allLg,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DsColors.surfaceDark
                            : DsColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPlus
                              ? DsColors.primary.withValues(alpha: 0.35)
                              : DsColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: isPlus
                                    ? DsColors.primary
                                    : DsColors.ink400,
                              ),
                              DsGap.smH,
                              Text(
                                isPlus ? 'Plus Member' : 'Free Plan',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          DsGap.sm,
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                ),
                          ),
                          if (renewal != null) ...[
                            DsGap.xs,
                            Text(
                              'Billing date: ${DateTimeFormatter.formatDate(renewal, locale: Localizations.localeOf(context).toString())}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    DsGap.lg,
                    if (isPlus) ...[
                      FilledButton.icon(
                        onPressed: state.isRestoring
                            ? null
                            : () => context.read<SubscriptionBloc>().add(
                                SubscriptionRestoreRequested(),
                              ),
                        icon: state.isRestoring
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          AppLocalizations.of(
                            context,
                          ).refreshSubscriptionStatus,
                        ),
                      ),
                      DsGap.sm,
                      OutlinedButton.icon(
                        onPressed: () => context.push(CrushRoutes.support),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(AppLocalizations.of(context).billingHelp),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: state.isCheckoutInProgress
                            ? null
                            : () => context.read<SubscriptionBloc>().add(
                                PlusCheckoutRequested(),
                              ),
                        icon: state.isCheckoutInProgress
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upgrade),
                        label: Text(AppLocalizations.of(context).upgradeToPlus),
                      ),
                      DsGap.sm,
                      OutlinedButton.icon(
                        onPressed: state.isRestoring
                            ? null
                            : () => context.read<SubscriptionBloc>().add(
                                SubscriptionRestoreRequested(),
                              ),
                        icon: const Icon(Icons.restore),
                        label: Text(
                          AppLocalizations.of(context).restorePurchases,
                        ),
                      ),
                    ],
                    DsGap.lg,
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sell_outlined),
                      title: Text(
                        AppLocalizations.of(context).planDetailsAndPricing,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context).comparePlanBenefits,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(CrushRoutes.pricing),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(SubscriptionState state, String locale) {
    final isPlus = state.plan == SubscriptionPlan.plus;
    if (!isPlus) {
      return 'Free Plan - Upgrade for unlimited likes';
    }
    if (state.nextRenewal == null) {
      return 'Plus Member - Active';
    }
    final prefix = state.cancelAtPeriodEnd == true ? 'Ends' : 'Renews';
    final date = DateTimeFormatter.formatDate(
      state.nextRenewal!,
      locale: locale,
    );
    return 'Plus Member - $prefix on $date';
  }
}
