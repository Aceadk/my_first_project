import 'package:equatable/equatable.dart';
import '../../data/models/subscription.dart';

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionWatchStarted extends SubscriptionEvent {}

class PlusCheckoutRequested extends SubscriptionEvent {}

class SubscriptionPlanUpdated extends SubscriptionEvent {
  final SubscriptionPlan plan;
  SubscriptionPlanUpdated(this.plan);

  @override
  List<Object?> get props => [plan];
}
