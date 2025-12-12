import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/billing_config.dart';
import '../../services/checkout_service.dart';
import '../../models/subscription.dart';
import '../subscription_repository.dart';

const _billingFunctionBaseUrl = String.fromEnvironment(
  'CRUSH_BILLING_FUNCTION_BASE_URL',
  defaultValue: 'https://us-central1-crushhour-dev.cloudfunctions.net',
);

const _billingFunctionName = String.fromEnvironment(
  'CRUSH_BILLING_FUNCTION_NAME',
  defaultValue: 'purchasePlusPlan',
);

class FirebaseSubscriptionRepository implements SubscriptionRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CheckoutService _checkoutService;
  final _controller = StreamController<SubscriptionPlan>.broadcast();

  FirebaseSubscriptionRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CheckoutService? checkoutService,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _checkoutService = checkoutService ?? CheckoutService() {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (!doc.exists) return;
        final data = doc.data()!;
        final planStr = data['plan'] as String? ?? 'free';
        final plan =
            planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
        _controller.add(plan);
      });
    } else {
      _controller.add(SubscriptionPlan.free);
    }
  }

  @override
  Stream<SubscriptionPlan> watchPlan() => _controller.stream;

  @override
  Future<SubscriptionPlan> getCurrentPlan() async {
    final user = _auth.currentUser;
    if (user == null) return SubscriptionPlan.free;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return SubscriptionPlan.free;
    final planStr = doc.data()!['plan'] as String? ?? 'free';
    return planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
  }

  @override
  Future<String> startPlusCheckout() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    return _checkoutService.createPlusCheckoutSession(
      priceId: BillingConfig.plusPriceId,
      successUrl: BillingConfig.successUrl,
      cancelUrl: BillingConfig.cancelUrl,
    );
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not launch checkout URL');
    }
  }

  @override
  Future<void> purchasePlusPlan() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('$_billingFunctionBaseUrl/$_billingFunctionName');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'plan': 'plus'}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Billing function failed (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final plan = decoded['plan'] as String?;
        if (plan != null && plan.toLowerCase() != 'plus') {
          throw Exception('Unexpected plan from billing: $plan');
        }
      }
    }

    await _firestore.collection('users').doc(user.uid).update({
      'plan': 'plus',
    });
    _controller.add(SubscriptionPlan.plus);
  }
}
