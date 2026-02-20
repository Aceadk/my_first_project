import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

/// Firebase implementation of SubscriptionRepository.
/// Includes fallback demo promo codes when Cloud Functions are not deployed.
class FirebaseSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

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
  Stream<SubscriptionPlan> watchPlan() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(SubscriptionPlan.free);
    }

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return SubscriptionPlan.free;
      final data = doc.data();
      final plan = data?['plan'] as String?;
      return plan == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
    });
  }

  @override
  Future<SubscriptionPlan> getCurrentPlan() async {
    final userId = _currentUserId;
    if (userId == null) return SubscriptionPlan.free;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return SubscriptionPlan.free;

    final plan = doc.data()?['plan'] as String?;
    return plan == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
  }

  @override
  Future<void> purchasePlusPlan() async {
    // Start checkout and launch the URL
    final url = await startPlusCheckout();
    await launchCheckoutUrl(url);
  }

  @override
  Future<String> startPlusCheckout() async {
    final callable = _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call<Map<String, dynamic>>({
      'priceId': 'price_plus_monthly', // Configure your Stripe price ID
      'successUrl': 'https://crushhour.app/checkout/success',
      'cancelUrl': 'https://crushhour.app/checkout/cancel',
    });

    final url = result.data['url'] as String?;
    if (url == null) throw Exception('No checkout URL returned');
    return url;
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch checkout URL');
    }
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    try {
      final callable = _functions.httpsCallable('syncSubscriptionStatus');
      final result = await callable.call<Map<String, dynamic>>();

      final data = result.data;
      final planStr = data['plan'] as String?;
      final plan = planStr == 'plus'
          ? SubscriptionPlan.plus
          : SubscriptionPlan.free;

      return SubscriptionStatus(
        plan: plan,
        status: data['status'] as String?,
        nextRenewal: _parseTimestamp(data['nextRenewal']),
        cancelAtPeriodEnd: data['cancelAtPeriodEnd'] as bool? ?? false,
      );
    } catch (e) {
      // Return current status on error
      final plan = await getCurrentPlan();
      return SubscriptionStatus(
        plan: plan,
        status: plan == SubscriptionPlan.plus ? 'active' : null,
      );
    }
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
