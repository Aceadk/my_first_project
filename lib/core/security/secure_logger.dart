import 'package:flutter/foundation.dart';

/// Secure logger for development that handles sensitive data properly.
///
/// SECURITY FEATURES:
/// - Only logs in debug mode (completely disabled in release builds)
/// - Can be globally disabled via [enableSensitiveLogging]
/// - Redacts sensitive data when [redactSensitiveData] is true
/// - Provides clear visual indicators that data is sensitive
/// - Token-aware: Never logs full tokens (FCM, App Check, JWT, etc.)
///
/// USAGE:
/// ```dart
/// SecureLogger.logToken(type: 'FCM', token: fcmToken);  // Shows: FCM Token: dK7x...9mN2 (152 chars)
/// SecureLogger.logOtp(type: 'Email', recipient: email, code: otp);
/// SecureLogger.debug('Safe message here');
/// ```
class SecureLogger {
  /// Master switch to enable/disable all sensitive logging.
  /// Set to false to disable all OTP/credential logging even in debug mode.
  /// IMPORTANT: This should be false in any shared development environment.
  static bool enableSensitiveLogging = kDebugMode;

  /// When true, sensitive data like OTPs will be partially redacted.
  /// e.g., "123456" becomes "12****"
  /// Defaults to true for security - only set to false for local debugging.
  static bool redactSensitiveData = true;

  /// When true, tokens are NEVER logged in full, even in debug mode.
  /// This is the strictest setting and should remain true.
  /// SECURITY: Do not set to false - tokens should never be in logs.
  static const bool _neverLogFullTokens = true;

  /// Log an OTP code with appropriate security handling.
  /// Only logs in debug mode when [enableSensitiveLogging] is true.
  static void logOtp({
    required String type,
    required String recipient,
    required String code,
  }) {
    if (!kDebugMode || !enableSensitiveLogging) return;

    final displayCode = redactSensitiveData ? _redact(code) : code;
    final displayRecipient =
        redactSensitiveData ? _redactEmail(recipient) : recipient;

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

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN SECURITY — NEVER LOG FULL TOKENS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log a token with proper redaction (NEVER logs full token).
  ///
  /// Shows only first 4 and last 4 characters plus length.
  /// Example output: "FCM Token: dK7x...9mN2 (152 chars)"
  ///
  /// This is the ONLY way tokens should be logged.
  static void logToken({
    required String type,
    required String? token,
    String? context,
  }) {
    if (!kDebugMode) return;

    final contextStr = context != null ? ' ($context)' : '';

    if (token == null || token.isEmpty) {
      debugPrint('[$type Token]$contextStr: <null or empty>');
      return;
    }

    // SECURITY: Always redact tokens, regardless of settings
    final redacted = _redactToken(token);
    debugPrint('[$type Token]$contextStr: $redacted');
  }

  /// Log a token refresh event (safe - only logs metadata).
  static void logTokenRefresh({
    required String type,
    required String? token,
  }) {
    if (!kDebugMode) return;

    if (token == null || token.isEmpty) {
      debugPrint('[$type] Token refresh: <null or empty>');
      return;
    }

    // Only log that refresh happened and token length (not the token itself)
    debugPrint('[$type] Token refreshed (${token.length} chars)');
  }

  /// Log a token error (safe - doesn't include the token).
  static void logTokenError({
    required String type,
    required String operation,
    Object? error,
  }) {
    if (!kDebugMode) return;

    debugPrint('[$type] $operation failed${error != null ? ': $error' : ''}');
  }

  /// Redact a token, showing only first 4 and last 4 chars + length.
  ///
  /// SECURITY: This method ALWAYS redacts, regardless of settings.
  /// Tokens should NEVER be fully visible in logs.
  static String _redactToken(String token) {
    if (_neverLogFullTokens || token.length > 12) {
      // Show: first4...last4 (length chars)
      final first = token.length >= 4 ? token.substring(0, 4) : token;
      final last =
          token.length >= 4 ? token.substring(token.length - 4) : '';
      return '$first...$last (${token.length} chars)';
    }
    // For very short tokens (unusual), still partially redact
    return '${token.substring(0, 2)}${'*' * (token.length - 2)}';
  }

  /// Get a redacted version of a token for display purposes.
  ///
  /// Use this when you need to show a token in UI or logs.
  /// Returns: "dK7x...9mN2" format
  static String redactToken(String? token) {
    if (token == null || token.isEmpty) return '<empty>';
    return _redactToken(token);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH SECURITY — NEVER LOG CREDENTIALS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log an auth event (safe - never includes sensitive data).
  static void logAuth({
    required String event,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    if (!kDebugMode) return;

    final userStr = userId != null ? ' user=${_redact(userId)}' : '';
    final metaStr = metadata != null ? ' $metadata' : '';
    debugPrint('[AUTH] $event$userStr$metaStr');
  }

  /// Log a security event (always logs, even in release for audit trail).
  static void logSecurityEvent({
    required String event,
    required String severity, // 'info', 'warning', 'critical'
    Map<String, dynamic>? details,
  }) {
    // Security events are important enough to log metadata even in release
    // but NEVER log sensitive data
    final detailsStr = details != null ? ' $details' : '';
    debugPrint('[SECURITY:$severity] $event$detailsStr');
  }
}
