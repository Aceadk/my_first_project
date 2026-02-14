import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';

/// Service for crash reporting and error tracking using Firebase Crashlytics.
///
/// Features:
/// - Automatic crash reporting
/// - Non-fatal error logging
/// - User identification for crash reports
/// - Custom keys and logs for debugging
/// - Flutter error handling integration
class CrashReportingService {
  CrashReportingService._({
    CrashlyticsClient? crashlytics,
    CrashlyticsClient Function()? crashlyticsFactory,
    bool Function()? isDebugMode,
    PlatformDispatcher? platformDispatcher,
    void Function(SendPort)? addIsolateErrorListener,
  }) : _crashlytics = crashlytics,
       _crashlyticsFactory =
           crashlyticsFactory ?? _defaultCrashlyticsClientFactory,
       _isDebugMode = isDebugMode ?? _defaultIsDebugMode,
       _platformDispatcher = platformDispatcher ?? PlatformDispatcher.instance,
       _addIsolateErrorListener =
           addIsolateErrorListener ?? Isolate.current.addErrorListener;

  static CrashReportingService _singleton = CrashReportingService._();

  static CrashReportingService get instance => _singleton;

  @visibleForTesting
  static void setInstanceForTesting(CrashReportingService service) {
    _singleton = service;
  }

  @visibleForTesting
  static void resetInstanceForTesting() {
    _singleton = CrashReportingService._();
  }

  factory CrashReportingService.test({
    CrashlyticsClient? crashlytics,
    CrashlyticsClient Function()? crashlyticsFactory,
    bool Function()? isDebugMode,
    PlatformDispatcher? platformDispatcher,
    void Function(SendPort)? addIsolateErrorListener,
  }) {
    return CrashReportingService._(
      crashlytics: crashlytics,
      crashlyticsFactory: crashlyticsFactory,
      isDebugMode: isDebugMode,
      platformDispatcher: platformDispatcher,
      addIsolateErrorListener: addIsolateErrorListener,
    );
  }

  static CrashlyticsClient _defaultCrashlyticsClientFactory() {
    return _FirebaseCrashlyticsClient(FirebaseCrashlytics.instance);
  }

  static bool _defaultIsDebugMode() => kDebugMode;

  CrashlyticsClient? _crashlytics;
  final CrashlyticsClient Function() _crashlyticsFactory;
  final bool Function() _isDebugMode;
  final PlatformDispatcher _platformDispatcher;
  final void Function(SendPort) _addIsolateErrorListener;
  bool _isInitialized = false;

  /// Initialize the crash reporting service.
  /// Call this after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _crashlytics ??= _crashlyticsFactory();

      // Disable crash collection in debug mode
      await _crashlytics?.setCrashlyticsCollectionEnabled(!_isDebugMode());

      // Set up Flutter error handling
      _setupFlutterErrorHandling();

      // Set up isolate error handling for async errors
      _setupIsolateErrorHandling();

      _isInitialized = true;
      AppLogger.debug('CrashReportingService: Initialized');
    } catch (e) {
      AppLogger.error('CrashReportingService: Failed to initialize - $e');
    }
  }

  void _setupFlutterErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isDebugMode()) {
        // In debug mode, print to console
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In release mode, report to Crashlytics
        _crashlytics?.recordFlutterFatalError(details);
      }
    };

    // Catch async errors not handled by Flutter
    _platformDispatcher.onError = (error, stack) {
      if (_isDebugMode()) {
        AppLogger.error('PlatformDispatcher error: $error\n$stack');
      } else {
        _crashlytics?.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  void _setupIsolateErrorHandling() {
    // Catch errors from other isolates
    _addIsolateErrorListener(
      RawReceivePort((pair) {
        final List<dynamic> errorAndStacktrace = pair;
        final error = errorAndStacktrace[0];
        final stackTrace = StackTrace.fromString(
          errorAndStacktrace[1] as String,
        );

        if (!_isDebugMode()) {
          _crashlytics?.recordError(error, stackTrace, fatal: true);
        }
      }).sendPort,
    );
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

      AppLogger.debug('CrashReportingService: Recorded error - $exception');
    } catch (e) {
      AppLogger.error('CrashReportingService: Failed to record error - $e');
    }
  }

  /// Record a Flutter error.
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.recordFlutterError(details);
    } catch (e) {
      AppLogger.error(
        'CrashReportingService: Failed to record Flutter error - $e',
      );
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
      AppLogger.debug('CrashReportingService: Set user ID');
    } catch (e) {
      AppLogger.error('CrashReportingService: Failed to set user ID - $e');
    }
  }

  /// Clear the user identifier.
  Future<void> clearUserId() async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier('');
    } catch (e) {
      AppLogger.error('CrashReportingService: Failed to clear user ID - $e');
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
      AppLogger.error('CrashReportingService: Failed to set custom key - $e');
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
      AppLogger.error('CrashReportingService: Failed to log message - $e');
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
  Future<void> logUserAction(
    String action, {
    Map<String, dynamic>? params,
  }) async {
    final paramsStr =
        params?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    await log(
      'User action: $action${paramsStr.isNotEmpty ? ' ($paramsStr)' : ''}',
    );
  }

  /// Log an API call as a breadcrumb.
  Future<void> logApiCall(
    String endpoint, {
    int? statusCode,
    String? error,
  }) async {
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
    if (_isDebugMode()) {
      AppLogger.debug(
        'CrashReportingService: Test crash ignored in debug mode',
      );
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

  /// Whether service is running in debug mode.
  bool get isDebugMode => _isDebugMode();
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
  if (CrashReportingService.instance.isDebugMode) {
    AppLogger.error('Zone error: $error\n$stack');
  } else {
    CrashReportingService.instance.recordError(error, stack, fatal: false);
  }
}

abstract class CrashlyticsClient {
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });
  Future<void> recordFlutterError(FlutterErrorDetails details);
  void recordFlutterFatalError(FlutterErrorDetails details);
  Future<void> setUserIdentifier(String userId);
  Future<void> setCustomKey(String key, String value);
  Future<void> log(String message);
  void crash();
  bool get isCrashlyticsCollectionEnabled;
}

class _FirebaseCrashlyticsClient implements CrashlyticsClient {
  _FirebaseCrashlyticsClient(this._delegate);

  final FirebaseCrashlytics _delegate;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) {
    return _delegate.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    return _delegate.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return _delegate.recordFlutterError(details);
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    _delegate.recordFlutterFatalError(details);
  }

  @override
  Future<void> setUserIdentifier(String userId) {
    return _delegate.setUserIdentifier(userId);
  }

  @override
  Future<void> setCustomKey(String key, String value) {
    return _delegate.setCustomKey(key, value);
  }

  @override
  Future<void> log(String message) {
    return _delegate.log(message);
  }

  @override
  void crash() {
    _delegate.crash();
  }

  @override
  bool get isCrashlyticsCollectionEnabled =>
      _delegate.isCrashlyticsCollectionEnabled;
}
