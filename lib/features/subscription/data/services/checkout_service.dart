/// Mock implementation of CheckoutService.
/// Returns mock checkout URLs for demo purposes.
class CheckoutService {
  Future<String> createPlusCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // For demo: return a mock checkout URL
    // In production, this would create a Stripe checkout session
    final sessionId = 'cs_demo_${DateTime.now().millisecondsSinceEpoch}';
    return 'https://checkout.example.com/$sessionId?success=$successUrl&cancel=$cancelUrl';
  }
}
