import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/boost_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';
import 'mock/noop_auth_repository.dart';
import 'mock/stub_analytics_service.dart';

CrushUser _makeAuthUser(String id) => CrushUser(
  id: id,
  phoneNumber: '+10000000000',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  plan: SubscriptionPlan.free,
);

class _AuthStreamRepository implements AuthRepository {
  final _controller = StreamController<CrushUser?>.broadcast();

  void emitUser(CrushUser? user) => _controller.add(user);
  Future<void> dispose() => _controller.close();

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  // ===========================================================================
  // BOOST STATE
  // ===========================================================================

  group('BoostState', () {
    test('default state has correct initial values', () {
      const state = BoostState();
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.tick, 0);
      expect(state.canBoost, false);
      expect(state.isBoostActive, false);
      expect(state.boostRemaining, Duration.zero);
    });

    test('canBoost is true when status allows and not loading', () {
      const state = BoostState(
        status: BoostStatus(
          canBoost: true,
          nextBoostAvailableAt: null,
          boostsRemaining: 1,
        ),
      );
      expect(state.canBoost, true);
    });

    test('canBoost is false when loading even if status allows', () {
      const state = BoostState(
        status: BoostStatus(canBoost: true, nextBoostAvailableAt: null),
        isLoading: true,
      );
      expect(state.canBoost, false);
    });

    test('isBoostActive reflects active session', () {
      final state = BoostState(
        status: BoostStatus(
          canBoost: false,
          nextBoostAvailableAt: DateTime.now().add(const Duration(hours: 1)),
          activeSession: BoostSession(
            startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
            endsAt: DateTime.now().add(const Duration(minutes: 20)),
            isActive: true,
          ),
        ),
      );
      expect(state.isBoostActive, true);
    });

    test('isBoostActive false when no active session', () {
      const state = BoostState(
        status: BoostStatus(canBoost: true, nextBoostAvailableAt: null),
      );
      expect(state.isBoostActive, false);
    });

    test('copyWith preserves values when no overrides', () {
      const state = BoostState(isLoading: true, tick: 5);
      final copied = state.copyWith();
      expect(copied.isLoading, true);
      expect(copied.tick, 5);
    });

    test('copyWith overrides specified values', () {
      const state = BoostState();
      final modified = state.copyWith(
        isLoading: true,
        errorMessage: 'fail',
        tick: 10,
      );
      expect(modified.isLoading, true);
      expect(modified.errorMessage, 'fail');
      expect(modified.tick, 10);
    });

    test('copyWith clears errorMessage when set to null', () {
      const state = BoostState(errorMessage: 'old error');
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });

    test('Equatable compares correctly', () {
      const a = BoostState(tick: 1);
      const b = BoostState(tick: 1);
      const c = BoostState(tick: 2);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ===========================================================================
  // BOOST STATUS MODEL
  // ===========================================================================

  group('BoostStatus', () {
    test('isBoostActive when activeSession is active', () {
      final status = BoostStatus(
        canBoost: false,
        nextBoostAvailableAt: null,
        activeSession: BoostSession(
          startedAt: DateTime.now(),
          endsAt: DateTime.now().add(const Duration(minutes: 30)),
          isActive: true,
        ),
      );
      expect(status.isBoostActive, true);
    });

    test('isBoostActive false when activeSession is inactive', () {
      final status = BoostStatus(
        canBoost: false,
        nextBoostAvailableAt: null,
        activeSession: BoostSession(
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          endsAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isActive: false,
        ),
      );
      expect(status.isBoostActive, false);
    });

    test('cooldownRemaining returns Duration.zero when canBoost', () {
      const status = BoostStatus(canBoost: true, nextBoostAvailableAt: null);
      expect(status.cooldownRemaining, Duration.zero);
    });

    test(
      'cooldownRemaining returns Duration.zero when nextBoostAvailableAt is null',
      () {
        const status = BoostStatus(canBoost: false, nextBoostAvailableAt: null);
        expect(status.cooldownRemaining, Duration.zero);
      },
    );

    test('cooldownRemaining returns positive duration when on cooldown', () {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      final status = BoostStatus(
        canBoost: false,
        nextBoostAvailableAt: futureTime,
      );
      expect(status.cooldownRemaining.inMinutes, greaterThan(0));
    });

    test(
      'cooldownRemaining returns Duration.zero when cooldown has passed',
      () {
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final status = BoostStatus(
          canBoost: false,
          nextBoostAvailableAt: pastTime,
        );
        expect(status.cooldownRemaining, Duration.zero);
      },
    );
  });

  // ===========================================================================
  // BOOST SESSION MODEL
  // ===========================================================================

  group('BoostSession', () {
    test('remainingDuration is positive for active future boost', () {
      final session = BoostSession(
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(minutes: 30)),
        isActive: true,
      );
      expect(session.remainingDuration.inMinutes, greaterThan(0));
      expect(session.hasExpired, false);
    });

    test('remainingDuration is zero for inactive session', () {
      final session = BoostSession(
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        endsAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isActive: false,
      );
      expect(session.remainingDuration, Duration.zero);
    });

    test('remainingDuration is zero for expired active session', () {
      final session = BoostSession(
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
        isActive: true,
      );
      expect(session.remainingDuration, Duration.zero);
      expect(session.hasExpired, true);
    });

    test('hasExpired is false for future endsAt', () {
      final session = BoostSession(
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 1)),
        isActive: true,
      );
      expect(session.hasExpired, false);
    });

    test('hasExpired is true for past endsAt', () {
      final session = BoostSession(
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        endsAt: DateTime.now().subtract(const Duration(hours: 1)),
        isActive: true,
      );
      expect(session.hasExpired, true);
    });

    test('profileViewsGained defaults to 0', () {
      final session = BoostSession(
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 1)),
        isActive: true,
      );
      expect(session.profileViewsGained, 0);
    });

