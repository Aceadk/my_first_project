import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/shared/dto/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFlowUseCases', () {
    test('normalizes email identifier for password login', () async {
      final repo = _StubAuthRepository(supportsUsernameLogin: true);
      final useCases = AuthFlowUseCases(repo);

      final result = await useCases.loginWithPassword(
        identifier: '  USER@Example.COM ',
        password: 'pw',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.lastLoginIdentifier, 'user@example.com');
    });

    test(
      'keeps username identifier when username login is supported',
      () async {
        final repo = _StubAuthRepository(supportsUsernameLogin: true);
        final useCases = AuthFlowUseCases(repo);

        final result = await useCases.loginWithPassword(
          identifier: 'test_user',
          password: 'pw',
        );

        expect(result.isSuccess, isTrue);
        expect(repo.lastLoginIdentifier, 'test_user');
      },
    );

    test('normalizes email during sign up', () async {
      final repo = _StubAuthRepository();
      final useCases = AuthFlowUseCases(repo);

      final result = await useCases.signUpWithPassword(
        username: 'new_user',
        email: ' NewUser@Example.COM ',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.lastSignUpEmail, 'newuser@example.com');
    });

    test('returns failure when google sign-in is unsupported', () async {
      final repo = _StubAuthRepository(supportsGoogleSignIn: false);
      final useCases = AuthFlowUseCases(repo);

      final result = await useCases.signInWithGoogle();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Google Sign-In failed. Please try again.');
      expect(result.errorCode, AuthFailureType.unsupportedProvider.code);
    });

    test('isEmailRegistered normalizes email input', () async {
      final repo = _StubAuthRepository(emailAlreadyRegistered: true);
      final useCases = AuthFlowUseCases(repo);

      final result = await useCases.isEmailRegistered('  TEST@Example.COM ');

      expect(result, const Result.success(true));
      expect(repo.lastEmailLookup, 'test@example.com');
    });
  });
}

class _StubAuthRepository
    implements AuthRepository, GoogleSignInAuthRepository {
  _StubAuthRepository({
    this.supportsUsernameLogin = false,
    this.supportsGoogleSignIn = true,
    this.emailAlreadyRegistered = false,
  });

  @override
  final bool supportsUsernameLogin;
  @override
  final bool supportsGoogleSignIn;
  final bool emailAlreadyRegistered;

  String? lastLoginIdentifier;
  String? lastSignUpEmail;
  String? lastEmailLookup;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Stream<CrushUser?> authStateChanges() => const Stream<CrushUser?>.empty();

  @override
  Future<void> bootstrapSession() async {}

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    lastLoginIdentifier = identifier;
    return _user();
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    lastSignUpEmail = email;
    return _user();
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    lastEmailLookup = email;
    return emailAlreadyRegistered;
  }

  @override
  Future<CrushUser> signInWithGoogle() async {
    if (!supportsGoogleSignIn) {
      throw UnimplementedError('Google Sign-In is unavailable');
    }
    return _user();
  }

  CrushUser _user() {
    return const CrushUser(
      id: 'u1',
      phoneNumber: '+10000000000',
      isEmailVerified: true,
      isPhoneVerified: true,
      isIdVerified: false,
      tier: SubscriptionTier.free,
    );
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async => _user();

  @override
  Future<CrushUser?> checkEmailVerification() async => _user();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<CrushUser?> refreshCurrentUser() async => _user();

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> signInWithApple() async => _user();

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async => _user();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => _user();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async => 'token';

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async => _user();

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async => _user();
}
