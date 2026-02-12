import 'package:shared_preferences/shared_preferences.dart';

/// Manages GDPR/privacy consent state for the app.
///
/// Tracks whether the user has accepted the privacy policy and terms
/// of service, and stores the consent timestamp.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  static const _keyConsentGiven = 'gdpr_consent_given';
  static const _keyConsentTimestamp = 'gdpr_consent_timestamp';

  bool _hasConsent = false;

  /// Whether the user has given GDPR consent.
  bool get hasConsent => _hasConsent;

  /// Initialize from stored preferences.
  Future<void> initialize(SharedPreferences prefs) async {
    _hasConsent = prefs.getBool(_keyConsentGiven) ?? false;
  }

  /// Record that the user has accepted privacy policy & terms.
  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setBool(_keyConsentGiven, true);
    await prefs.setString(_keyConsentTimestamp, now);
    _hasConsent = true;
  }

  /// Revoke consent (e.g., user requests data deletion).
  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsentGiven, false);
    await prefs.remove(_keyConsentTimestamp);
    _hasConsent = false;
  }

  /// Get the timestamp when consent was last granted.
  Future<String?> getConsentTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConsentTimestamp);
  }
}
