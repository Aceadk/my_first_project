enum SubscriptionPlan { free, plus }

extension SubscriptionPlanX on SubscriptionPlan {
  bool get isFree => this == SubscriptionPlan.free;
  bool get isPlus => this == SubscriptionPlan.plus;
}

class SubscriptionStatus {
  SubscriptionStatus({
    required this.plan,
    this.status,
    this.nextRenewal,
    this.cancelAtPeriodEnd = false,
  });

  final SubscriptionPlan plan;
  final String? status;
  final DateTime? nextRenewal;
  final bool cancelAtPeriodEnd;
}
