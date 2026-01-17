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

  /// Send email verification to the current user.
  Future<void> sendEmailVerification();

  /// Check if the current user's email is verified.
  /// Returns the updated user if verified, null otherwise.
  Future<CrushUser?> checkEmailVerification();

  /// Schedule phone number for deletion.
  /// The phone will be unlinked from the account after ~3 days (2 days 23 hours)
  /// and added to a cooldown list preventing reuse until then.
  Future<void> schedulePhoneDeletion();

  /// Change the user's password.
  /// Requires current password for verification.
  /// Sends notification to email/phone after successful change.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Deactivate the user's account.
  /// Profile will be hidden but data preserved.
  /// Account will be permanently deleted after 6 months of inactivity.
  Future<void> deactivateAccount({required String reason});

  /// Schedule account for deletion.
  /// User has 14 days to recover by signing back in.
  /// Requires password confirmation.
  Future<void> deleteAccount({
    required String password,
    required String reason,
  });

  /// Dev-only: bypass authentication with admin123/admin123 credentials.
  /// Returns null if bypass is disabled or credentials don't match.
  Future<CrushUser?> devLoginBypass({
    required String identifier,
    required String password,
  });

  /// Check if an email is already registered.
  /// Returns true if the email is already in use.
  Future<bool> isEmailRegistered(String email);

  /// Accept terms and conditions and privacy policy.
  /// Updates the user's hasAcceptedTerms field to true.
  Future<CrushUser> acceptTermsAndConditions();
}
