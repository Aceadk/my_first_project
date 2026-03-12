import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:equatable/equatable.dart';

enum SubscriptionTransactionStatus {
  idle,
  pending,
  purchased,
  failed,
  restored,
  noPurchases,
}

class SubscriptionState extends Equatable {
  final SubscriptionTier tier;
  final bool purchaseInProgress;
  final String? errorMessage;
  final bool isRestoring;
  final String? statusLabel;
  final DateTime? nextRenewal;
  final bool? cancelAtPeriodEnd;
  final List<SubscriptionProduct> availableProducts;
  final bool isLoadingProducts;
  final String? productsErrorMessage;
  final SubscriptionTransactionStatus transactionStatus;

  const SubscriptionState({
    required this.tier,
    this.purchaseInProgress = false,
    this.errorMessage,
    this.isRestoring = false,
    this.statusLabel,
    this.nextRenewal,
    this.cancelAtPeriodEnd,
    this.availableProducts = const [],
    this.isLoadingProducts = false,
    this.productsErrorMessage,
    this.transactionStatus = SubscriptionTransactionStatus.idle,
  });

  bool get isCheckoutInProgress => purchaseInProgress;

  SubscriptionState copyWith({
    bool? purchaseInProgress,
    SubscriptionTier? tier,
    bool? isCheckoutInProgress,
    Object? errorMessage = _unset,
    bool? isRestoring,
    String? statusLabel,
    Object? nextRenewal = _unset,
    Object? cancelAtPeriodEnd = _unset,
    List<SubscriptionProduct>? availableProducts,
    bool? isLoadingProducts,
    Object? productsErrorMessage = _unset,
    SubscriptionTransactionStatus? transactionStatus,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      purchaseInProgress:
          purchaseInProgress ?? isCheckoutInProgress ?? this.purchaseInProgress,
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
      availableProducts: availableProducts ?? this.availableProducts,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      productsErrorMessage: identical(productsErrorMessage, _unset)
          ? this.productsErrorMessage
          : productsErrorMessage as String?,
      transactionStatus: transactionStatus ?? this.transactionStatus,
    );
  }

  @override
  List<Object?> get props => [
    tier,
    purchaseInProgress,
    errorMessage,
    isRestoring,
    statusLabel,
    nextRenewal,
    cancelAtPeriodEnd,
    availableProducts,
    isLoadingProducts,
    productsErrorMessage,
    transactionStatus,
  ];
}

const _unset = Object();
