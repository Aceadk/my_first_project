import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/premium_cta_helper.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/features/subscription/presentation/subscription_management_links.dart';
import 'package:crushhour/features/subscription/presentation/subscription_restore_feedback.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SubscriptionSettingsScreen extends StatelessWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsManageSubscription),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
              listenWhen: didFinishRestore,
              listener: (context, state) {
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  showErrorSnackBar(context, state.errorMessage!);
                  return;
                }

                final feedback = buildSubscriptionRestoreFeedback(
                  state,
                  locale: locale,
                );
                if (feedback.tone == SubscriptionRestoreFeedbackTone.success) {
                  showSuccessSnackBar(context, feedback.message);
                  return;
                }

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(feedback.message)));
              },
              builder: (context, state) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final hasPremium = state.tier.hasPremium;
                final planName = _planName(state.tier);
                final billingEntries = _billingEntries(
                  state,
                  locale: locale,
                  planName: planName,
                );

                return ListView(
                  padding: DsEdgeInsets.allLg,
                  children: [
                    const _SectionHeader(
                      title: 'Current Plan',
                      subtitle:
                          'Review your current access and plan-specific renewal details.',
                    ),
                    _CurrentPlanCard(
                      state: state,
                      planName: planName,
                      locale: locale,
                      isDark: isDark,
                    ),
                    DsGap.lg,
                    const _SectionHeader(
                      title: 'Billing History',
                      subtitle:
                          'Recent verified subscription events for this account.',
                    ),
                    _BillingHistoryCard(
                      entries: billingEntries,
                      emptyMessage:
                          'No billing activity yet. Start or restore a subscription to populate this history.',
                    ),
                    DsGap.lg,
                    const _SectionHeader(
                      title: 'Manage',
                      subtitle:
                          'Change plans, restore purchases, and manage store billing from one place.',
                    ),
                    _ManageSection(
                      state: state,
                      hasPremium: hasPremium,
                      onChangePlan: () => PremiumCtaHelper.showPaywall(
                        context,
                        source: 'subscription_management',
                      ),
                      onOpenSupport: () => context.push(CrushRoutes.support),
                      onRestore: () => context.read<SubscriptionBloc>().add(
                        SubscriptionRestoreRequested(),
                      ),
                      onRefresh: () => context.read<SubscriptionBloc>().add(
                        SubscriptionRestoreRequested(),
                      ),
                      onCancelSubscription: () =>
                          _openSubscriptionManagement(context, state.tier),
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

  static Future<void> _openSubscriptionManagement(
    BuildContext context,
    SubscriptionTier tier,
  ) async {
    final result = await SubscriptionManagementLinks.openManagementPortal(tier);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case SubscriptionManagementLaunchResult.launched:
        return;
      case SubscriptionManagementLaunchResult.unsupported:
        showErrorSnackBar(
          context,
          'Subscription management is available on iOS and Android only.',
        );
      case SubscriptionManagementLaunchResult.failed:
        showErrorSnackBar(context, 'Could not open subscription management.');
    }
  }

  static String _planName(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 'Free',
      SubscriptionTier.plus => 'Plus',
      SubscriptionTier.platinum => 'Platinum',
    };
  }

  static String _subtitle(SubscriptionState state, String locale) {
    final planName = _planName(state.tier);
    if (!state.tier.hasPremium) {
      return 'Free plan - upgrade for unlimited likes and premium controls.';
    }
    if (state.nextRenewal == null) {
      return '$planName Member - Active';
    }
    final prefix = state.cancelAtPeriodEnd == true ? 'Ends' : 'Renews';
    final date = DateTimeFormatter.formatDate(
      state.nextRenewal!,
      locale: locale,
    );
    return '$planName Member - $prefix on $date';
  }

  static List<_BillingEntry> _billingEntries(
    SubscriptionState state, {
    required String locale,
    required String planName,
  }) {
    final entries = <_BillingEntry>[];
    final normalizedStatus = state.statusLabel?.trim().toLowerCase();

    if (state.tier.hasPremium) {
      entries.add(
        _BillingEntry(
          icon: Icons.workspace_premium,
          title: 'Current plan',
          value: '$planName membership is active on this account.',
        ),
      );
    } else if (normalizedStatus == 'expired') {
      entries.add(
        const _BillingEntry(
          icon: Icons.history,
          title: 'Previous plan',
          value: 'Premium access expired and the account is back on Free.',
        ),
      );
    }

    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      entries.add(
        _BillingEntry(
          icon: Icons.verified_outlined,
          title: 'Latest store status',
          value: _humanizeStatus(normalizedStatus),
        ),
      );
    }

    if (state.nextRenewal != null) {
      final formattedDate = DateTimeFormatter.formatDate(
        state.nextRenewal!,
        locale: locale,
      );
      entries.add(
        _BillingEntry(
          icon: state.cancelAtPeriodEnd == true
              ? Icons.event_busy
              : Icons.event_available,
          title: state.cancelAtPeriodEnd == true
              ? 'Access ends'
              : 'Next renewal',
          value: formattedDate,
        ),
      );
    }

    return entries;
  }

  static String _humanizeStatus(String status) {
    return switch (status) {
      'active' => 'Active',
      'trialing' => 'Trial active',
      'none' => 'No active subscription found',
      'expired' => 'Expired',
      'canceled' => 'Cancelled in store',
      _ => 'Status: ${status.toUpperCase()}',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.state,
    required this.planName,
    required this.locale,
    required this.isDark,
  });

  final SubscriptionState state;
  final String planName;
  final String locale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subtitle = SubscriptionSettingsScreen._subtitle(state, locale);
    final renewal = state.nextRenewal;

    return Container(
      padding: DsEdgeInsets.allLg,
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.tier.hasPremium
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
                color: state.tier.hasPremium
                    ? DsColors.primary
                    : DsColors.ink400,
              ),
              DsGap.smH,
              Text(
                state.tier.hasPremium ? '$planName Member' : 'Free Plan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          DsGap.sm,
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
          if (renewal != null) ...[
            DsGap.xs,
            Text(
              'Billing date: ${DateTimeFormatter.formatDate(renewal, locale: locale)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillingHistoryCard extends StatelessWidget {
  const _BillingHistoryCard({
    required this.entries,
    required this.emptyMessage,
  });

  final List<_BillingEntry> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: DsEdgeInsets.allMd,
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DsColors.borderLight),
      ),
      child: entries.isEmpty
          ? Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(entries[index].icon),
                    title: Text(entries[index].title),
                    subtitle: Text(entries[index].value),
                  ),
                  if (index < entries.length - 1)
                    const Divider(height: 8, color: DsColors.borderLight),
                ],
              ],
            ),
    );
  }
}

