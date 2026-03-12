import 'package:crushhour/config/billing_config.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/presentation/subscription_restore_feedback.dart';
import 'package:crushhour/shared/dto/subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.source});

  final String? source;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.plus;
  int _selectedPeriodIndex = 1; // 0=monthly, 1=quarterly, 2=yearly
  SubscriptionState? _previousSubscriptionState;
  bool _requestedProducts = false;

  static const _periods = ['1 Month', '3 Months', '12 Months'];

  @override
  void initState() {
    super.initState();
    // Default to the first paid tier available if 'plus' is not in the config (unlikely)
    final availableTiers = BillingConfig.tiers
        .where((t) => t.tier != SubscriptionTier.free)
        .toList();
    if (availableTiers.isNotEmpty &&
        !availableTiers.any((t) => t.tier == SubscriptionTier.plus)) {
      _selectedTier = availableTiers.first.tier;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _previousSubscriptionState ??= context.read<SubscriptionBloc>().state;
    if (!_requestedProducts) {
      context.read<SubscriptionBloc>().add(SubscriptionProductsRequested());
      _requestedProducts = true;
    }
  }

  void _handleSubscribe() {
    final selectedProductId =
        '${_selectedTier.name}_${_getBillingPeriod().name}';
    context.read<SubscriptionBloc>().add(
      SubscriptionPurchaseInitiated(selectedProductId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    final availableTiers = BillingConfig.tiers
        .where((t) => t.tier != SubscriptionTier.free)
        .toList();
    final comparisonFeatures = _comparisonFeatureNames(availableTiers);
    final activePlanConfig = availableTiers.firstWhere(
      (t) => t.tier == _selectedTier,
      orElse: () => availableTiers.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Get Premium')),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (previous, current) {
          return previous.isCheckoutInProgress !=
                  current.isCheckoutInProgress ||
              previous.isRestoring != current.isRestoring ||
              previous.errorMessage != current.errorMessage ||
              previous.productsErrorMessage != current.productsErrorMessage ||
              previous.tier != current.tier ||
              previous.statusLabel != current.statusLabel ||
              previous.nextRenewal != current.nextRenewal ||
              previous.cancelAtPeriodEnd != current.cancelAtPeriodEnd;
        },
        listener: (context, state) {
          final previous = _previousSubscriptionState ?? state;
          _previousSubscriptionState = state;
          final finishedRestore = didFinishRestore(previous, state);
          final finishedCheckout =
              previous.isCheckoutInProgress && !state.isCheckoutInProgress;

          if (previous.productsErrorMessage != state.productsErrorMessage &&
              state.productsErrorMessage != null &&
              state.productsErrorMessage!.isNotEmpty) {
            showErrorSnackBar(context, state.productsErrorMessage!);
          }

          if (finishedRestore) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              showErrorSnackBar(context, state.errorMessage!);
            } else {
              final feedback = buildSubscriptionRestoreFeedback(
                state,
                locale: Localizations.localeOf(context).toString(),
              );
              if (feedback.tone == SubscriptionRestoreFeedbackTone.success) {
                showSuccessSnackBar(context, feedback.message);
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(feedback.message)));
              }
            }

            if (state.tier != SubscriptionTier.free) {
              context.go(CrushRoutes.home);
            }
            return;
          }

          if (finishedCheckout && state.tier != SubscriptionTier.free) {
            context.go(CrushRoutes.home);
          } else if (finishedCheckout &&
              state.errorMessage != null &&
              !state.isCheckoutInProgress) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final isLoading = state.isCheckoutInProgress;

          return LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  children: [
                    Text(
                      'Unlock Your Best Dating Life',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    Text(
                      'Choose the tier that gives you the best chances.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                    ),
                    const SizedBox(height: DsSpacing.xl),

                    // Tier Selection Toggle
                    if (availableTiers.length > 1)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceDark
                              : DsColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? DsColors.borderDark
                                : DsColors.borderLight,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: DsSpacing.xl),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: availableTiers.map((plan) {
                            final isSelected = _selectedTier == plan.tier;
                            return Expanded(
                              child: Semantics(
                                button: true,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTier = plan.tier),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? DsColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      plan.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Features Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? DsColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? DsColors.borderDark
                              : DsColors.borderLight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [DsColors.primary, DsColors.secondary],
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                            ),
                            child: Text(
                              '${activePlanConfig.name} Features',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(DsSpacing.md),
                            child: Column(
                              children: activePlanConfig.features.map((
                                feature,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          feature.name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      if (feature.included == true ||
                                          feature.included.toString() !=
                                              'false')
                                        const Icon(
                                          Icons.check,
                                          color: DsColors.primary,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.close,
                                          color: DsColors.borderDark,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DsSpacing.xl),
                    _ComparisonGrid(
                      plans: availableTiers,
                      featureNames: comparisonFeatures,
                    ),
                    const SizedBox(height: DsSpacing.xl),
                    Text(
                      'Choose Your Billing Period',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.md),

                    // Period Selection
                    Column(
                      children: List.generate(_periods.length, (index) {
                        final isSelected = _selectedPeriodIndex == index;
                        final period = _getPeriodFromIndex(index);
                        final resolvedProduct = _resolvedProduct(state, period);
                        final price =
                            resolvedProduct?.price ??
                            activePlanConfig.getPriceForPeriod(period);
                        final priceLabel =
                            resolvedProduct?.priceLabel ??
                            _formatPrice(context, price);
                        final savings = activePlanConfig.getSavingsPercentage(
                          period,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: DsSpacing.md),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPeriodIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(DsSpacing.lg),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DsColors.primary.withValues(alpha: 0.1)
                                    : (isDark
                                          ? DsColors.surfaceDark
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? DsColors.primary
                                      : (isDark
                                            ? DsColors.borderDark
                                            : DsColors.borderLight),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _periods[index],
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (savings > 0)
                                          Text(
                                            'Save $savings%',
                                            style: const TextStyle(
                                              color: DsColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        priceLabel,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '/${_periods[index]}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: DsSpacing.xl),

                    // Subscribe Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _handleSubscribe,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Get ${activePlanConfig.name} for ${_resolvedProduct(state, _getBillingPeriod())?.priceLabel ?? _formatPrice(context, activePlanConfig.getPriceForPeriod(_getBillingPeriod()))}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    Text(
                      'Recurring billing. Cancel anytime in settings.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    TextButton.icon(
                      key: const Key('paywall_restore_button'),
                      onPressed: state.isRestoring
                          ? null
                          : () => context.read<SubscriptionBloc>().add(
                              SubscriptionRestoreRequested(),
                            ),
                      icon: state.isRestoring
                          ? const SizedBox(
                              key: Key('paywall_restore_loading'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore),
                      label: Text(
                        state.isRestoring
                            ? 'Restoring purchases...'
                            : 'Restore purchases',
                      ),
                    ),
                    const SizedBox(height: DsSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: DsSpacing.sm,
                      runSpacing: DsSpacing.xs,
                      children: [
                        TextButton(
                          key: const Key('paywall_terms_button'),
                          onPressed: () =>
                              context.push(CrushRoutes.termsOfService),
                          child: const Text('Terms of Service'),
                        ),
                        TextButton(
                          key: const Key('paywall_privacy_button'),
                          onPressed: () =>
                              context.push(CrushRoutes.privacyPolicy),
                          child: const Text('Privacy Policy'),
                        ),
                      ],
                    ),
                    Text(
                      'Billing and trial terms are managed through the App Store or Google Play on mobile devices.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),

                    const SizedBox(height: DsSpacing.xxl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BillingPeriod _getPeriodFromIndex(int index) {
    switch (index) {
      case 1:
        return BillingPeriod.quarterly;
      case 2:
        return BillingPeriod.yearly;
      default:
        return BillingPeriod.monthly;
    }
  }

  BillingPeriod _getBillingPeriod() {
    return _getPeriodFromIndex(_selectedPeriodIndex);
  }

  String _formatPrice(BuildContext context, double price) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: 'USD',
    ).format(price);
  }

  SubscriptionProduct? _resolvedProduct(
    SubscriptionState state,
    BillingPeriod period,
  ) {
    for (final product in state.availableProducts) {
      if (product.tier == _selectedTier && product.period == period) {
        return product;
      }
    }
    return null;
  }

  List<String> _comparisonFeatureNames(List<BillingPlanConfig> plans) {
    final names = <String>[];
    for (final plan in plans) {
      for (final feature in plan.features) {
        if (!names.contains(feature.name)) {
          names.add(feature.name);
        }
      }
    }
    return names;
  }
}

class _ComparisonGrid extends StatelessWidget {
  const _ComparisonGrid({required this.plans, required this.featureNames});

  final List<BillingPlanConfig> plans;
  final List<String> featureNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: const Key('paywall_comparison_grid'),
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? DsColors.borderDark : DsColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare premium features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            'See which plan unlocks the features that matter most.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.4),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const _ComparisonHeaderCell(
                    label: 'Feature',
                    alignStart: true,
                  ),
                  for (final plan in plans)
                    _ComparisonHeaderCell(label: plan.name),
                ],
              ),
              for (final featureName in featureNames)
                TableRow(
                  children: [
                    _ComparisonValueCell(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(featureName),
                      ),
                    ),
                    for (final plan in plans)
                      _ComparisonValueCell(
                        child: Icon(
                          _featureIncluded(plan, featureName)
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          color: _featureIncluded(plan, featureName)
                              ? DsColors.primary
                              : DsColors.ink400,
                          size: 18,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _featureIncluded(BillingPlanConfig plan, String featureName) {
    final match = plan.features.where((feature) => feature.name == featureName);
    if (match.isEmpty) {
      return false;
    }
    return match.first.included;
  }
}

class _ComparisonHeaderCell extends StatelessWidget {
  const _ComparisonHeaderCell({required this.label, this.alignStart = false});

  final String label;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Align(
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        child: Text(
          label,
          textAlign: alignStart ? TextAlign.left : TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ComparisonValueCell extends StatelessWidget {
  const _ComparisonValueCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(child: child),
    );
  }
}
