import 'dart:async';

import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';

/// Minimal [AuthRepository] stub for tests that need an auth repository
/// but don't exercise auth flows. Provides an empty [authStateChanges] stream
/// and throws [UnimplementedError] for everything else.
class NoopAuthRepository implements AuthRepository {
  final StreamController<CrushUser?> _controller =
      StreamController<CrushUser?>.broadcast();

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }

  // -- Everything below throws UnimplementedError --

  @override
  Future<void> sendOtp(String phoneNumber) async => throw UnimplementedError();

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailSignInLink(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithApple() async => throw UnimplementedError();

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async =>
      throw UnimplementedError();

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() async => throw UnimplementedError();

  @override
  Future<CrushUser?> checkEmailVerification() async =>
      throw UnimplementedError();

  @override
  Future<void> schedulePhoneDeletion() async => throw UnimplementedError();

  @override
@override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deactivateAccount({required String reason}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> isEmailRegistered(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> acceptTermsAndConditions() async =>
      throw UnimplementedError();

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