class _ManageSection extends StatelessWidget {
  const _ManageSection({
    required this.state,
    required this.hasPremium,
    required this.onChangePlan,
    required this.onOpenSupport,
    required this.onRestore,
    required this.onRefresh,
    required this.onCancelSubscription,
  });

  final SubscriptionState state;
  final bool hasPremium;
  final VoidCallback onChangePlan;
  final VoidCallback onOpenSupport;
  final VoidCallback onRestore;
  final VoidCallback onRefresh;
  final Future<void> Function() onCancelSubscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: DsEdgeInsets.allMd,
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DsColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('subscription_management_change_plan_button'),
            onPressed: state.isCheckoutInProgress ? null : onChangePlan,
            icon: const Icon(Icons.swap_horiz),
            label: Text(_primaryPlanActionLabel(state)),
          ),
          DsGap.sm,
          if (hasPremium) ...[
            OutlinedButton.icon(
              key: const Key('subscription_management_cancel_button'),
              onPressed: onCancelSubscription,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                AppLocalizations.of(context).subscriptionCancelSubscription,
              ),
            ),
            DsGap.sm,
            FilledButton.icon(
              onPressed: state.isRestoring ? null : onRefresh,
              key: const Key('subscription_settings_refresh_button'),
              icon: state.isRestoring
                  ? const SizedBox(
                      key: ValueKey<String>(
                        'subscription_settings_restore_loading',
                      ),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                AppLocalizations.of(context).refreshSubscriptionStatus,
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: state.isRestoring ? null : onRestore,
              key: const Key('subscription_settings_restore_button'),
              icon: state.isRestoring
                  ? const SizedBox(
                      key: ValueKey<String>(
                        'subscription_settings_restore_loading',
                      ),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(
                state.isRestoring
                    ? 'Restoring purchases...'
                    : AppLocalizations.of(context).restorePurchases,
              ),
            ),
          ],
          DsGap.sm,
          OutlinedButton.icon(
            onPressed: onOpenSupport,
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(AppLocalizations.of(context).billingHelp),
          ),
          DsGap.sm,
          Text(
            hasPremium
                ? 'Cancellations and renewals are managed through the App Store or Google Play.'
                : 'Use restore if you already paid through the App Store or Google Play.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  String _primaryPlanActionLabel(SubscriptionState state) {
    final normalizedStatus = state.statusLabel?.trim().toLowerCase();
    if (state.cancelAtPeriodEnd == true || normalizedStatus == 'expired') {
      return 'Resubscribe';
    }
    return hasPremium ? 'Change plan' : 'Choose a plan';
  }
}

class _BillingEntry {
  const _BillingEntry({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;
}