    test('profileViewsGained is set correctly', () {
      final session = BoostSession(
        startedAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 1)),
        isActive: true,
        profileViewsGained: 42,
      );
      expect(session.profileViewsGained, 42);
    });
  });

  // ===========================================================================
  // BOOST CUBIT
  // ===========================================================================

  group('BoostCubit', () {
    group('Initial State', () {
      test('starts with default empty state', () {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(),
        );
        expect(cubit.state.isLoading, false);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.canBoost, false);
        expect(cubit.state.isBoostActive, false);
        cubit.close();
      });
    });

    group('initialize', () {
      test('loads boost status and emits loaded state', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
              boostsRemaining: 3,
            ),
          ),
        );

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.isNotEmpty, true);

        // Should have a loading state followed by loaded
        final loadingStates = states.where((s) => s.isLoading).toList();
        expect(loadingStates, isNotEmpty);

        final loadedStates = states
            .where((s) => !s.isLoading && s.status.canBoost)
            .toList();
        expect(loadedStates, isNotEmpty);
        expect(loadedStates.last.status.boostsRemaining, 3);

        await sub.cancel();
        await cubit.close();
      });

      test('handles status fetch failure', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(shouldFailGetStatus: true),
        );

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final errorStates = states
            .where((s) => s.errorMessage != null)
            .toList();
        expect(errorStates, isNotEmpty);
        expect(errorStates.last.isLoading, false);

        await sub.cancel();
        await cubit.close();
      });
    });

    group('activateBoost', () {
      test('activates boost and emits active session', () async {
        final now = DateTime.now();
        final endsAt = now.add(const Duration(minutes: 30));

        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
              boostsRemaining: 1,
            ),
            sessionToReturn: BoostSession(
              startedAt: now,
              endsAt: endsAt,
              isActive: true,
            ),
          ),
        );

        // Initialize first
        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        // Activate boost
        await cubit.activateBoost();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.isNotEmpty, true);

        // Should have loading then active session
        final loadingStates = states.where((s) => s.isLoading).toList();
        expect(loadingStates, isNotEmpty);

        final activeStates = states
            .where((s) => !s.isLoading && s.isBoostActive)
            .toList();
        expect(activeStates, isNotEmpty);
        expect(activeStates.last.status.activeSession, isNotNull);

        await sub.cancel();
        await cubit.close();
      });

      test('does nothing when userId is null (not initialized)', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(),
        );

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.activateBoost();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // No state changes should occur
        expect(states, isEmpty);

        await sub.cancel();
        await cubit.close();
      });

      test('does nothing when canBoost is false', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: false,
              nextBoostAvailableAt: null,
            ),
          ),
        );

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.activateBoost();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // No loading state should be emitted since canBoost is false
        final loadingStates = states.where((s) => s.isLoading).toList();
        expect(loadingStates, isEmpty);

        await sub.cancel();
        await cubit.close();
      });

      test('handles activation failure', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
              boostsRemaining: 1,
            ),
            shouldFailActivate: true,
          ),
        );

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final states = <BoostState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.activateBoost();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final errorStates = states
            .where((s) => s.errorMessage != null)
            .toList();
        expect(errorStates, isNotEmpty);
        expect(errorStates.last.isLoading, false);

        await sub.cancel();
        await cubit.close();
      });
    });

    group('Auth reset contract', () {
      test('switching authenticated user resets boost state', () async {
        final authRepository = _AuthStreamRepository();
        final cubit = BoostCubit(
          authRepository: authRepository,
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
              boostsRemaining: 1,
            ),
          ),
        );

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cubit.state.status.canBoost, isTrue);

        authRepository.emitUser(_makeAuthUser('user-a'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cubit.state.status.canBoost, isTrue);

        authRepository.emitUser(_makeAuthUser('user-b'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cubit.state, const BoostState());

        await cubit.close();
        await authRepository.dispose();
      });
    });

    group('Lifecycle', () {
      test('can close cleanly', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(),
        );
        await expectLater(cubit.close(), completes);
      });

      test('can close after initialization', () async {
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
            ),
          ),
        );

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await expectLater(cubit.close(), completes);
      });

      test('can close after activating boost with countdown timer', () async {
        final now = DateTime.now();
        final cubit = BoostCubit(
          authRepository: NoopAuthRepository(),
          boostRepository: _StubBoostRepository(
            statusToReturn: const BoostStatus(
              canBoost: true,
              nextBoostAvailableAt: null,
              boostsRemaining: 1,
            ),
            sessionToReturn: BoostSession(
              startedAt: now,
              endsAt: now.add(const Duration(minutes: 30)),
              isActive: true,
            ),
          ),
        );

        await cubit.initialize('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await cubit.activateBoost();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Close should cancel the countdown timer
        await expectLater(cubit.close(), completes);
      });
    });
  });
}

// =============================================================================
// Stub Repository
// =============================================================================

class _StubBoostRepository implements BoostRepository {
  _StubBoostRepository({
    this.statusToReturn = const BoostStatus(
      canBoost: false,
      nextBoostAvailableAt: null,
    ),
    this.sessionToReturn,
    this.shouldFailGetStatus = false,
    this.shouldFailActivate = false,
  });

  final BoostStatus statusToReturn;
  final BoostSession? sessionToReturn;
  final bool shouldFailGetStatus;
  final bool shouldFailActivate;

  @override
  Future<BoostStatus> getBoostStatus(String userId) async {
    if (shouldFailGetStatus) {
      throw Exception('Failed to get boost status');
    }
    return statusToReturn;
  }

  @override
  Future<BoostSession> activateBoost(String userId) async {
    if (shouldFailActivate) {
      throw Exception('Failed to activate boost');
    }
    return sessionToReturn ??
        BoostSession(
          startedAt: DateTime.now(),
          endsAt: DateTime.now().add(const Duration(minutes: 30)),
          isActive: true,
        );
  }

  @override
  Future<List<BoostSession>> getBoostHistory(String userId) async {
    return [];
  }
}
