/// Central place for legal/compliance URLs and contact information.
/// These URLs are used for App Store/Play Store compliance and in-app links.
class LegalConfig {
  LegalConfig._();

  /// Base URL for the Crush website
  static const String baseUrl = 'https://crushhour.app';

  /// Privacy Policy web URL (required for App Store/Play Store)
  static const String privacyPolicyUrl = '$baseUrl/privacy';

  /// Terms of Service web URL (required for App Store/Play Store)
  static const String termsOfServiceUrl = '$baseUrl/terms';

  /// Community Guidelines web URL
  static const String communityGuidelinesUrl = '$baseUrl/guidelines';

  /// Contact email for privacy-related inquiries
  static const String privacyEmail = 'privacy@crushhour.app';

  /// Contact email for legal inquiries
  static const String legalEmail = 'legal@crushhour.app';

  /// Contact email for general support
  static const String supportEmail = 'support@crushhour.app';

  /// Last updated date for privacy policy (January 2026)
  static const String privacyPolicyLastUpdated = 'January 2026';

  /// Last updated date for terms of service (January 2026)
  static const String termsOfServiceLastUpdated = 'January 2026';

  /// Minimum age requirement for the app
  static const int minimumAge = 18;

  /// Maximum age for profiles
  static const int maximumAge = 75;
}
