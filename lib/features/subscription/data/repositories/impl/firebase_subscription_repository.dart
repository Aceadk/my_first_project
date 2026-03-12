import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/config/billing_config.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

typedef GooglePurchaseTokenVerifier =
    Future<Map<String, dynamic>> Function({
      required String productId,
      required String purchaseToken,
    });

typedef AppleTransactionVerifier =
    Future<Map<String, dynamic>> Function({
      required String productId,
      required String transactionId,
    });

typedef PurchaseReceiptVerifier =
    Future<Map<String, dynamic>> Function({
      required String platform,
      required String receiptData,
      required String productId,
      String? packageName,
    });

/// Firebase implementation of SubscriptionRepository.
/// Includes fallback demo promo codes when Cloud Functions are not deployed.
class FirebaseSubscriptionRepository implements SubscriptionRepository {
  FirebaseSubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    NativeBillingService? nativeBillingService,
    PurchaseReceiptVerifier? purchaseReceiptVerifier,
    GooglePurchaseTokenVerifier? googlePurchaseTokenVerifier,
    AppleTransactionVerifier? appleTransactionVerifier,
  }) : _firestoreOverride = firestore,
       _functionsOverride = functions,
       _authOverride = auth,
       _nativeBillingService =
           nativeBillingService ?? InAppPurchaseNativeBillingService(),
       _purchaseReceiptVerifier = purchaseReceiptVerifier,
       _googlePurchaseTokenVerifier = googlePurchaseTokenVerifier,
       _appleTransactionVerifier = appleTransactionVerifier;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final FirebaseAuth? _authOverride;
  final NativeBillingService _nativeBillingService;
  final PurchaseReceiptVerifier? _purchaseReceiptVerifier;
  final GooglePurchaseTokenVerifier? _googlePurchaseTokenVerifier;
  final AppleTransactionVerifier? _appleTransactionVerifier;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  bool get _requiresNativeMobilePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  bool get _isAndroidNativeMobilePurchase =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIosNativeMobilePurchase =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String get _nativeReceiptPlatform =>
      _isAndroidNativeMobilePurchase ? 'android' : 'ios';

  // Keys for local promo code storage (fallback)
  static const _redeemedCodesKey = 'redeemed_promo_codes_firebase';
  static const _localPlanKey = 'firebase_local_subscription_plan';

  /// Demo promo codes for testing when Cloud Functions are not available.
  static const Map<String, PromoCode> _demoCodes = {
    'WELCOME50': PromoCode(
      code: 'WELCOME50',
      type: PromoCodeType.discount,
      description: '50% off your first month of Plus',
      discountPercent: 50,
    ),
    'FREEWEEK': PromoCode(
      code: 'FREEWEEK',
      type: PromoCodeType.freeTrial,
      description: '7 days free trial of Plus',
      freeTrialDays: 7,
    ),
    'CRUSH2024': PromoCode(
      code: 'CRUSH2024',
      type: PromoCodeType.combined,
      description: 'Special launch offer: 30% off + 10 bonus likes',
      discountPercent: 30,
      bonusLikes: 10,
    ),
    'SUPERLOVE': PromoCode(
      code: 'SUPERLOVE',
      type: PromoCodeType.bonusSuperLikes,
      description: '5 bonus Super Likes',
      bonusSuperLikes: 5,
    ),
    'CRUSHFREE': PromoCode(
      code: 'CRUSHFREE',
      type: PromoCodeType.discount,
      description: '100% off - Completely free Plus membership!',
      discountPercent: 100,
    ),
  };

  @override
  Stream<SubscriptionTier> watchPlan() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(SubscriptionTier.free);
    }

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return SubscriptionTier.free;
      final data = doc.data();
      return _tierFromPlan(data?['plan'] as String?);
    });
  }

  @override
  Future<SubscriptionTier> getCurrentPlan() async {
    final userId = _currentUserId;
    if (userId == null) return SubscriptionTier.free;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return SubscriptionTier.free;

    return _tierFromPlan(doc.data()?['plan'] as String?);
  }

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (_requiresNativeMobilePurchase) {
      await purchaseProduct(productId: '${tier.name}_${period.name}');
      return;
    }

    // Start checkout and launch the URL
    final url = await startCheckout(tier: tier, period: period);
    await launchCheckoutUrl(url);
  }

  @override
  Future<void> purchaseProduct({required String productId}) async {
    if (!_requiresNativeMobilePurchase) {
      final selection = subscriptionSelectionForProductId(productId);
      if (selection == null) {
        throw UnsupportedError('Unknown subscription product: $productId');
      }
      await purchaseSubscription(
        tier: selection.tier,
        period: selection.period,
      );
      return;
    }

    final purchase = await _nativeBillingService.purchaseProduct(
      productId: productId,
    );
    final status = await verifyPurchaseReceipt(
      platform: _nativeReceiptPlatform,
      receiptData: _receiptDataForPurchase(purchase),
      productId: purchase.productId,
    );

    if (!status.tier.hasPremium) {
      throw StateError(
        'Purchase verification did not activate premium access.',
      );
    }
  }

  @override
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (_requiresNativeMobilePurchase) {
      throw UnsupportedError(
        'Mobile checkout must use native in-app purchase flow.',
      );
    }

    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call<Map<String, dynamic>>({
      'priceId':
          'price_${tier.name}_${period.name}', // Configure your Stripe price ID
      'successUrl': 'https://crushhour.app/checkout/success',
      'cancelUrl': 'https://crushhour.app/checkout/cancel',
    });

    final url = result.data['url'] as String?;
    if (url == null) throw Exception('No checkout URL returned');
    return url;
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    if (_requiresNativeMobilePurchase) {
      throw UnsupportedError(
        'Mobile checkout must use native in-app purchase flow.',
      );
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch checkout URL');
    }
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    if (_requiresNativeMobilePurchase) {
      return _refreshNativePurchaseStatus();
    }

    try {
      final callable = _functions.httpsCallable('syncSubscriptionStatus');
      final result = await callable.call<Map<String, dynamic>>();

      final data = result.data;
      final tier = _tierFromPlan(data['plan'] as String?);

      return SubscriptionStatus(
        tier: tier,
        status: data['status'] as String?,
        nextRenewal: _parseTimestamp(data['nextRenewal']),
        cancelAtPeriodEnd: data['cancelAtPeriodEnd'] as bool? ?? false,
      );
    } catch (e) {
      // Return current status on error
      final tier = await getCurrentPlan();
      return SubscriptionStatus(
        tier: tier,
        status: tier.hasPremium ? 'active' : null,
      );
    }
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    if (_requiresNativeMobilePurchase) {
      return _refreshNativePurchaseStatus();
    }
    return refreshStatus();
  }

  @override
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) async {
    final payload = await _invokePurchaseReceiptVerifier(
      platform: platform,
      receiptData: receiptData,
      productId: productId,
      packageName: packageName,
    );
    return _subscriptionStatusFromGooglePayload(payload);
  }

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async {
    if (_requiresNativeMobilePurchase) {
      final productDetails = await _nativeBillingService.fetchProducts(
        _knownProductIds,
      );
      final products = productDetails
          .map(_subscriptionProductFromStoreDetails)
          .whereType<SubscriptionProduct>()
          .toList(growable: false);
      products.sort(_sortProducts);
      return products;
    }

    return BillingConfig.tiers
        .where((plan) => plan.tier != SubscriptionTier.free)
        .expand(
          (plan) => [
            _fallbackProductFor(plan, BillingPeriod.monthly),
            _fallbackProductFor(plan, BillingPeriod.quarterly),
            _fallbackProductFor(plan, BillingPeriod.yearly),
          ],
        )
        .toList(growable: false);
  }

  Future<SubscriptionStatus> _refreshNativePurchaseStatus() async {
    final restoredPurchases = await _nativeBillingService.restorePurchases();

    if (restoredPurchases.isEmpty) {
      return SubscriptionStatus(tier: SubscriptionTier.free, status: 'none');
    }

    if (_isAndroidNativeMobilePurchase) {
      return _restoreStatusesFromPurchases(
        restoredPurchases,
        _verifyGooglePlayRestoredPurchase,
      );
    }

    if (_isIosNativeMobilePurchase) {
      return _restoreStatusesFromPurchases(
        restoredPurchases,
        _verifyAppleRestoredPurchase,
      );
    }

    final currentPlan = await getCurrentPlan();
    return SubscriptionStatus(
      tier: currentPlan,
      status: currentPlan.hasPremium ? 'active' : 'none',
    );
  }

  Future<SubscriptionStatus> _verifyGooglePlayRestoredPurchase(
    NativeSubscriptionPurchase purchase,
  ) => verifyPurchaseReceipt(
    platform: 'android',
    receiptData: purchase.serverVerificationData,
    productId: purchase.productId,
  );

  Future<SubscriptionStatus> _verifyAppleRestoredPurchase(
    NativeSubscriptionPurchase purchase,
  ) => verifyPurchaseReceipt(
    platform: 'ios',
    receiptData: _receiptDataForPurchase(purchase),
    productId: purchase.productId,
  );

  Future<Map<String, dynamic>> _invokePurchaseReceiptVerifier({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) async {
    final verifier = _purchaseReceiptVerifier;
    if (verifier != null) {
      return verifier(
        platform: platform,
        receiptData: receiptData,
        productId: productId,
        packageName: packageName,
      );
    }

    final googleVerifier = _googlePurchaseTokenVerifier;
    if (platform == 'android' && googleVerifier != null) {
      return googleVerifier(productId: productId, purchaseToken: receiptData);
    }
    final appleVerifier = _appleTransactionVerifier;
    if (platform == 'ios' && appleVerifier != null) {
      return appleVerifier(productId: productId, transactionId: receiptData);
    }

    final callable = _functions.httpsCallable('verifyPurchaseReceipt');
    final result = await callable.call<Map<String, dynamic>>({
      'platform': platform,
      'receiptData': receiptData,
      'productId': productId,
      ...?(packageName == null ? null : {'packageName': packageName}),
    });
    return Map<String, dynamic>.from(result.data);
  }

  String _receiptDataForPurchase(NativeSubscriptionPurchase purchase) {
    if (_isIosNativeMobilePurchase) {
      final transactionId = purchase.transactionId;
      if (transactionId == null || transactionId.isEmpty) {
        throw StateError(
          'Missing App Store transaction ID for restored purchase.',
        );
      }
      return transactionId;
    }
    return purchase.serverVerificationData;
  }

  Future<SubscriptionStatus> _restoreStatusesFromPurchases(
    List<NativeSubscriptionPurchase> purchases,
    Future<SubscriptionStatus> Function(NativeSubscriptionPurchase purchase)
    verifier,
  ) async {
    final restoredStatuses = <SubscriptionStatus>[];
    Object? lastError;

    for (final purchase in purchases) {
      try {
        restoredStatuses.add(await verifier(purchase));
      } catch (error) {
        lastError = error;
      }
    }

    if (restoredStatuses.isNotEmpty) {
      return _selectMostEntitledStatus(restoredStatuses);
    }

    if (lastError != null) {
      throw StateError('Could not restore purchases. Please try again.');
    }

    return SubscriptionStatus(tier: SubscriptionTier.free, status: 'none');
  }

  SubscriptionStatus _subscriptionStatusFromGooglePayload(
    Map<String, dynamic> payload,
  ) {
    final tier = _tierFromPlan(payload['plan'] as String?);

    return SubscriptionStatus(
      tier: tier,
      status: payload['status'] as String?,
      nextRenewal:
          _parseTimestamp(payload['nextRenewal']) ??
          _parseEpochSeconds(payload['currentPeriodEnd']),
      cancelAtPeriodEnd: payload['cancelAtPeriodEnd'] as bool? ?? false,
    );
  }

  SubscriptionStatus _selectMostEntitledStatus(
    List<SubscriptionStatus> statuses,
  ) {
    statuses.sort(
      (left, right) =>
          _tierPriority(right.tier).compareTo(_tierPriority(left.tier)),
    );
    return statuses.first;
  }

  SubscriptionTier _tierFromPlan(String? planValue) {
    return switch (planValue) {
      'plus' => SubscriptionTier.plus,
      'platinum' => SubscriptionTier.platinum,
      _ => SubscriptionTier.free,
    };
  }

  int _tierPriority(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 0,
      SubscriptionTier.plus => 1,
      SubscriptionTier.platinum => 2,
    };
  }

  SubscriptionProduct? _subscriptionProductFromStoreDetails(
    ProductDetails details,
  ) {
    final metadata = _metadataForProductId(details.id);
    if (metadata == null) {
      return null;
    }

    return SubscriptionProduct(
      productId: details.id,
      tier: metadata.tier,
      period: metadata.period,
      title: details.title,
      description: details.description,
      priceLabel: details.price,
      price: details.rawPrice,
      currencyCode: details.currencyCode,
      currencySymbol: details.currencySymbol,
    );
  }

  SubscriptionProduct _fallbackProductFor(
    BillingPlanConfig plan,
    BillingPeriod period,
  ) {
    final price = plan.getPriceForPeriod(period);
    return SubscriptionProduct(
      productId: '${plan.tier.name}_${period.name}',
      tier: plan.tier,
      period: period,
      title: plan.name,
      description: plan.description,
      priceLabel: NumberFormat.simpleCurrency(name: 'USD').format(price),
      price: price,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );
  }

  ({SubscriptionTier tier, BillingPeriod period})? _metadataForProductId(
    String productId,
  ) {
    return switch (productId) {
      'plus_monthly' => (
        tier: SubscriptionTier.plus,
        period: BillingPeriod.monthly,
      ),
      'plus_quarterly' => (
        tier: SubscriptionTier.plus,
        period: BillingPeriod.quarterly,
      ),
      'plus_yearly' => (
        tier: SubscriptionTier.plus,
        period: BillingPeriod.yearly,
      ),
      'platinum_monthly' => (
        tier: SubscriptionTier.platinum,
        period: BillingPeriod.monthly,
      ),
      'platinum_quarterly' => (
        tier: SubscriptionTier.platinum,
        period: BillingPeriod.quarterly,
      ),
      'platinum_yearly' => (
        tier: SubscriptionTier.platinum,
        period: BillingPeriod.yearly,
      ),
      _ => null,
    };
  }

  Set<String> get _knownProductIds => const {
    'plus_monthly',
    'plus_quarterly',
    'plus_yearly',
    'platinum_monthly',
    'platinum_quarterly',
    'platinum_yearly',
  };

  int _sortProducts(SubscriptionProduct a, SubscriptionProduct b) {
    int tierScore(SubscriptionTier tier) => switch (tier) {
      SubscriptionTier.plus => 1,
      SubscriptionTier.platinum => 2,
      SubscriptionTier.free => 0,
    };
    int periodScore(BillingPeriod period) => switch (period) {
      BillingPeriod.monthly => 1,
      BillingPeriod.quarterly => 2,
      BillingPeriod.yearly => 3,
    };

    final tierComparison = tierScore(a.tier).compareTo(tierScore(b.tier));
    if (tierComparison != 0) {
      return tierComparison;
    }
    return periodScore(a.period).compareTo(periodScore(b.period));
  }

  DateTime? _parseEpochSeconds(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch((parsed * 1000).round());
      }
    }
    return null;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMO CODE METHODS (with fallback to local demo codes)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    // Try Cloud Function first
    try {
      final callable = _functions.httpsCallable('validatePromoCode');
      final result = await callable.call<Map<String, dynamic>>({
        'code': normalizedCode,
      });

      final data = result.data;
      if (data['valid'] != true) return null;

      return PromoCode.fromJson(data['promoCode'] as Map<String, dynamic>);
    } catch (e) {
      // Fallback to local demo codes
      return _validateLocalPromoCode(normalizedCode);
    }
  }

  Future<PromoCode?> _validateLocalPromoCode(String normalizedCode) async {
    final promoCode = _demoCodes[normalizedCode];
    if (promoCode == null) return null;

    // Check if already redeemed locally
    final redeemed = await _getLocalRedeemedCodes();
    if (redeemed.contains(normalizedCode)) return null;

    return promoCode.isValid ? promoCode : null;
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    final userId = _currentUserId;
    if (userId == null) {
      return PromoCodeRedemptionResult.failure(
        'Please sign in to redeem a promo code.',
      );
    }

    final normalizedCode = code.trim().toUpperCase();

    // Try Cloud Function first
    try {
      final callable = _functions.httpsCallable('redeemPromoCode');
      final result = await callable.call<Map<String, dynamic>>({
        'code': normalizedCode,
      });

      final data = result.data;
      if (data['success'] != true) {
        return PromoCodeRedemptionResult.failure(
          data['error'] as String? ?? 'Failed to redeem promo code.',
        );
      }

      final promoCode = PromoCode.fromJson(
        data['promoCode'] as Map<String, dynamic>,
      );
      final benefits =
          (data['appliedBenefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return PromoCodeRedemptionResult.success(
        promoCode: promoCode,
        appliedBenefits: benefits,
      );
    } catch (e) {
      // Fallback to local demo codes
      return _redeemLocalPromoCode(normalizedCode, userId);
    }
  }

  Future<PromoCodeRedemptionResult> _redeemLocalPromoCode(
    String normalizedCode,
    String userId,
  ) async {
    final promoCode = _demoCodes[normalizedCode];

    if (promoCode == null) {
      return PromoCodeRedemptionResult.failure(
        'Invalid promo code. Please check and try again.',
      );
    }

    if (promoCode.isExpired) {
      return PromoCodeRedemptionResult.failure('This promo code has expired.');
    }

    // Check if already redeemed locally
    final redeemed = await _getLocalRedeemedCodes();
    if (redeemed.contains(normalizedCode)) {
      return PromoCodeRedemptionResult.failure(
        'You have already redeemed this promo code.',
      );
    }

    // Apply benefits
    final benefits = <String>[];

    if (promoCode.discountPercent != null) {
      benefits.add('${promoCode.discountPercent}% discount applied');
      // For 100% discount, upgrade to Plus
      if (promoCode.discountPercent == 100) {
        await _upgradeToPlus(userId);
        benefits.add('Plus membership activated!');
      }
    }

    if (promoCode.freeTrialDays != null) {
      benefits.add('${promoCode.freeTrialDays} day free trial activated');
      await _upgradeToPlus(userId);
    }

    if (promoCode.bonusLikes != null) {
      benefits.add('${promoCode.bonusLikes} bonus likes added');
    }

    if (promoCode.bonusSuperLikes != null) {
      benefits.add('${promoCode.bonusSuperLikes} bonus Super Likes added');
    }

    // Save redemption locally
    await _saveLocalRedeemedCode(normalizedCode);

    return PromoCodeRedemptionResult.success(
      promoCode: promoCode,
      appliedBenefits: benefits,
    );
  }

  Future<void> _upgradeToPlus(String userId) async {
    // Update Firestore user document
    try {
      await _firestore.collection('users').doc(userId).set({
        'plan': 'plus',
      }, SetOptions(merge: true));
    } catch (e) {
      // If Firestore fails, save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localPlanKey, 'plus');
    }
  }

  Future<Set<String>> _getLocalRedeemedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codes = prefs.getStringList(_redeemedCodesKey) ?? [];
    return codes.toSet();
  }

  Future<void> _saveLocalRedeemedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final codes = prefs.getStringList(_redeemedCodesKey) ?? [];
    codes.add(code);
    await prefs.setStringList(_redeemedCodesKey, codes);
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('redeemedCodes')
          .orderBy('redeemedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PromoCode.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // Return local redeemed codes as fallback
      final localCodes = await _getLocalRedeemedCodes();
      return localCodes
          .map((code) => _demoCodes[code])
          .whereType<PromoCode>()
          .toList();
    }
  }
}
