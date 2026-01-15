import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Environment configuration for sensitive credentials.
///
/// SECURITY: Credentials are loaded from:
/// 1. Dart defines (compile-time, for production builds)
/// 2. Secure storage (runtime, for development/testing)
///
/// To build with credentials:
/// ```bash
/// flutter build apk \
///   --dart-define=SMTP_HOST=smtp.gmail.com \
///   --dart-define=SMTP_PORT=587 \
///   --dart-define=SMTP_EMAIL=your-email@gmail.com \
///   --dart-define=SMTP_PASSWORD=your-app-password \
///   --dart-define=SMTP_SENDER_NAME=CrushHour
/// ```
///
/// For CI/CD, set these as secrets and inject them during build.
class EnvConfig {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Dart define keys (compile-time)
  static const String _smtpHost = String.fromEnvironment('SMTP_HOST');
  static const String _smtpPortStr = String.fromEnvironment('SMTP_PORT');
  static const String _smtpEmail = String.fromEnvironment('SMTP_EMAIL');
  static const String _smtpPassword = String.fromEnvironment('SMTP_PASSWORD');
  static const String _smtpSenderName = String.fromEnvironment('SMTP_SENDER_NAME', defaultValue: 'Crush');

  // Secure storage keys
  static const String _keySmtpHost = 'smtp_host';
  static const String _keySmtpPort = 'smtp_port';
  static const String _keySmtpEmail = 'smtp_email';
  static const String _keySmtpPassword = 'smtp_password';
  static const String _keySenderName = 'smtp_sender_name';

  /// Get SMTP host from dart-define or secure storage.
  static Future<String?> getSmtpHost() async {
    if (_smtpHost.isNotEmpty) return _smtpHost;
    return _storage.read(key: _keySmtpHost);
  }

  /// Get SMTP port from dart-define or secure storage.
  static Future<int> getSmtpPort() async {
    if (_smtpPortStr.isNotEmpty) {
      return int.tryParse(_smtpPortStr) ?? 587;
    }
    final stored = await _storage.read(key: _keySmtpPort);
    return int.tryParse(stored ?? '') ?? 587;
  }

  /// Get SMTP email from dart-define or secure storage.
  static Future<String?> getSmtpEmail() async {
    if (_smtpEmail.isNotEmpty) return _smtpEmail;
    return _storage.read(key: _keySmtpEmail);
  }

  /// Get SMTP password from dart-define or secure storage.
  static Future<String?> getSmtpPassword() async {
    if (_smtpPassword.isNotEmpty) return _smtpPassword;
    return _storage.read(key: _keySmtpPassword);
  }

  /// Get sender name from dart-define or secure storage.
  static Future<String> getSenderName() async {
    if (_smtpSenderName.isNotEmpty) return _smtpSenderName;
    return await _storage.read(key: _keySenderName) ?? 'Crush';
  }

  /// Check if SMTP is fully configured.
  static Future<bool> isSmtpConfigured() async {
    final host = await getSmtpHost();
    final email = await getSmtpEmail();
    final password = await getSmtpPassword();
    return host != null &&
           host.isNotEmpty &&
           email != null &&
           email.isNotEmpty &&
           password != null &&
           password.isNotEmpty;
  }

  /// Configure SMTP settings at runtime (for development/testing).
  /// These are stored in secure storage.
  static Future<void> configureSmtp({
    required String host,
    required int port,
    required String email,
    required String password,
    String senderName = 'Crush',
  }) async {
    await _storage.write(key: _keySmtpHost, value: host);
    await _storage.write(key: _keySmtpPort, value: port.toString());
    await _storage.write(key: _keySmtpEmail, value: email);
    await _storage.write(key: _keySmtpPassword, value: password);
    await _storage.write(key: _keySenderName, value: senderName);
  }

  /// Clear all SMTP configuration from secure storage.
  static Future<void> clearSmtpConfig() async {
    await _storage.delete(key: _keySmtpHost);
    await _storage.delete(key: _keySmtpPort);
    await _storage.delete(key: _keySmtpEmail);
    await _storage.delete(key: _keySmtpPassword);
    await _storage.delete(key: _keySenderName);
  }

  /// Debug: Check configuration status (only in debug mode).
  static Future<void> debugPrintStatus() async {
    if (!kDebugMode) return;

    final configured = await isSmtpConfigured();
    final hasEnvVars = _smtpHost.isNotEmpty && _smtpEmail.isNotEmpty;

    // ignore: avoid_print
    print('[EnvConfig] SMTP configured: $configured');
    // ignore: avoid_print
    print('[EnvConfig] Using dart-defines: $hasEnvVars');
  }
}
