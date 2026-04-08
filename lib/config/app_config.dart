import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';

String resolveFlavorForEnv({
  required String flavor,
  required String legacyAppEnv,
  String fallback = 'development',
}) {
  final normalizedFlavor = flavor.trim().toLowerCase();
  if (normalizedFlavor == 'development' ||
      normalizedFlavor == 'staging' ||
      normalizedFlavor == 'production') {
    return normalizedFlavor;
  }
  if (normalizedFlavor == 'dev') return 'development';
  if (normalizedFlavor == 'prod') return 'production';

  final normalizedLegacy = legacyAppEnv.trim().toLowerCase();
  if (normalizedLegacy == 'development' || normalizedLegacy == 'dev') {
    return 'development';
  }
  if (normalizedLegacy == 'staging' || normalizedLegacy == 'stage') {
    return 'staging';
  }
  if (normalizedLegacy == 'production' || normalizedLegacy == 'prod') {
    return 'production';
  }

  return fallback;
}

/// Centralized application configuration for different environments.
/// Use --dart-define to override values at build time.
///
/// Example build commands:
/// ```bash
/// # Development (default)
/// flutter run
///
/// # Staging
/// flutter run --dart-define=FLAVOR=staging
///
/// # Production
/// flutter build appbundle --release \
///   --dart-define=FLAVOR=production \
///   --dart-define=API_BASE_URL=https://api.crushhour.app \
///   --dart-define=AGORA_APP_ID=your_agora_id
/// ```
class AppConfig {
  AppConfig._();

  // ===========================================================================
  // BUILD-TIME CONSTANTS (from --dart-define)
  // ===========================================================================

