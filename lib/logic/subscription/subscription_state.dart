import 'package:equatable/equatable.dart';
import '../../data/models/subscription.dart';

class SubscriptionState extends Equatable {
  final SubscriptionPlan plan;
  final bool isCheckoutInProgress;
  final String? errorMessage;

  const SubscriptionState({
    required this.plan,
    this.isCheckoutInProgress = false,
    this.errorMessage,
  });

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    bool? isCheckoutInProgress,
    String? errorMessage,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      isCheckoutInProgress: isCheckoutInProgress ?? this.isCheckoutInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [plan, isCheckoutInProgress, errorMessage];
}
