import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  // Install stub analytics service to avoid Firebase Analytics calls
  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('AuthBloc', () {
    group('Initial State', () {
      test('initial state is unknown with no loading', () {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());
        expect(bloc.state.status, AuthStatus.unknown);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.user, isNull);
        expect(bloc.state.errorMessage, isNull);
        bloc.close();
      });
    });

    group('AuthStarted', () {
      test('emits authenticated when user stream emits user', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(userStreamController: controller),
        );

        bloc.add(AuthStarted());
        await Future.delayed(const Duration(milliseconds: 50));

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

      test('emits error when bootstrap fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailBootstrap: true),
        );

        bloc.add(AuthStarted());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.unauthenticated)
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('Phone OTP Flow', () {
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

      test('emits error when sendOtp fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailSendOtp: true),
        );

        bloc.add(AuthPhoneSubmitted('+1234567890'));

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

      test('resends OTP successfully', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthOtpResendRequested('+1234567890'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.authenticating)
                .having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.otpSent)
                .having((s) => s.isLoading, 'isLoading', false),
          ]),
        );

        await bloc.close();
      });

      test('emits error when resend with empty phone', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthOtpResendRequested(''));

        await expectLater(
          bloc.stream,
          emits(
            isA<AuthState>().having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });

      test('uses state phone when resend phone is empty', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        // First submit phone to set phoneInProgress
        bloc.add(AuthPhoneSubmitted('+1234567890'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Then resend with empty phone - should use state phone
        bloc.add(AuthOtpResendRequested(''));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.otpSent)
                .having((s) => s.phoneInProgress, 'phone', '+1234567890'),
          ),
        );

        await bloc.close();
      });

      test('handles verification bypass mode', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(isVerificationBypass: true),
        );

        bloc.add(AuthPhoneSubmitted('+1234567890'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.authenticating)
                .having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.unauthenticated)
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.phoneInProgress, 'phone', '+1234567890'),
          ]),
        );

        await bloc.close();
      });
    });

    group('Email Link Flow', () {
      test('emits emailLinkSent when email link requested', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailLinkRequested('test@example.com'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.authenticating)
                .having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.emailLinkSent)
                .having((s) => s.isLoading, 'isLoading', false)
                .having(
                    (s) => s.emailInProgress, 'email', 'test@example.com'),
          ]),
        );

        await bloc.close();
      });

      test('emits error when email link request fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailEmailLink: true),
        );

        bloc.add(AuthEmailLinkRequested('test@example.com'));

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

      test('emits error when email is empty', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailLinkRequested(''));

        await expectLater(
          bloc.stream,
          emits(
            isA<AuthState>().having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });

      test('emits authenticated when email link submitted', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailLinkSubmitted(
            'test@example.com', 'https://app.example.com/link'));

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

      test('emits error when email link verification fails', () async {
        final bloc = AuthBloc(
          authRepository:
              _StubAuthRepository(shouldFailEmailLinkVerify: true),
        );

        bloc.add(
            AuthEmailLinkSubmitted('test@example.com', 'invalid-link'));

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
    });

    group('Email Password Flow', () {
      test('emits authenticated when email/password login succeeds', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailPasswordSubmitted('test@example.com', 'password123'));

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

      test('emits error when email/password login fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailEmailPassword: true),
        );

        bloc.add(AuthEmailPasswordSubmitted('test@example.com', 'wrong'));

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
    });

    group('Email OTP Flow', () {
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

      test('emits error when email OTP request fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailEmailOtpRequest: true),
        );

        bloc.add(AuthEmailOtpRequested('testuser'));

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

      test('emits error when email OTP verification fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailEmailOtpVerify: true),
        );

        bloc.add(AuthEmailOtpSubmitted('testuser', 'wrong'));

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

      test('resends email OTP successfully', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailOtpResendRequested('testuser'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.authenticating)
                .having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.emailOtpSent)
                .having((s) => s.isLoading, 'isLoading', false),
          ]),
        );

        await bloc.close();
      });

      test('emits error when empty identifier provided for OTP', () async {
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

      test('emits error when empty identifier for OTP resend', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthEmailOtpResendRequested(''));

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

    group('Sign Out', () {
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

      test('emits error when sign out fails', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldFailSignOut: true),
        );

        bloc.add(AuthSignedOut());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
            isA<AuthState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('User Refresh', () {
      test('refreshes user when requested', () async {
        final bloc = AuthBloc(authRepository: _StubAuthRepository());

        bloc.add(AuthUserRefreshRequested());

        await expectLater(
          bloc.stream,
          emits(
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.authenticated)
                .having((s) => s.user?.id, 'user.id', 'test-user-id'),
          ),
        );

        await bloc.close();
      });

      test('does not emit when refresh returns null', () async {
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(shouldReturnNullOnRefresh: true),
        );

        bloc.add(AuthUserRefreshRequested());

        // Should not emit any state changes
        await Future.delayed(const Duration(milliseconds: 100));
        expect(bloc.state.user, isNull);

        await bloc.close();
      });
    });

    group('Stream Subscription', () {
      test('cancels subscription on close', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = AuthBloc(
          authRepository: _StubAuthRepository(userStreamController: controller),
        );

        bloc.add(AuthStarted());
        await Future.delayed(const Duration(milliseconds: 50));

        await bloc.close();

        // Stream controller should be closeable (subscription cancelled)
        expect(() => controller.close(), returnsNormally);
      });
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
    this.shouldFailSendOtp = false,
    this.shouldFailBootstrap = false,
    this.shouldFailEmailLink = false,
    this.shouldFailEmailLinkVerify = false,
    this.shouldFailEmailPassword = false,
    this.shouldFailEmailOtpRequest = false,
    this.shouldFailEmailOtpVerify = false,
    this.shouldFailSignOut = false,
    this.shouldReturnNullOnRefresh = false,
    this.isVerificationBypass = false,
  });

  final StreamController<CrushUser?>? userStreamController;
  final bool shouldFailOtpVerify;
  final bool shouldFailSendOtp;
  final bool shouldFailBootstrap;
  final bool shouldFailEmailLink;
  final bool shouldFailEmailLinkVerify;
  final bool shouldFailEmailPassword;
  final bool shouldFailEmailOtpRequest;
  final bool shouldFailEmailOtpVerify;
  final bool shouldFailSignOut;
  final bool shouldReturnNullOnRefresh;
  final bool isVerificationBypass;

  @override
  bool get isVerificationBypassEnabled => isVerificationBypass;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {
    if (shouldFailBootstrap) {
      throw Exception('Bootstrap failed');
    }
  }

  @override
  Stream<CrushUser?> authStateChanges() {
    return userStreamController?.stream ?? const Stream.empty();
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    if (shouldFailSendOtp) {
      throw Exception('Failed to send OTP');
    }
  }

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
  Future<void> sendEmailSignInLink(String email) async {
    if (shouldFailEmailLink) {
      throw Exception('Failed to send email link');
    }
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    if (shouldFailEmailLinkVerify) {
      throw Exception('Invalid email link');
    }
    return _testUser;
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFailEmailPassword) {
      throw Exception('Invalid credentials');
    }
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
  }) async {
    if (shouldFailEmailOtpRequest) {
      throw Exception('Failed to send email OTP');
    }
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    if (shouldFailEmailOtpVerify) {
      throw Exception('Invalid email OTP');
    }
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
  Future<void> signOut() async {
    if (shouldFailSignOut) {
      throw Exception('Sign out failed');
    }
  }

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
  Future<CrushUser?> refreshCurrentUser() async {
    if (shouldReturnNullOnRefresh) {
      return null;
    }
    return _testUser;
  }
}
