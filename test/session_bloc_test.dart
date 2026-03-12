import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());

    // Configure PushNotificationService overrides for testing
    final pushService = PushNotificationService.instance;
    pushService.tokenProviderOverride = () async => 'mock-fcm-token';
    pushService.saveTokenOverride = (userId, token) async {};
    pushService.deleteTokenOverride = (userId, token) async {};
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();

    // Reset PushNotificationService overrides
    final pushService = PushNotificationService.instance;
    pushService.tokenProviderOverride = null;
    pushService.saveTokenOverride = null;
    pushService.deleteTokenOverride = null;
  });

  // ===========================================================================
  // SESSION STATE
  // ===========================================================================

  group('SessionState', () {
    test('factory unknown() produces correct defaults', () {
      final state = SessionState.unknown();
      expect(state.status, SessionStatus.unknown);
      expect(state.user, isNull);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves existing values when no overrides', () {
      const state = SessionState(
        status: SessionStatus.authenticated,
        user: _testUser,
        isLoading: true,
        errorMessage: 'error',
      );
      final copied = state.copyWith();
      expect(copied.status, SessionStatus.authenticated);
      expect(copied.user, _testUser);
      expect(copied.isLoading, true);
      expect(copied.errorMessage, 'error');
    });

    test('copyWith overrides specified values', () {
      final state = SessionState.unknown();
      final modified = state.copyWith(
        status: SessionStatus.authenticated,
        user: _testUser,
        isLoading: true,
        errorMessage: 'something',
      );
      expect(modified.status, SessionStatus.authenticated);
      expect(modified.user, _testUser);
      expect(modified.isLoading, true);
      expect(modified.errorMessage, 'something');
    });

    test('copyWith clearError removes error message', () {
      const state = SessionState(
        status: SessionStatus.authenticated,
        errorMessage: 'old error',
      );
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('Equatable compares correctly', () {
      const a = SessionState(status: SessionStatus.unknown);
      const b = SessionState(status: SessionStatus.unknown);
      const c = SessionState(status: SessionStatus.authenticated);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ===========================================================================
  // SESSION EVENT
  // ===========================================================================

  group('SessionEvent', () {
    test('SessionStarted props are empty', () {
      expect(SessionStarted().props, isEmpty);
    });

    test('SessionUserChanged contains user in props', () {
      final event = SessionUserChanged(_testUser);
      expect(event.user, _testUser);
      expect(event.props, [_testUser]);
    });

    test('SessionUserChanged with null user', () {
      final event = SessionUserChanged(null);
      expect(event.user, isNull);
      expect(event.props, [null]);
    });

    test('SessionSignOutRequested props are empty', () {
      expect(SessionSignOutRequested().props, isEmpty);
    });

    test('SessionTimeoutOccurred props are empty', () {
      expect(SessionTimeoutOccurred().props, isEmpty);
    });

    test('SessionActivityRecorded props are empty', () {
      expect(SessionActivityRecorded().props, isEmpty);
    });
  });

  // ===========================================================================
  // SESSION BLOC
  // ===========================================================================

  group('SessionBloc', () {
    group('Initial State', () {
      test('initial state is unknown with no loading', () {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );
        expect(bloc.state.status, SessionStatus.unknown);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.user, isNull);
        expect(bloc.state.errorMessage, isNull);
        bloc.close();
      });
    });

    group('SessionStarted', () {
      test('starts auth subscription and emits loading', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(
            userStreamController: controller,
          ),
        );

        final states = <SessionState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(SessionStarted());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // First state should be loading
        expect(states.isNotEmpty, true);
        expect(states.first.isLoading, true);

        await sub.cancel();
        await controller.close();
        await bloc.close();
      });

      test('emits authenticated when user stream emits user', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(
            userStreamController: controller,
          ),
        );

        bloc.add(SessionStarted());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Emit a user on the auth stream
        controller.add(_testUser);

        await expectLater(
          bloc.stream,
          emits(
            isA<SessionState>()
                .having((s) => s.status, 'status', SessionStatus.authenticated)
                .having((s) => s.user?.id, 'user.id', 'test-user-id')
                .having((s) => s.isLoading, 'isLoading', false),
          ),
        );

        await controller.close();
        await bloc.close();
      });

      test('emits unauthenticated when user stream emits null', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(
            userStreamController: controller,
          ),
        );

        bloc.add(SessionStarted());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        controller.add(null);

        await expectLater(
          bloc.stream,
          emits(
            isA<SessionState>()
                .having(
                    (s) => s.status, 'status', SessionStatus.unauthenticated)
                .having((s) => s.user, 'user', isNull)
                .having((s) => s.isLoading, 'isLoading', false),
          ),
        );

        await controller.close();
        await bloc.close();
      });

      test('emits error when bootstrap fails', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(shouldFailBootstrap: true),
        );

        bloc.add(SessionStarted());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SessionState>().having((s) => s.isLoading, 'isLoading', true),
            isA<SessionState>()
                .having(
                    (s) => s.status, 'status', SessionStatus.unauthenticated)
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('SessionUserChanged', () {
      test('transitions to authenticated with user', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );

        bloc.add(SessionUserChanged(_testUser));

        await expectLater(
          bloc.stream,
          emits(
            isA<SessionState>()
                .having((s) => s.status, 'status', SessionStatus.authenticated)
                .having((s) => s.user, 'user', _testUser)
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ),
        );

        await bloc.close();
      });

      test('transitions to unauthenticated with null user', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );

        bloc.add(SessionUserChanged(null));

        await expectLater(
          bloc.stream,
          emits(
            isA<SessionState>()
                .having(
                    (s) => s.status, 'status', SessionStatus.unauthenticated)
                .having((s) => s.user, 'user', isNull),
          ),
        );

        await bloc.close();
      });
    });

    group('SessionSignOutRequested', () {
      test('emits loading then unknown state on successful sign out', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );

        bloc.add(SessionSignOutRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SessionState>().having((s) => s.isLoading, 'isLoading', true),
            isA<SessionState>()
                .having((s) => s.status, 'status', SessionStatus.unknown)
                .having((s) => s.isLoading, 'isLoading', false),
          ]),
        );

        await bloc.close();
      });

      test('emits error when sign out fails', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(shouldFailSignOut: true),
        );

        bloc.add(SessionSignOutRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SessionState>().having((s) => s.isLoading, 'isLoading', true),
            isA<SessionState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('SessionTimeoutOccurred', () {
      test('emits unauthenticated with timeout message', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );

        bloc.add(SessionTimeoutOccurred());

        await expectLater(
          bloc.stream,
          emits(
            isA<SessionState>()
                .having(
                    (s) => s.status, 'status', SessionStatus.unauthenticated)
                .having((s) => s.user, 'user', isNull)
                .having((s) => s.isLoading, 'isLoading', false)
                .having(
                  (s) => s.errorMessage,
                  'error',
                  contains('Session expired'),
                ),
          ),
        );

        await bloc.close();
      });
    });

    group('SessionActivityRecorded', () {
      test('does not change state', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );

        final initialState = bloc.state;
        bloc.add(SessionActivityRecorded());

        // Activity recording should not produce a state change
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(bloc.state, equals(initialState));

        await bloc.close();
      });
    });

    group('Bloc lifecycle', () {
      test('can close cleanly from fresh state', () async {
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(),
        );
        await expectLater(bloc.close(), completes);
      });

      test('can close after starting session', () async {
        final controller = StreamController<CrushUser?>();
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(
            userStreamController: controller,
          ),
        );

        bloc.add(SessionStarted());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await controller.close();
        await expectLater(bloc.close(), completes);
      });

      test('full session lifecycle: start -> authenticate -> sign out',
          () async {
        final controller = StreamController<CrushUser?>();
        final bloc = SessionBloc(
          authRepository: _StubAuthRepository(
            userStreamController: controller,
          ),
        );

        final states = <SessionState>[];
        final sub = bloc.stream.listen(states.add);

        // Start session
        bloc.add(SessionStarted());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // User authenticated
        controller.add(_testUser);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Sign out
        bloc.add(SessionSignOutRequested());
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Verify states include loading, authenticated, and then unknown
        final authenticatedStates = states
            .where((s) => s.status == SessionStatus.authenticated)
            .toList();
        expect(authenticatedStates, isNotEmpty);

        final unknownStates = states
            .where(
                (s) => s.status == SessionStatus.unknown && !s.isLoading)
            .toList();
        expect(unknownStates, isNotEmpty);

        await sub.cancel();
        await controller.close();
        await bloc.close();
      });
    });
  });
}

// =============================================================================
// Test Data
// =============================================================================

const _testUser = CrushUser(
  id: 'test-user-id',
  phoneNumber: '+1234567890',
  isEmailVerified: false,
  isPhoneVerified: true,
  isIdVerified: false,
  tier: SubscriptionTier.free,
  profile: null,
);

// =============================================================================
// Stub Repository
// =============================================================================

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({
    this.userStreamController,
    this.shouldFailBootstrap = false,
    this.shouldFailSignOut = false,
  });

  final StreamController<CrushUser?>? userStreamController;
  final bool shouldFailBootstrap;
  final bool shouldFailSignOut;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

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
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async =>
      _testUser;

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async =>
      _testUser;

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async =>
      _testUser;

  @override
  Future<CrushUser> signInWithApple() async => _testUser;

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async =>
      _testUser;

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async =>
      _testUser;

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
  }) async =>
      _testUser;

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async =>
      'reset-token';

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
@override
  Future<void> verifyPassword(String password) async {}

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
  Future<CrushUser> acceptTermsAndConditions() async =>
      _testUser.copyWith(hasAcceptedTerms: true);

  @override
  Future<CrushUser?> refreshCurrentUser() async => _testUser;
}
