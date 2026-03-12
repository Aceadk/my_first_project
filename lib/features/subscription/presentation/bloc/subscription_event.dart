import 'package:crushhour/data/models/subscription.dart';
import 'package:equatable/equatable.dart';

import 'subscription_state.dart';

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionWatchStarted extends SubscriptionEvent {}

class SubscriptionProductsRequested extends SubscriptionEvent {}

class SubscriptionPurchaseInitiated extends SubscriptionEvent {
  SubscriptionPurchaseInitiated(this.productId);

  factory SubscriptionPurchaseInitiated.forSelection(
    SubscriptionTier tier,
    BillingPeriod period,
  ) {
    return SubscriptionPurchaseInitiated('${tier.name}_${period.name}');
  }

  final String productId;

  @override
  List<Object?> get props => [productId];
}

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

class SubscriptionTransactionUpdated extends SubscriptionEvent {
  SubscriptionTransactionUpdated(this.status, {this.errorMessage});

  final SubscriptionTransactionStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}

class SubscriptionStatusUpdated extends SubscriptionEvent {
  final SubscriptionStatus status;
  SubscriptionStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}
