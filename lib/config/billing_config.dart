/// Central place for subscription billing constants.
/// Replace placeholder values with your live/QA Stripe configuration.
class BillingConfig {
  /// Stripe price id for the Plus plan.
  static const plusPriceId = 'price_plus_usd_999';

  /// Display price for Plus.
  static const plusPriceUsd = 9.99;
  static const plusAnnualPriceUsd = 80.99; //  33% off
  static const plusQuarterPriceUsd = 32.04; // 11% off

  /// Where Stripe redirects after a successful checkout.
  static const successUrl = 'https://crushhour.app/pay/success';

  /// Where Stripe redirects after the user cancels checkout.
  static const cancelUrl = 'https://crushhour.app/pay/cancel';
}
