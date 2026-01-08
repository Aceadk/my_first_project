import 'dart:async';
import '../../models/user.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/subscription.dart';
import '../auth_repository.dart';

/// Stub implementation of AuthRepository.
/// Replace this with your actual authentication backend implementation.
class StubAuthRepository implements AuthRepository {
  final _authStateController = StreamController<CrushUser?>.broadcast();

  @override
  bool get isVerificationBypassEnabled => true;

  @override
  Future<void> bootstrapSession() async {
    // No-op for stub
  }

  @override
  Stream<CrushUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // TODO: Implement OTP sending via your backend
    throw UnimplementedError('OTP sending not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    // TODO: Implement OTP verification via your backend
    throw UnimplementedError('OTP verification not implemented. Connect your backend.');
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    // TODO: Implement email sign-in link sending
    throw UnimplementedError('Email sign-in link not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    // TODO: Implement email link sign-in
    throw UnimplementedError('Email link sign-in not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // TODO: Implement email/password sign-in
    throw UnimplementedError('Email/password sign-in not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    // TODO: Implement login with password
    throw UnimplementedError('Login not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    // TODO: Implement sign-up
    throw UnimplementedError('Sign-up not implemented. Connect your backend.');
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    // TODO: Implement email OTP request
    throw UnimplementedError('Email OTP not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    // TODO: Implement email OTP verification
    throw UnimplementedError('Email OTP verification not implemented. Connect your backend.');
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    // TODO: Implement password reset request
    throw UnimplementedError('Password reset not implemented. Connect your backend.');
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    // TODO: Implement password reset OTP verification
    throw UnimplementedError('Password reset OTP not implemented. Connect your backend.');
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    // TODO: Implement password reset with token
    throw UnimplementedError('Password reset with token not implemented. Connect your backend.');
  }

  @override
  Future<void> signOut() async {
    _authStateController.add(null);
  }

  @override
  Future<CrushUser?> devLoginBypass({
    required String identifier,
    required String password,
  }) async {
    // Dev bypass for testing - admin123/admin123
    if (identifier == 'admin123' && password == 'admin123') {
      final user = CrushUser(
        id: 'dev-admin-${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: '+1234567890',
        email: 'admin@crushhour.dev',
        username: 'admin123',
        isEmailVerified: true,
        isPhoneVerified: true,
        isIdVerified: true,
        plan: SubscriptionPlan.plus,
        profile: Profile(
          id: 'dev-admin-profile',
          name: 'Dev Admin',
          age: 25,
          gender: 'Other',
          bio: 'Development test account',
          photoUrls: const [],
          videoUrls: const [],
          interests: const ['Development', 'Testing'],
          country: 'United States',
          city: 'San Francisco',
          isVerified: true,
          preferences: const DiscoveryPreferences(
            minAge: 18,
            maxAge: 50,
            maxDistanceKm: 100,
            showMeGenders: ['All'],
            showMyDistance: true,
            showMyAge: true,
            hideFromDiscovery: false,
            incognitoMode: false,
            country: 'United States',
            city: 'San Francisco',
          ),
        ),
      );
      _authStateController.add(user);
      return user;
    }
    return null;
  }

  void dispose() {
    _authStateController.close();
  }
}
