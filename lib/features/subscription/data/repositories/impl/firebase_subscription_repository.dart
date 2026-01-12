import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/data/models/subscription.dart';
import '../subscription_repository.dart';

/// Firebase implementation of SubscriptionRepository.
class FirebaseSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

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
      final plan =
          planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;

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
}
