import 'package:flutter/foundation.dart';

/// Secure logger for development that handles sensitive data properly.
///
/// SECURITY FEATURES:
/// - Only logs in debug mode (completely disabled in release builds)
/// - Can be globally disabled via [enableSensitiveLogging]
/// - Redacts sensitive data when [redactSensitiveData] is true
/// - Provides clear visual indicators that data is sensitive
class SecureLogger {
  /// Master switch to enable/disable all sensitive logging.
  /// Set to false to disable all OTP/credential logging even in debug mode.
  /// IMPORTANT: This should be false in any shared development environment.
  static bool enableSensitiveLogging = kDebugMode;

  /// When true, sensitive data like OTPs will be partially redacted.
  /// e.g., "123456" becomes "12****"
  /// Defaults to true for security - only set to false for local debugging.
  static bool redactSensitiveData = true;

  /// Log an OTP code with appropriate security handling.
  /// Only logs in debug mode when [enableSensitiveLogging] is true.
  static void logOtp({
    required String type,
    required String recipient,
    required String code,
  }) {
    if (!kDebugMode || !enableSensitiveLogging) return;

    final displayCode = redactSensitiveData ? _redact(code) : code;
    final displayRecipient = redactSensitiveData ? _redactEmail(recipient) : recipient;

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('┌─────────────────────────────────────────────────────────┐');
    // ignore: avoid_print
    print('│  ⚠️  DEVELOPMENT ONLY - DO NOT SHARE                    │');
    // ignore: avoid_print
    print('├─────────────────────────────────────────────────────────┤');
    // ignore: avoid_print
    print('│  $type OTP');
    // ignore: avoid_print
    print('│  Recipient: $displayRecipient');
    // ignore: avoid_print
    print('│  Code: $displayCode');
    // ignore: avoid_print
    print('└─────────────────────────────────────────────────────────┘');
    // ignore: avoid_print
    print('');
  }

  /// Log a debug message only in debug mode.
  static void debug(String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  /// Log a warning message.
  static void warning(String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[WARNING] $message');
  }

  /// Log an error message (always logs in debug mode).
  static void error(String message, [Object? error]) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('[ERROR DETAILS] $error');
    }
  }

  /// Redact a code, showing only first 2 characters.
  static String _redact(String code) {
    if (code.length <= 2) return '**';
    return '${code.substring(0, 2)}${'*' * (code.length - 2)}';
  }

  /// Redact an email address.
  static String _redactEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '***@***.***';
    final username = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    if (username.length <= 2) return '**$domain';
    return '${username.substring(0, 2)}${'*' * (username.length - 2)}$domain';
  }
}
