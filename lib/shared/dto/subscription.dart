enum SubscriptionTier { free, plus, platinum }

extension SubscriptionTierX on SubscriptionTier {
  bool get isFree => this == SubscriptionTier.free;
  bool get isPlus => this == SubscriptionTier.plus;
  bool get isPlatinum => this == SubscriptionTier.platinum;
  bool get hasPremium => this != SubscriptionTier.free;
}

enum BillingPeriod { monthly, quarterly, yearly }

class SubscriptionStatus {
  SubscriptionStatus({
    required this.tier,
    this.period,
    this.status,
    this.nextRenewal,
    this.cancelAtPeriodEnd = false,
  });

  final SubscriptionTier tier;
  final BillingPeriod? period;
  final String? status;
  final DateTime? nextRenewal;
  final bool cancelAtPeriodEnd;
}
