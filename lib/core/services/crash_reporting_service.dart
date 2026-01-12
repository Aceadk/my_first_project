import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for crash reporting and error tracking using Firebase Crashlytics.
///
/// Features:
/// - Automatic crash reporting
/// - Non-fatal error logging
/// - User identification for crash reports
/// - Custom keys and logs for debugging
/// - Flutter error handling integration
class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  /// Initialize the crash reporting service.
  /// Call this after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Disable crash collection in debug mode
      await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Set up Flutter error handling
      _setupFlutterErrorHandling();

      // Set up isolate error handling for async errors
      _setupIsolateErrorHandling();

      _isInitialized = true;
      debugPrint('CrashReportingService: Initialized');
    } catch (e) {
      debugPrint('CrashReportingService: Failed to initialize - $e');
    }
  }

  void _setupFlutterErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, print to console
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In release mode, report to Crashlytics
        _crashlytics?.recordFlutterFatalError(details);
      }
    };

    // Catch async errors not handled by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
      } else {
        _crashlytics?.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  void _setupIsolateErrorHandling() {
    // Catch errors from other isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final List<dynamic> errorAndStacktrace = pair;
      final error = errorAndStacktrace[0];
      final stackTrace = StackTrace.fromString(errorAndStacktrace[1] as String);

      if (!kDebugMode) {
        _crashlytics?.recordError(error, stackTrace, fatal: true);
      }
    }).sendPort);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR REPORTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a non-fatal error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      // Log additional information
      if (information != null) {
        for (final entry in information.entries) {
          await setCustomKey(entry.key, entry.value.toString());
        }
      }

      if (reason != null) {
        await log('Error reason: $reason');
      }

      await _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      debugPrint('CrashReportingService: Recorded error - $exception');
    } catch (e) {
      debugPrint('CrashReportingService: Failed to record error - $e');
    }
  }

  /// Record a Flutter error.
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.recordFlutterError(details);
    } catch (e) {
      debugPrint('CrashReportingService: Failed to record Flutter error - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER IDENTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set the user identifier for crash reports.
  Future<void> setUserId(String userId) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier(userId);
      debugPrint('CrashReportingService: Set user ID');
    } catch (e) {
      debugPrint('CrashReportingService: Failed to set user ID - $e');
    }
  }

  /// Clear the user identifier.
  Future<void> clearUserId() async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier('');
    } catch (e) {
      debugPrint('CrashReportingService: Failed to clear user ID - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOM KEYS AND LOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set a custom key-value pair for crash reports.
  Future<void> setCustomKey(String key, String value) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      debugPrint('CrashReportingService: Failed to set custom key - $e');
    }
  }

  /// Set multiple custom keys at once.
  Future<void> setCustomKeys(Map<String, String> keys) async {
    for (final entry in keys.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  /// Log a message that will be included in crash reports.
  Future<void> log(String message) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      debugPrint('CrashReportingService: Failed to log message - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BREADCRUMBS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log a navigation event as a breadcrumb.
  Future<void> logNavigation(String from, String to) async {
    await log('Navigation: $from -> $to');
  }

  /// Log a user action as a breadcrumb.
  Future<void> logUserAction(String action, {Map<String, dynamic>? params}) async {
    final paramsStr = params?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    await log('User action: $action${paramsStr.isNotEmpty ? ' ($paramsStr)' : ''}');
  }

  /// Log an API call as a breadcrumb.
  Future<void> logApiCall(String endpoint, {int? statusCode, String? error}) async {
    if (error != null) {
      await log('API Error: $endpoint - $error');
    } else if (statusCode != null) {
      await log('API: $endpoint - $statusCode');
    } else {
      await log('API: $endpoint');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Force a crash for testing purposes.
  /// Only works in release mode.
  void testCrash() {
    if (kDebugMode) {
      debugPrint('CrashReportingService: Test crash ignored in debug mode');
      return;
    }
    _crashlytics?.crash();
  }

  /// Check if crash collection is enabled.
  bool get isCrashlyticsCollectionEnabled {
    return _crashlytics?.isCrashlyticsCollectionEnabled ?? false;
  }

  /// Enable or disable crash collection.
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Check if the service is initialized.
  bool get isInitialized => _isInitialized;
}

/// Extension for easy error reporting in try-catch blocks.
extension CrashReportingExtension on Object {
  /// Report this error to Crashlytics.
  Future<void> reportError({
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    await CrashReportingService.instance.recordError(
      this,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }
}

/// A zone error handler that reports errors to Crashlytics.
void crashlyticsErrorHandler(Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('Zone error: $error\n$stack');
  } else {
    CrashReportingService.instance.recordError(error, stack, fatal: false);
  }
}
