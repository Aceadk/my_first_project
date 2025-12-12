enum SubscriptionPlan {
  free,
  plus,
}

extension SubscriptionPlanX on SubscriptionPlan {
  bool get isFree => this == SubscriptionPlan.free;
  bool get isPlus => this == SubscriptionPlan.plus;
}