  static const String _flavorRaw = String.fromEnvironment(
    'FLAVOR',
    defaultValue: '',
  );
  static const String _legacyAppEnvRaw = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );

  /// Current environment flavor
  static String get flavor =>
      resolveFlavorForEnv(flavor: _flavorRaw, legacyAppEnv: _legacyAppEnvRaw);

  /// Whether this is a production build
  static bool get isProduction => flavor == 'production';

  /// Whether this is a staging build
  static bool get isStaging => flavor == 'staging';

  /// Whether this is a development build
  static bool get isDevelopment => flavor == 'development';

  // ===========================================================================
  // API CONFIGURATION
  // ===========================================================================

  /// Base URL for REST API calls
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'CRUSH_API_BASE_URL',
      defaultValue: 'https://us-central1-crushhour-dev.cloudfunctions.net',
    ),
  );

  /// API version prefix
  static const String apiVersion = 'v1';

  /// Full API URL
  static String get fullApiUrl => '$apiBaseUrl/$apiVersion';

  // ===========================================================================
  // FIREBASE CONFIGURATION
  // ===========================================================================

  /// Firebase project ID (varies by environment)
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'crushhour-dev',
  );

  /// Whether to use Firebase emulators
  static const bool useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: bool.fromEnvironment('USE_EMULATORS', defaultValue: false),
  );

  /// Firebase emulator host (for local development)
  static const String emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: 'localhost',
    ),
  );

  /// Firebase Auth emulator port
  static const int authEmulatorPort = 9099;

  /// Firestore emulator port
  static const int firestoreEmulatorPort = 8080;

  /// Functions emulator port
  static const int functionsEmulatorPort = 5001;

  /// Storage emulator port
  static const int storageEmulatorPort = 9199;

  // ===========================================================================
  // AGORA VIDEO/VOICE CALLING
  // ===========================================================================

  /// Agora App ID for video/voice calls
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );

  /// Whether Agora is configured
  static bool get isAgoraConfigured => agoraAppId.isNotEmpty;

  // ===========================================================================
  // FEATURE FLAGS
  // ===========================================================================

  /// Enable chat E2E encryption
  static const bool enableChatE2EE = bool.fromEnvironment(
    'ENABLE_CHAT_E2EE',
    defaultValue: true,
  );

  /// Enable video calling feature
  static const bool enableVideoCalls = bool.fromEnvironment(
    'ENABLE_VIDEO_CALLS',
    defaultValue: true,
  );

  /// Enable voice notes in chat
  static const bool enableVoiceNotes = bool.fromEnvironment(
    'ENABLE_VOICE_NOTES',
    defaultValue: true,
  );

  /// Enable photo verification feature
  static const bool enablePhotoVerification = bool.fromEnvironment(
    'ENABLE_PHOTO_VERIFICATION',
    defaultValue: true,
  );

  /// Enable content moderation
  static const bool enableContentModeration = bool.fromEnvironment(
    'ENABLE_CONTENT_MODERATION',
    defaultValue: true,
  );

  /// Enable analytics in this build
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  /// Enable crashlytics in this build
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );

  /// Enable performance monitoring
  static const bool enablePerformance = bool.fromEnvironment(
    'ENABLE_PERFORMANCE',
    defaultValue: true,
  );

  // ===========================================================================
  // APP CHECK / SECURITY
  // ===========================================================================

  /// Enforce App Check for API requests
  static const bool enforceAppCheck = bool.fromEnvironment(
    'ENFORCE_APP_CHECK',
    defaultValue: false,
  );

  /// Enable a development-only fast-start mode that defers non-critical
  /// startup work until after the first interactive frame.
  static const bool _fastStartRaw = bool.fromEnvironment(
    'FAST_START',
    defaultValue: bool.fromEnvironment('CRUSH_FAST_START', defaultValue: false),
  );

  static bool get fastStartEnabled => kDebugMode && _fastStartRaw;

  // ===========================================================================
  // RATE LIMITS
  // ===========================================================================

  /// Maximum daily likes for free users
  static const int freeDailyLikes = 50;

  /// Maximum daily super likes for free users
  static const int freeDailySuperLikes = 1;

  /// Maximum daily rewinds for free users
  static const int freeDailyRewinds = 0;

  // ===========================================================================
  // CACHE CONFIGURATION
  // ===========================================================================

  /// Maximum image cache size in MB
  static const int maxImageCacheMb = 100;

  /// Profile cache TTL in hours
  static const int profileCacheTtlHours = 24;

  /// Discovery cache TTL in minutes
  static const int discoveryCacheTtlMinutes = 30;

  // ===========================================================================
  // DEBUG HELPERS
  // ===========================================================================

  /// Print configuration summary (only in debug mode)
  static void printConfig() {
    if (kDebugMode) {
      AppLogger.debug('=== AppConfig ===');
      AppLogger.debug('Flavor: $flavor');
      AppLogger.debug('API URL: $apiBaseUrl');
      AppLogger.debug('Firebase Project: $firebaseProjectId');
      AppLogger.debug('Use Emulators: $useEmulators');
      AppLogger.debug('Agora Configured: $isAgoraConfigured');
      AppLogger.debug('E2EE Enabled: $enableChatE2EE');
      AppLogger.debug('App Check Enforced: $enforceAppCheck');
      AppLogger.debug('Fast Start Enabled: $fastStartEnabled');
      AppLogger.debug('=================');
    }
  }
}

/// Environment-specific Firebase configuration.
class FirebaseConfig {
  /// Get the appropriate Firebase options based on current flavor.
  /// In production, these should be loaded from environment or secure storage.
  static Map<String, String> get currentConfig {
    switch (AppConfig.flavor) {
      case 'production':
        return productionConfig;
      case 'staging':
        return stagingConfig;
      default:
        return developmentConfig;
    }
  }

  static const Map<String, String> developmentConfig = {
    'projectId': 'crushhour-dev',
    'storageBucket': 'crushhour-dev.firebasestorage.app',
    'messagingSenderId': '123456789',
    'appId': '1:123456789:ios:dev',
  };

  static const Map<String, String> stagingConfig = {
    'projectId': 'crushhour-staging',
    'storageBucket': 'crushhour-staging.firebasestorage.app',
    'messagingSenderId': '234567890',
    'appId': '1:234567890:ios:staging',
  };

  static const Map<String, String> productionConfig = {
    'projectId': 'crushhour',
    'storageBucket': 'crushhour.firebasestorage.app',
    'messagingSenderId': '345678901',
    'appId': '1:345678901:ios:prod',
  };
}
