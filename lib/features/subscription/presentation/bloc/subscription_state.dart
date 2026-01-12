import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/subscription.dart';

class SubscriptionState extends Equatable {
  final SubscriptionPlan plan;
  final bool isCheckoutInProgress;
  final String? errorMessage;
  final bool isRestoring;
  final String? statusLabel;
  final DateTime? nextRenewal;
  final bool? cancelAtPeriodEnd;

  const SubscriptionState({
    required this.plan,
    this.isCheckoutInProgress = false,
    this.errorMessage,
    this.isRestoring = false,
    this.statusLabel,
    this.nextRenewal,
    this.cancelAtPeriodEnd,
  });

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    bool? isCheckoutInProgress,
    Object? errorMessage = _unset,
    bool? isRestoring,
    String? statusLabel,
    Object? nextRenewal = _unset,
    Object? cancelAtPeriodEnd = _unset,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      isCheckoutInProgress: isCheckoutInProgress ?? this.isCheckoutInProgress,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isRestoring: isRestoring ?? this.isRestoring,
      statusLabel: statusLabel ?? this.statusLabel,
      nextRenewal: identical(nextRenewal, _unset)
          ? this.nextRenewal
          : nextRenewal as DateTime?,
      cancelAtPeriodEnd: identical(cancelAtPeriodEnd, _unset)
          ? this.cancelAtPeriodEnd
          : cancelAtPeriodEnd as bool?,
    );
  }

  @override
  List<Object?> get props => [
        plan,
        isCheckoutInProgress,
        errorMessage,
        isRestoring,
        statusLabel,
        nextRenewal,
        cancelAtPeriodEnd,
      ];
}

const _unset = Object();
