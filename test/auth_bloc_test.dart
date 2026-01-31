import 'dart:async';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  group('AuthBloc', () {
    test('initial state is unknown', () {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());
      expect(bloc.state.status, AuthStatus.unknown);
      expect(bloc.state.isLoading, false);
      bloc.close();
    });

    test('emits authenticated when user stream emits user', () async {
      final controller = StreamController<CrushUser?>();
      final bloc = AuthBloc(
        authRepository: _StubAuthRepository(userStreamController: controller),
      );

      bloc.add(AuthStarted());

      // Wait for bootstrap
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit a user
      controller.add(_testUser);

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user?.id, 'user.id', 'test-user-id'),
        ),
      );

      await controller.close();
      await bloc.close();
    });

    test('emits unauthenticated when user stream emits null', () async {
      final controller = StreamController<CrushUser?>();
      final bloc = AuthBloc(
        authRepository: _StubAuthRepository(userStreamController: controller),
      );

      bloc.add(AuthStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(null);

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.user, 'user', null),
        ),
      );

      await controller.close();
      await bloc.close();
    });

    test('emits otpSent when phone submitted successfully', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthPhoneSubmitted('+1234567890'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticating)
              .having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.otpSent)
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.phoneInProgress, 'phone', '+1234567890'),
        ]),
      );

      await bloc.close();
    });

    test('emits authenticated when OTP verified successfully', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthOtpSubmitted('+1234567890', '123456'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticating)
              .having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.user?.id, 'user.id', 'test-user-id'),
        ]),
      );

      await bloc.close();
    });

    test('emits error when OTP verification fails', () async {
      final bloc = AuthBloc(
        authRepository: _StubAuthRepository(shouldFailOtpVerify: true),
      );

      bloc.add(AuthOtpSubmitted('+1234567890', 'wrong-otp'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticating)
              .having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'error', isNotNull),
        ]),
      );

      await bloc.close();
    });

    test('emits emailOtpSent when email OTP requested', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthEmailOtpRequested('testuser'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticating)
              .having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.emailOtpSent)
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.emailOtpIdentifier, 'identifier', 'testuser'),
        ]),
      );

      await bloc.close();
    });

    test('emits authenticated when email OTP verified', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthEmailOtpSubmitted('testuser', '123456'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticating)
              .having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.isLoading, 'isLoading', false),
        ]),
      );

      await bloc.close();
    });

    test('emits unauthenticated after sign out', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthSignedOut());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.unknown)
              .having((s) => s.isLoading, 'isLoading', false),
        ]),
      );

      await bloc.close();
    });

    test('emits error when empty email provided for OTP', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthEmailOtpRequested(''));

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthState>().having((s) => s.errorMessage, 'error', isNotNull),
        ),
      );

      await bloc.close();
    });

    test('cancels email OTP flow correctly', () async {
      final bloc = AuthBloc(authRepository: _StubAuthRepository());

      bloc.add(AuthEmailOtpCancelled());

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.emailOtpIdentifier, 'identifier', null)
              .having((s) => s.isLoading, 'isLoading', false),
        ),
      );

      await bloc.close();
    });
  });
}

const _testUser = CrushUser(
  id: 'test-user-id',
  phoneNumber: '+1234567890',
  isEmailVerified: false,
  isPhoneVerified: true,
  isIdVerified: false,
  plan: SubscriptionPlan.free,
  profile: null,
);

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({
    this.userStreamController,
    this.shouldFailOtpVerify = false,
  });

  final StreamController<CrushUser?>? userStreamController;
  final bool shouldFailOtpVerify;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() {
    return userStreamController?.stream ?? const Stream.empty();
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (shouldFailOtpVerify) {
      throw Exception('Invalid OTP');
    }
    return _testUser;
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    return _testUser;
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _testUser;
  }

  @override
  Future<CrushUser> signInWithApple() async {
    return _testUser;
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    return _testUser;
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    return _testUser;
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    return _testUser;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    return 'reset-token';
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

  @override
  Future<void> schedulePhoneDeletion() async {}

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
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> acceptTermsAndConditions() async {
    return _testUser.copyWith(hasAcceptedTerms: true);
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async => _testUser;
}
