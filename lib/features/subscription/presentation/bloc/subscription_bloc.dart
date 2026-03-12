import 'dart:async';

import 'package:crushhour/config/billing_config.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/usecases/check_entitlement.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository subscriptionRepository;
  final CheckEntitlementUseCase? checkEntitlementUseCase;
  StreamSubscription<SubscriptionTier>? _sub;
  StreamSubscription? _authSubscription;
  String? _pendingPurchaseProductId;

  SubscriptionBloc({
    required this.subscriptionRepository,
    required AuthRepository authRepository,
    this.checkEntitlementUseCase,
  }) : super(const SubscriptionState(tier: SubscriptionTier.free)) {
    on<SubscriptionWatchStarted>(_onWatchStarted);
    on<SubscriptionProductsRequested>(_onProductsRequested);
    on<SubscriptionPurchaseInitiated>(_onPurchaseInitiated);
    on<SubscriptionCheckoutRequested>(_onSubscriptionCheckoutRequested);
    on<SubscriptionTierUpdated>(_onPlanUpdated);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<SubscriptionTransactionUpdated>(_onTransactionUpdated);
    on<SubscriptionStatusUpdated>(_onStatusUpdated);
    on<SubscriptionResetRequested>(_onResetRequested);

    // Reset subscription state on logout to prevent data leakage
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) add(SubscriptionResetRequested());
    });
  }

  Future<void> _onWatchStarted(
    SubscriptionWatchStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    _sub?.cancel();
    _sub = subscriptionRepository.watchPlan().listen((plan) {
      add(SubscriptionTierUpdated(plan));
    });
  }

  Future<void> _onProductsRequested(
    SubscriptionProductsRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state.isLoadingProducts) {
      return;
    }

    emit(state.copyWith(isLoadingProducts: true, productsErrorMessage: null));

    final result = await Result.guard(
      () => subscriptionRepository.fetchAvailableProducts(),
      logLabel: 'SubscriptionRepository.fetchAvailableProducts',
      fallbackError: 'Unable to load subscription pricing.',
    );

    if (!result.isSuccess || result.data == null) {
      emit(
        state.copyWith(
          isLoadingProducts: false,
          productsErrorMessage: result.errorMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        availableProducts: result.data!,
        isLoadingProducts: false,
        productsErrorMessage: null,
      ),
    );
  }

  Future<void> _onSubscriptionCheckoutRequested(
    SubscriptionCheckoutRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    await _startPurchase(
      emit,
      productId: '${event.tier.name}_${event.period.name}',
      tier: event.tier,
    );
  }

  Future<void> _onPurchaseInitiated(
    SubscriptionPurchaseInitiated event,
    Emitter<SubscriptionState> emit,
  ) async {
    final metadata = _metadataForProductId(event.productId);
    if (metadata == null) {
      await AnalyticsService.instance.logSubscriptionPurchaseFailed(
        tier: 'unknown',
        reason: ErrorMessages.checkoutFailed,
        productId: event.productId,
      );
      emit(
        state.copyWith(
          purchaseInProgress: false,
          errorMessage: ErrorMessages.checkoutFailed,
          transactionStatus: SubscriptionTransactionStatus.failed,
        ),
      );
      return;
    }

    await _startPurchase(emit, productId: event.productId, tier: metadata.tier);
  }

  Future<void> _startPurchase(
    Emitter<SubscriptionState> emit, {
    required String productId,
    required SubscriptionTier tier,
  }) async {
    _pendingPurchaseProductId = productId;
    emit(
      state.copyWith(
        purchaseInProgress: true,
        errorMessage: null,
        transactionStatus: SubscriptionTransactionStatus.pending,
      ),
    );

    await AnalyticsService.instance.logCheckoutStarted(tier: tier.name);

    final purchaseResult = await Result.guard(
      () => subscriptionRepository.purchaseProduct(productId: productId),
      logLabel: 'SubscriptionRepository.purchaseProduct',
      fallbackError: ErrorMessages.checkoutFailed,
    );

    if (!purchaseResult.isSuccess) {
      await AnalyticsService.instance.logSubscriptionPurchaseFailed(
        tier: tier.name,
        reason: purchaseResult.errorMessage ?? ErrorMessages.checkoutFailed,
        productId: productId,
      );
      emit(
        state.copyWith(
          purchaseInProgress: false,
          errorMessage: purchaseResult.errorMessage,
          transactionStatus: SubscriptionTransactionStatus.failed,
        ),
      );
      _pendingPurchaseProductId = null;
      return;
    }

    emit(
      state.copyWith(
        purchaseInProgress: false,
        errorMessage: null,
        transactionStatus: SubscriptionTransactionStatus.pending,
      ),
    );
  }

  Future<void> _onPlanUpdated(
    SubscriptionTierUpdated event,
    Emitter<SubscriptionState> emit,
  ) async {
    checkEntitlementUseCase?.primeCachedTier(event.tier);
    final upgradedFromPendingPurchase =
        state.tier == SubscriptionTier.free &&
        event.tier != SubscriptionTier.free &&
        _pendingPurchaseProductId != null;
    if (upgradedFromPendingPurchase) {
      final pendingProductId = _pendingPurchaseProductId!;
      final trackedProduct = _productForId(pendingProductId);
      await AnalyticsService.instance.logSubscriptionPurchaseCompleted(
        tier: event.tier.name,
        price: trackedProduct?.price ?? 0,
        currency: trackedProduct?.currencyCode ?? 'USD',
        productId: pendingProductId,
      );
      _pendingPurchaseProductId = null;
    }

    emit(
      state.copyWith(
        tier: event.tier,
        purchaseInProgress: false,
        errorMessage: null,
        isRestoring: false,
        transactionStatus: upgradedFromPendingPurchase
            ? SubscriptionTransactionStatus.purchased
            : (event.tier == SubscriptionTier.free
                  ? SubscriptionTransactionStatus.idle
                  : state.transactionStatus),
      ),
    );
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      state.copyWith(
        isRestoring: true,
        errorMessage: null,
        transactionStatus: SubscriptionTransactionStatus.pending,
      ),
    );
    final result = await Result.guard(
      () => subscriptionRepository.restorePurchases(),
      logLabel: 'SubscriptionRepository.restorePurchases',
      fallbackError: ErrorMessages.restorePurchasesFailed,
    );
    if (!result.isSuccess || result.data == null) {
      emit(
        state.copyWith(
          isRestoring: false,
          errorMessage: result.errorMessage,
          transactionStatus: SubscriptionTransactionStatus.failed,
        ),
      );
      return;
    }
    add(SubscriptionStatusUpdated(result.data!));
  }

  void _onTransactionUpdated(
    SubscriptionTransactionUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(
      state.copyWith(
        transactionStatus: event.status,
        errorMessage: event.errorMessage ?? state.errorMessage,
      ),
    );
  }

  Future<void> _onStatusUpdated(
    SubscriptionStatusUpdated event,
    Emitter<SubscriptionState> emit,
  ) async {
    checkEntitlementUseCase?.primeCachedTier(event.status.tier);
    final restoredPremium =
        state.isRestoring && event.status.tier != SubscriptionTier.free;
    final restoredNone =
        state.isRestoring && event.status.tier == SubscriptionTier.free;
    if (restoredPremium) {
      await AnalyticsService.instance.logSubscriptionRestored(
        tier: event.status.tier.name,
      );
    }

    emit(
      state.copyWith(
        tier: event.status.tier,
        isRestoring: false,
        errorMessage: null,
        statusLabel: event.status.status,
        nextRenewal: event.status.nextRenewal,
        cancelAtPeriodEnd: event.status.cancelAtPeriodEnd,
        transactionStatus: restoredPremium
            ? SubscriptionTransactionStatus.restored
            : (restoredNone
                  ? SubscriptionTransactionStatus.noPurchases
                  : state.transactionStatus),
      ),
    );
  }

  void _onResetRequested(
    SubscriptionResetRequested event,
    Emitter<SubscriptionState> emit,
  ) {
    AppLogger.debug('SubscriptionBloc: Resetting state on logout');
    _sub?.cancel();
    _sub = null;
    _pendingPurchaseProductId = null;
    checkEntitlementUseCase?.clearCache();
    emit(const SubscriptionState(tier: SubscriptionTier.free));
  }

  ({SubscriptionTier tier, BillingPeriod period})? _metadataForProductId(
    String productId,
  ) {
    final parts = productId.split('_');
    if (parts.length != 2) {
      return null;
    }

    final tier = switch (parts.first) {
      'plus' => SubscriptionTier.plus,
      'platinum' => SubscriptionTier.platinum,
      _ => null,
    };
    final period = switch (parts.last) {
      'monthly' => BillingPeriod.monthly,
      'quarterly' => BillingPeriod.quarterly,
      'yearly' => BillingPeriod.yearly,
      _ => null,
    };
    if (tier == null || period == null) {
      return null;
    }
    return (tier: tier, period: period);
  }

  SubscriptionProduct? _productForId(String productId) {
    for (final product in state.availableProducts) {
      if (product.productId == productId) {
        return product;
      }
    }

    final metadata = _metadataForProductId(productId);
    if (metadata == null) {
      return null;
    }
    final plan = BillingConfig.tiers.firstWhere(
      (candidate) => candidate.tier == metadata.tier,
      orElse: () => BillingConfig.tiers.first,
    );
    final price = plan.getPriceForPeriod(metadata.period);
    return SubscriptionProduct(
      productId: productId,
      tier: metadata.tier,
      period: metadata.period,
      title: plan.name,
      description: plan.description,
      priceLabel: '\$${price.toStringAsFixed(2)}',
      price: price,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
