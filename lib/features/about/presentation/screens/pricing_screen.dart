import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  int _selectedPeriod = 0; // 0=monthly, 1=quarterly, 2=yearly

  static const _periods = ['Monthly', '3 Months', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).pricing)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: ListView(
              padding: const EdgeInsets.all(DsSpacing.lg),
              children: [
                Text(
                  'Choose Your Perfect Plan',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Text(
                  'Start for free and upgrade anytime to unlock premium features.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                ),
                const SizedBox(height: DsSpacing.xl),

                // Billing period toggle
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
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: List.generate(_periods.length, (index) {
                      final isSelected = _selectedPeriod == index;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPeriod = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DsColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _periods[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected ? Colors.white : muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: DsSpacing.xl),

                // Free Plan
                _PlanCard(
                  title: 'Free',
                  price: '\$0',
                  period: 'forever',
                  description: 'Get started with the basics',
                  features: const [
                    'Unlimited swipes',
                    'See your matches',
                    'Send messages',
                    'Basic discovery filters',
                    'Profile prompts',
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: DsSpacing.lg),

                // Crush+ Plan
                _PlanCard(
                  title: 'Crush+',
                  price: _crushPlusPrice,
                  period: _periodLabel,
                  savings: _crushPlusSavings,
                  description: 'Our most popular plan',
                  isPopular: true,
                  features: const [
                    'Everything in Free',
                    'See who likes you',
                    'Unlimited rewinds',
                    '5 Super Likes per day',
                    'Passport mode',
                    '1 Boost per month',
                    'No ads',
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: DsSpacing.lg),

                // Crush Platinum Plan
                _PlanCard(
                  title: 'Crush Platinum',
                  price: _platinumPrice,
                  period: _periodLabel,
                  savings: _platinumSavings,
                  description: 'The ultimate experience',
                  features: const [
                    'Everything in Crush+',
                    'Unlimited Super Likes',
                    '5 Boosts per month',
                    'Incognito mode',
                    'Read receipts',
                    'Advanced filters',
                    'Priority support',
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: DsSpacing.xxl),

                // Guarantees
                Container(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DsColors.surfaceDark
                        : DsColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? DsColors.borderDark
                          : DsColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: DsColors.success,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Text(
                              '7-day money-back guarantee',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DsSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: DsColors.info,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Text(
                              'Cancel anytime, no hidden fees',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DsSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card_outlined,
                            color: DsColors.warning,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Text(
                              'Secure payment via App Store / Google Play',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DsSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _crushPlusPrice {
    switch (_selectedPeriod) {
      case 1:
        return '\$24.99';
      case 2:
        return '\$79.99';
      default:
        return '\$9.99';
    }
  }

  String get _platinumPrice {
    switch (_selectedPeriod) {
      case 1:
        return '\$49.99';
      case 2:
        return '\$149.99';
      default:
        return '\$19.99';
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 1:
        return '/ 3 months';
      case 2:
        return '/ year';
      default:
        return '/ month';
    }
  }

  String? get _crushPlusSavings {
    switch (_selectedPeriod) {
      case 1:
        return 'Save 17%';
      case 2:
        return 'Save 33%';
      default:
        return null;
    }
  }

  String? get _platinumSavings {
    switch (_selectedPeriod) {
      case 1:
        return 'Save 17%';
      case 2:
        return 'Save 37%';
      default:
        return null;
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.isDark,
    this.isPopular = false,
    this.savings,
  });

  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool isDark;
  final bool isPopular;
  final String? savings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? DsColors.primary
              : (isDark ? DsColors.borderDark : DsColors.borderLight),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: DsColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPopular) ...[
                DsGap.smH,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DsColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPopular ? DsColors.primary : null,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4),
                child: Text(
                  period,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              if (savings != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DsColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    savings!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DsColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: DsSpacing.lg),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: isPopular ? DsColors.primary : DsColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(feature, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
