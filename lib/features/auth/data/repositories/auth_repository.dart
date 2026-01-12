import 'package:crushhour/data/models/user.dart';

enum EmailOtpPurpose {
  login,
  addEmail,
  changeEmail,
  resetPassword,
  newDevice,
  sensitiveAction,
}

extension EmailOtpPurposeValue on EmailOtpPurpose {
  String get value {
    switch (this) {
      case EmailOtpPurpose.login:
        return 'login';
      case EmailOtpPurpose.addEmail:
        return 'add_email';
      case EmailOtpPurpose.changeEmail:
        return 'change_email';
      case EmailOtpPurpose.resetPassword:
        return 'reset_password';
      case EmailOtpPurpose.newDevice:
        return 'new_device';
      case EmailOtpPurpose.sensitiveAction:
        return 'sensitive_action';
    }
  }
}

abstract class AuthRepository {
  bool get isVerificationBypassEnabled;

  Future<void> bootstrapSession();

  Stream<CrushUser?> authStateChanges();

  Future<void> sendOtp(String phoneNumber);

  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> sendEmailSignInLink(String email);

  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  });

  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  });

  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  });

  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  });

  Future<void> requestPasswordReset({required String email});

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  });

  Future<void> signOut();

  /// Dev-only: bypass authentication with admin123/admin123 credentials.
  /// Returns null if bypass is disabled or credentials don't match.
  Future<CrushUser?> devLoginBypass({
    required String identifier,
    required String password,
  });
}
