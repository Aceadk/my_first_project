import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/security/secure_logger.dart';
import 'package:crushhour/core/app_logger.dart';

/// Service for Firebase App Check / Device Attestation.
///
/// App Check helps protect your backend resources from abuse by
/// verifying that requests come from your authentic app running on
/// genuine devices.
///
/// ## Setup Required in Firebase Console:
///
/// 1. Go to Firebase Console > App Check
/// 2. Register your apps:
///
/// ### iOS:
/// - Select "DeviceCheck" (iOS 14+) or "App Attest" (iOS 14+, more secure)
/// - Download and add the configuration to Xcode
/// - For development, enable "Debug provider" temporarily
///
/// ### Android:
/// - Select "Play Integrity" (recommended) or "SafetyNet" (deprecated)
/// - Register your app's SHA-256 certificate fingerprint
/// - For development, enable "Debug provider" temporarily
///
/// 3. Enforce App Check in Firebase services:
///    - Cloud Firestore > Rules > Enable App Check
///    - Cloud Functions > Settings > Enable App Check
///    - Realtime Database > Rules > Enable App Check
///    - Cloud Storage > Rules > Enable App Check
///
/// ## Security Notes:
/// - In production, ALWAYS use device attestation (not debug provider)
/// - Tokens are automatically refreshed by the SDK
/// - If attestation fails, the app cannot access protected resources
class AppCheckService {
  AppCheckService._();

  static final AppCheckService instance = AppCheckService._();

  bool _initialized = false;

  /// Initialize App Check with appropriate provider for the platform.
  ///
  /// Uses debug provider in debug mode, device attestation in release.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await FirebaseAppCheck.instance.activate(
        // iOS: Use Device Check for iOS 14+, falls back to App Attest
        // ignore: deprecated_member_use
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,

        // Android: Use Play Integrity (recommended over SafetyNet)
        // ignore: deprecated_member_use
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );

      _initialized = true;

      if (kDebugMode) {
        AppLogger.debug('AppCheckService: Initialized with DEBUG provider');
        AppLogger.debug(
            '  WARNING: Debug provider should NEVER be used in production!');

        // Log debug token info (redacted) for Firebase Console registration
        // SECURITY: Never log full tokens - use SecureLogger
        final token = await getToken();
        SecureLogger.logToken(
          type: 'AppCheck',
          token: token,
          context: 'Debug token for Firebase Console',
        );
      } else {
        AppLogger.debug(
            'AppCheckService: Initialized with device attestation (RELEASE)');
      }

      // Listen for token changes - use secure logging
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        SecureLogger.logTokenRefresh(type: 'AppCheck', token: token);
      });
    } catch (e, stack) {
      AppLogger.error('AppCheckService: Failed to initialize - $e');
      AppLogger.error('Stack: $stack');
      // Don't rethrow - app should still work, but backend calls may fail
      // if App Check enforcement is enabled
    }
  }

  /// Get the current App Check token.
  ///
  /// Returns null if App Check is not initialized or token fetch fails.
  Future<String?> getToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token;
    } catch (e) {
      SecureLogger.logTokenError(
        type: 'AppCheck',
        operation: 'getToken',
        error: e,
      );
      return null;
    }
  }

  /// Force refresh the App Check token.
  ///
  /// Useful when you suspect the token may be invalid.
  Future<String?> forceRefreshToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      SecureLogger.logTokenRefresh(type: 'AppCheck', token: token);
      return token;
    } catch (e) {
      SecureLogger.logTokenError(
        type: 'AppCheck',
        operation: 'forceRefresh',
        error: e,
      );
      return null;
    }
  }

  /// Set a custom token refresh listener.
  void setTokenRefreshListener(void Function(String? token) listener) {
    FirebaseAppCheck.instance.onTokenChange.listen(listener);
  }

  /// Check if App Check is initialized.
  bool get isInitialized => _initialized;
}
