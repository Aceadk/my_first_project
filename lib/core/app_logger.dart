import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:crushhour/core/services/crash_reporting_service.dart';

/// Structured logging utility for consistent logging across the app.
///
/// FEATURES:
/// - Multiple log levels: debug, info, warning, error
/// - Debug-only logging (completely disabled in release builds)
/// - Crashlytics integration for production error reporting
/// - Consistent formatting with log level prefixes
///
/// USAGE:
/// ```dart
/// AppLogger.debug('Processing user data');
/// AppLogger.info('User logged in successfully');
/// AppLogger.warning('API rate limit approaching', data: {'remaining': 10});
/// AppLogger.error('Failed to fetch profile', error: e, stackTrace: stack);
/// ```
class AppLogger {
  AppLogger._();

  /// Log a debug message (only in debug mode).
  ///
  /// Use for detailed development information that helps trace execution flow.
  /// These logs are completely stripped in release builds.
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (!kDebugMode) return;

    final formattedMessage = _formatMessage('DEBUG', message, data);
    developer.log(formattedMessage, name: 'CrushHour', level: 500);
    debugPrint(formattedMessage);
  }

  /// Log an informational message (only in debug mode).
  ///
  /// Use for general operational information about app state and flow.
  static void info(String message, {Map<String, dynamic>? data}) {
    if (!kDebugMode) return;

    final formattedMessage = _formatMessage('INFO', message, data);
    developer.log(formattedMessage, name: 'CrushHour', level: 800);
    debugPrint(formattedMessage);
  }

  /// Log a warning message (only in debug mode).
  ///
  /// Use for potentially problematic situations that don't cause errors
  /// but might indicate issues (e.g., deprecated API usage, slow operations).
  static void warning(String message, {Object? error, Map<String, dynamic>? data}) {
    if (!kDebugMode) return;

    final formattedMessage = _formatMessage('WARN', message, data);
    developer.log(
      formattedMessage,
      name: 'CrushHour',
      level: 900,
      error: error,
    );
    debugPrint(formattedMessage);
    if (error != null) {
      debugPrint('[WARN DETAIL] $error');
    }
  }

  /// Log an error message.
  ///
  /// In debug mode: prints to console.
  /// In release mode: reports to Crashlytics for tracking.
  ///
  /// Use for errors that need attention but don't crash the app.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    bool reportToCrashlytics = true,
  }) {
    final formattedMessage = _formatMessage('ERROR', message, data);

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'CrushHour',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint(formattedMessage);
      if (error != null) {
        debugPrint('[ERROR DETAIL] $error');
      }
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    } else if (reportToCrashlytics) {
      // Report to Crashlytics in production
      CrashReportingService.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        information: data,
      );
    }
  }

  /// Log a network request (debug only).
  ///
  /// Use for tracking API calls and their results.
  static void network(
    String method,
    String endpoint, {
    int? statusCode,
    Duration? duration,
    Object? error,
  }) {
    if (!kDebugMode) return;

    final status = statusCode != null ? '[$statusCode]' : '';
    final time = duration != null ? '(${duration.inMilliseconds}ms)' : '';
    final errorStr = error != null ? ' - Error: $error' : '';

    debugPrint('[NET] $method $endpoint $status $time$errorStr');
  }

  /// Log a lifecycle event (debug only).
  ///
  /// Use for tracking app/widget lifecycle events.
  static void lifecycle(String event, {String? context}) {
    if (!kDebugMode) return;

    final ctx = context != null ? ' - $context' : '';
    debugPrint('[LIFECYCLE] $event$ctx');
  }

  /// Log a performance metric (debug only).
  ///
  /// Use for tracking timing and performance data.
  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    if (!kDebugMode) return;

    final dataStr = data != null ? ' ${_formatData(data)}' : '';
    debugPrint('[PERF] $operation: ${duration.inMilliseconds}ms$dataStr');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY METHODS (for backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  /// @deprecated Use [info] instead.
  static void logInfo(String message) {
    info(message);
  }

  /// @deprecated Use [error] instead.
  static void logError(String context, Object error, [StackTrace? stackTrace]) {
    AppLogger.error(context, error: error, stackTrace: stackTrace);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _formatMessage(String level, String message, Map<String, dynamic>? data) {
    final dataStr = data != null ? ' ${_formatData(data)}' : '';
    return '[$level] $message$dataStr';
  }

  static String _formatData(Map<String, dynamic> data) {
    final entries = data.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return '{$entries}';
  }
}
