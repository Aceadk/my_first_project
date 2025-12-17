import '../../config/billing_config.dart';

/// Simple runtime checks to catch missing/placeholder configuration early.
class ConfigValidation {
  const ConfigValidation._();

  static void assertBillingConfigured() {
    final issues = <String>[];
    if (BillingConfig.plusPriceId.isEmpty ||
        BillingConfig.plusPriceId.contains('price_plus')) {
      issues.add('BillingConfig.plusPriceId is not set to a live/QA Stripe price id.');
    }
    if (BillingConfig.successUrl.isEmpty ||
        !Uri.tryParse(BillingConfig.successUrl)?.hasScheme == true) {
      issues.add('BillingConfig.successUrl is not a valid https URL.');
    }
    if (BillingConfig.cancelUrl.isEmpty ||
        !Uri.tryParse(BillingConfig.cancelUrl)?.hasScheme == true) {
      issues.add('BillingConfig.cancelUrl is not a valid https URL.');
    }

    if (issues.isNotEmpty) {
      throw Exception('Billing configuration invalid: ${issues.join(' ')}');
    }
  }
}
