import 'package:crushhour/data/models/subscription.dart';
import 'package:equatable/equatable.dart';

class SubscriptionState extends Equatable {
  final SubscriptionTier tier;
  final bool isCheckoutInProgress;
  final String? errorMessage;
  final bool isRestoring;
  final String? statusLabel;
  final DateTime? nextRenewal;
  final bool? cancelAtPeriodEnd;

  const SubscriptionState({
    required this.tier,
    this.isCheckoutInProgress = false,
    this.errorMessage,
    this.isRestoring = false,
    this.statusLabel,
    this.nextRenewal,
    this.cancelAtPeriodEnd,
  });

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isCheckoutInProgress,
    Object? errorMessage = _unset,
    bool? isRestoring,
    String? statusLabel,
    Object? nextRenewal = _unset,
    Object? cancelAtPeriodEnd = _unset,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
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
    tier,
    isCheckoutInProgress,
    errorMessage,
    isRestoring,
    statusLabel,
    nextRenewal,
    cancelAtPeriodEnd,
  ];
}

const _unset = Object();
