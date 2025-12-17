import '../../config/billing_config.dart';

/// Simple runtime checks to catch missing/placeholder configuration early.
class ConfigValidation {
  const ConfigValidation._();

  /// Returns a list of human-readable issues for billing config.
  /// Empty list means "looks good".
  static List<String> billingIssues() {
    final issues = <String>[];
    if (BillingConfig.plusPriceId.isEmpty ||
        BillingConfig.plusPriceId.contains('price_plus')) {
      issues.add('BillingConfig.plusPriceId is not set to a live/QA Stripe price id.');
    }
    if (!_isValidHttpsUrl(BillingConfig.successUrl)) {
      issues.add('BillingConfig.successUrl is not a valid https URL.');
    }
    if (!_isValidHttpsUrl(BillingConfig.cancelUrl)) {
      issues.add('BillingConfig.cancelUrl is not a valid https URL.');
    }
    return issues;
  }

  /// Throws if billing config contains obvious placeholder values.
  /// Pass [onIssues] to log/forward the combined message before throwing.
  static void assertBillingConfigured({void Function(String message)? onIssues}) {
    final issues = billingIssues();
    if (issues.isEmpty) return;
    final message = 'Billing configuration invalid: ${issues.join(' ')}';
    onIssues?.call(message);
    throw StateError(message);
  }

  static bool _isValidHttpsUrl(String value) {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.scheme == 'https';
  }
}
