import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/billing_config.dart';
import '../../core/config/config_validation.dart';
import '../../core/errors.dart';
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
  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _planSub;

  FirebaseSubscriptionRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CheckoutService? checkoutService,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _checkoutService = checkoutService ?? CheckoutService() {
    _listenForAuthChanges();
  }

  void _listenForAuthChanges() {
    // Emit current user immediately, then react to auth changes.
    _handleUserChanged(_auth.currentUser);
    _authSub = _auth.authStateChanges().listen(_handleUserChanged);
  }

  void _handleUserChanged(fb.User? user) {
    _planSub?.cancel();
    if (user == null) {
      _controller.add(SubscriptionPlan.free);
      return;
    }

    _planSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        _controller.add(SubscriptionPlan.free);
        return;
      }
      final data = doc.data() ?? {};
      final planStr = data['plan'] as String? ?? 'free';
      _controller.add(_planFromString(planStr));
    });
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
    return _planFromString(planStr);
  }

  @override
  Future<String> startPlusCheckout() async {
    final billingIssues = ConfigValidation.billingIssues();
    if (billingIssues.isNotEmpty) {
      throw RepositoryException(
        'billing_config',
        billingIssues.join(' '),
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw RepositoryException('auth', 'Sign in to upgrade to Plus.');
    }

    return _checkoutService.createPlusCheckoutSession(
      priceId: BillingConfig.plusPriceId,
      successUrl: BillingConfig.successUrl,
      cancelUrl: BillingConfig.cancelUrl,
    );
  }

  SubscriptionPlan _planFromString(String? value) {
    if (value == null) return SubscriptionPlan.free;
    return value.toLowerCase() == 'plus'
        ? SubscriptionPlan.plus
        : SubscriptionPlan.free;
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw RepositoryException(
        'checkout_launch_failed',
        'Could not open checkout link. Try again.',
      );
    }
  }

  @override
  Future<void> purchasePlusPlan() async {
    final billingIssues = ConfigValidation.billingIssues();
    if (billingIssues.isNotEmpty) {
      throw RepositoryException(
        'billing_config',
        billingIssues.join(' '),
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw RepositoryException('auth', 'Sign in to complete purchase.');
    }

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
      throw RepositoryException(
        'billing_http_${response.statusCode}',
        'Billing service failed (${response.statusCode}). Please try again.',
      );
    }

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final plan = decoded['plan'] as String?;
        if (plan != null && plan.toLowerCase() != 'plus') {
          throw RepositoryException(
            'billing_response',
            'Unexpected billing response. Please try again.',
          );
        }
      }
    }

    await _firestore.collection('users').doc(user.uid).update({
      'plan': 'plus',
    });
    _controller.add(SubscriptionPlan.plus);
  }
}
