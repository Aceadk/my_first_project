import 'package:crushhour/shared/dto/subscription.dart';

class BillingFeature {
  const BillingFeature({required this.name, required this.included});
  final String name;
  final bool included;
}

class BillingPlanConfig {
  const BillingPlanConfig({
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.quarterlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.popular = false,
  });

  final SubscriptionTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final double quarterlyPrice;
  final double yearlyPrice;
  final List<BillingFeature> features;
  final bool popular;

  double getPriceForPeriod(BillingPeriod period) {
    switch (period) {
      case BillingPeriod.monthly:
        return monthlyPrice;
      case BillingPeriod.quarterly:
        return quarterlyPrice;
      case BillingPeriod.yearly:
        return yearlyPrice;
    }
  }

  double getMonthlyEquivalent(BillingPeriod period) {
    switch (period) {
      case BillingPeriod.monthly:
        return monthlyPrice;
      case BillingPeriod.quarterly:
        return quarterlyPrice / 3;
      case BillingPeriod.yearly:
        return yearlyPrice / 12;
    }
  }

  int getSavingsPercentage(BillingPeriod period) {
    if (monthlyPrice == 0 || period == BillingPeriod.monthly) return 0;
    final totalMonthly =
        monthlyPrice * (period == BillingPeriod.yearly ? 12 : 3);
    final discountedPrice = getPriceForPeriod(period);
    return ((1 - discountedPrice / totalMonthly) * 100).round();
  }
}

class BillingConfig {
  static const String successUrl = 'https://crushhour.app/pay/success';
  static const String cancelUrl = 'https://crushhour.app/pay/cancel';

  static const List<BillingPlanConfig> tiers = [
    BillingPlanConfig(
      tier: SubscriptionTier.free,
      name: 'Free',
      description: 'Everything you need to get started',
      monthlyPrice: 0,
      quarterlyPrice: 0,
      yearlyPrice: 0,
      features: [
        BillingFeature(name: 'Unlimited swipes', included: true),
        BillingFeature(name: 'See your matches', included: true),
        BillingFeature(name: 'Send messages', included: true),
        BillingFeature(name: 'Basic discovery filters', included: true),
        BillingFeature(name: 'Profile prompts', included: true),
        BillingFeature(name: 'See who likes you', included: false),
        BillingFeature(name: 'Unlimited rewinds', included: false),
        BillingFeature(name: 'Super likes', included: false),
        BillingFeature(name: 'Passport mode', included: false),
        BillingFeature(name: 'Profile boost', included: false),
        BillingFeature(name: 'Incognito mode', included: false),
        BillingFeature(name: 'Read receipts', included: false),
        BillingFeature(name: 'Priority support', included: false),
      ],
    ),
    BillingPlanConfig(
      tier: SubscriptionTier.plus,
      name: 'Crush+',
      description: 'Unlock premium features',
      monthlyPrice: 9.99,
      quarterlyPrice: 24.99,
      yearlyPrice: 79.99,
      popular: true,
      features: [
        BillingFeature(name: 'Unlimited swipes', included: true),
        BillingFeature(name: 'See your matches', included: true),
        BillingFeature(name: 'Send messages', included: true),
        BillingFeature(name: 'Basic discovery filters', included: true),
        BillingFeature(name: 'Profile prompts', included: true),
        BillingFeature(name: 'See who likes you', included: true),
        BillingFeature(name: 'Unlimited rewinds', included: true),
        BillingFeature(name: '5 Super likes/day', included: true),
        BillingFeature(name: 'Passport mode', included: true),
        BillingFeature(name: '1 Boost/month', included: true),
        BillingFeature(name: 'Incognito mode', included: false),
        BillingFeature(name: 'Read receipts', included: false),
        BillingFeature(name: 'Priority support', included: false),
      ],
    ),
    BillingPlanConfig(
      tier: SubscriptionTier.platinum,
      name: 'Crush Platinum',
      description: 'The ultimate dating experience',
      monthlyPrice: 19.99,
      quarterlyPrice: 49.99,
      yearlyPrice: 149.99,
      features: [
        BillingFeature(name: 'Unlimited swipes', included: true),
        BillingFeature(name: 'See your matches', included: true),
        BillingFeature(name: 'Send messages', included: true),
        BillingFeature(name: 'Advanced discovery filters', included: true),
        BillingFeature(name: 'Profile prompts', included: true),
        BillingFeature(name: 'See who likes you', included: true),
        BillingFeature(name: 'Unlimited rewinds', included: true),
        BillingFeature(name: 'Unlimited Super likes', included: true),
        BillingFeature(name: 'Passport mode', included: true),
        BillingFeature(name: '5 Boosts/month', included: true),
        BillingFeature(name: 'Incognito mode', included: true),
        BillingFeature(name: 'Read receipts', included: true),
        BillingFeature(name: 'Priority support', included: true),
      ],
    ),
  ];
}
