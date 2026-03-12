import 'package:crushhour/data/models/subscription.dart';
import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionWatchStarted extends SubscriptionEvent {}

class SubscriptionCheckoutRequested extends SubscriptionEvent {
  final SubscriptionTier tier;
  final BillingPeriod period;
  SubscriptionCheckoutRequested(this.tier, this.period);

  @override
  List<Object?> get props => [tier, period];
}

class SubscriptionTierUpdated extends SubscriptionEvent {
  final SubscriptionTier tier;
  SubscriptionTierUpdated(this.tier);

  @override
  List<Object?> get props => [tier];
}

class SubscriptionRestoreRequested extends SubscriptionEvent {}

class SubscriptionResetRequested extends SubscriptionEvent {}

class SubscriptionStatusUpdated extends SubscriptionEvent {
  final SubscriptionStatus status;
  SubscriptionStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}
