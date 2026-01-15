import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/env_config.dart';
import '../security/secure_logger.dart';

/// Email service for sending OTP codes and other emails.
///
/// SECURITY: Credentials are loaded from environment configuration,
/// not hardcoded in the source code.
///
/// To configure for production, use dart-defines during build:
/// ```bash
/// flutter build apk \
///   --dart-define=SMTP_HOST=smtp.gmail.com \
///   --dart-define=SMTP_PORT=587 \
///   --dart-define=SMTP_EMAIL=your-email@gmail.com \
///   --dart-define=SMTP_PASSWORD=your-app-password \
///   --dart-define=SMTP_SENDER_NAME=CrushHour
/// ```
///
/// For development, use [EnvConfig.configureSmtp] to set credentials
/// in secure storage.
class EmailService {
  /// Create SMTP server configuration from environment.
  static Future<SmtpServer?> _getSmtpServer() async {
    final host = await EnvConfig.getSmtpHost();
    final port = await EnvConfig.getSmtpPort();
    final email = await EnvConfig.getSmtpEmail();
    final password = await EnvConfig.getSmtpPassword();

    if (host == null || email == null || password == null) {
      SecureLogger.warning('SMTP not configured. Email sending disabled.');
      return null;
    }

    return SmtpServer(
      host,
      port: port,
      username: email,
      password: password,
      ssl: false,
      allowInsecure: false,
    );
  }

  /// Send OTP code to the specified email address.
  /// Returns true if sent successfully, false otherwise.
  static Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final smtpServer = await _getSmtpServer();
    if (smtpServer == null) {
      SecureLogger.error('Cannot send email: SMTP not configured');
      return false;
    }

    final senderEmail = await EnvConfig.getSmtpEmail();
    final senderName = await EnvConfig.getSenderName();

    final message = Message()
      ..from = Address(senderEmail!, senderName)
      ..recipients.add(recipientEmail)
      ..subject = 'Your Crush verification code: $otpCode'
      ..html = _buildOtpEmailHtml(otpCode);

    try {
      final sendReport = await send(message, smtpServer);
      SecureLogger.debug('OTP email sent to $recipientEmail: $sendReport');
      return true;
    } on MailerException catch (e) {
      SecureLogger.error('Failed to send OTP email: ${e.message}');
      for (var p in e.problems) {
        SecureLogger.error('Email problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      SecureLogger.error('Failed to send OTP email', e);
      return false;
    }
  }

  /// Check if email service is properly configured.
  static Future<bool> get isConfigured => EnvConfig.isSmtpConfigured();

  /// Build the HTML template for OTP emails.
  static String _buildOtpEmailHtml(String otpCode) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { text-align: center; padding: 20px 0; }
    .logo { font-size: 28px; font-weight: bold; color: #E91E63; }
    .otp-box {
      background: linear-gradient(135deg, #E91E63 0%, #9C27B0 100%);
      color: white;
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 8px;
      text-align: center;
      padding: 20px;
      border-radius: 12px;
      margin: 30px 0;
    }
    .message { text-align: center; color: #666; }
    .footer { text-align: center; color: #999; font-size: 12px; margin-top: 40px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">Crush</div>
    </div>
    <p class="message">Your verification code is:</p>
    <div class="otp-box">$otpCode</div>
    <p class="message">
      Enter this code in the app to verify your identity.<br>
      This code expires in 10 minutes.
    </p>
    <p class="message" style="color: #999; font-size: 14px;">
      If you didn't request this code, please ignore this email.
    </p>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Crush. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
