import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('DiscoveryBloc', () {
    group('Initial State', () {
      test('has correct initial values', () {
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: const []),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        expect(bloc.state.status, DeckStatus.initial);
        expect(bloc.state.deck, isEmpty);
        expect(bloc.state.currentIndex, 0);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.newMatch, isNull);
        expect(bloc.state.superLikesRemaining, 1);
        expect(bloc.state.canRewind, false);

        bloc.close();
      });
    });

    group('DiscoveryDeckRequested', () {
      test('emits empty status when deck is empty', () async {
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: const []),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        bloc.add(DiscoveryDeckRequested('user-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DiscoveryState>()
                .having((s) => s.isLoading, 'isLoading', true)
                .having((s) => s.status, 'status', DeckStatus.loading),
            isA<DiscoveryState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.status, 'status', DeckStatus.empty)
                .having((s) => s.deck.isEmpty, 'deck empty', true),
          ]),
        );

        await bloc.close();
      });

      test('emits ready status with profiles when deck has data', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        bloc.add(DiscoveryDeckRequested('user-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DiscoveryState>().having(
              (s) => s.status,
              'status',
              DeckStatus.loading,
            ),
            isA<DiscoveryState>()
                .having((s) => s.status, 'status', DeckStatus.ready)
                .having((s) => s.deck.length, 'deck length', 2)
                .having((s) => s.currentIndex, 'currentIndex', 0),
          ]),
        );

        await bloc.close();
      });

      test('emits error status when fetch fails', () async {
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: const [],
            shouldFailFetch: true,
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        bloc.add(DiscoveryDeckRequested('user-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DiscoveryState>().having(
              (s) => s.status,
              'status',
              DeckStatus.loading,
            ),
            isA<DiscoveryState>()
                .having((s) => s.status, 'status', DeckStatus.error)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('DiscoverySwipedRight', () {
      test('advances current index on swipe right', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck first
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe right
        bloc.add(DiscoverySwipedRight(userId: 'user-1', targetUserId: 'p1'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.currentIndex, 'currentIndex', 1)
                .having((s) => s.lastSwipeDirection, 'direction', 'right')
                .having((s) => s.canRewind, 'canRewind', true),
          ),
        );

        await bloc.close();
      });

      test('emits new match when match occurs', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final match = _testMatch('match-1');
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: profiles,
            matchOnSwipeRight: match,
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck first
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe right
        bloc.add(DiscoverySwipedRight(userId: 'user-1', targetUserId: 'p1'));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<DiscoveryState>()
                .having((s) => s.newMatch, 'newMatch', isNotNull)
                .having(
                  (s) => s.newMatch?.matchId,
                  'matchId',
                  equals('match-1'),
                ),
          ),
        );

        await bloc.close();
      });

      test('allows swiping when plan has remaining swipes', () async {
        final profiles = List.generate(5, (i) => _testProfile('p$i'));
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
            dailySwipesRemaining: 10,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe right - should succeed
        bloc.add(DiscoverySwipedRight(userId: 'user-1', targetUserId: 'p0'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>().having(
              (s) => s.currentIndex,
              'currentIndex',
              1,
            ),
          ),
        );

        await bloc.close();
      });

      test('does nothing when deck is empty', () async {
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: const []),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load empty deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Try to swipe
        bloc.add(
          DiscoverySwipedRight(userId: 'user-1', targetUserId: 'nobody'),
        );

        // Should not emit any changes after the empty deck
        await Future.delayed(const Duration(milliseconds: 100));
        expect(bloc.state.currentIndex, 0);

        await bloc.close();
      });
    });

    group('DiscoverySwipedLeft', () {
      test('advances current index on swipe left', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck first
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe left
        bloc.add(DiscoverySwipedLeft(userId: 'user-1', targetUserId: 'p1'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.currentIndex, 'currentIndex', 1)
                .having((s) => s.lastSwipeDirection, 'direction', 'left')
                .having((s) => s.canRewind, 'canRewind', true),
          ),
        );

        await bloc.close();
      });
    });

    group('DiscoverySuperLiked', () {
      test('consumes super like and advances index', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck first
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Super like
        bloc.add(DiscoverySuperLiked(userId: 'user-1', targetUserId: 'p1'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.currentIndex, 'currentIndex', 1)
                .having((s) => s.superLikesRemaining, 'remaining', 0)
                .having((s) => s.lastSwipeDirection, 'direction', 'superlike'),
          ),
        );

        await bloc.close();
      });

      test('shows error when no super likes remaining', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck first
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Use up super like
        bloc.add(DiscoverySuperLiked(userId: 'user-1', targetUserId: 'p1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Try again - should fail
        bloc.add(DiscoverySuperLiked(userId: 'user-1', targetUserId: 'p2'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>().having(
              (s) => s.errorMessage,
              'error',
              contains('super like'),
            ),
          ),
        );

        await bloc.close();
      });
    });

    group('DiscoveryRewindRequested', () {
      test('restores last swiped profile for free user first undo', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: profiles,
            rewindProfile: profiles[0],
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe left
        bloc.add(DiscoverySwipedLeft(userId: 'user-1', targetUserId: 'p1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Rewind
        bloc.add(DiscoveryRewindRequested('user-1'));

        // Use emitsThrough to wait for the final state after rewind completes
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<DiscoveryState>()
                .having((s) => s.currentIndex, 'currentIndex', 0)
                .having((s) => s.canRewind, 'canRewind', false),
          ),
        );

        // Verify free undo was used
        expect(bloc.state.freeUndoUsedToday, true);

        await bloc.close();
      });

      test('shows error when no swipe to undo', () async {
        final profiles = [_testProfile('p1')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck but don't swipe
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Try to rewind without swiping
        bloc.add(DiscoveryRewindRequested('user-1'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>().having(
              (s) => s.errorMessage,
              'error',
              contains('undo'),
            ),
          ),
        );

        await bloc.close();
      });

      test('plus users can rewind without limit', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: profiles,
            rewindProfile: profiles[0],
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.plus,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Swipe left
        bloc.add(DiscoverySwipedLeft(userId: 'user-1', targetUserId: 'p1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Rewind
        bloc.add(DiscoveryRewindRequested('user-1'));

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.currentIndex, 'currentIndex', 0)
                .having((s) => s.canRewind, 'canRewind', false)
                .having((s) => s.freeUndoUsedToday, 'freeUndoUsed', false),
          ),
        );

        await bloc.close();
      });
    });

    group('DiscoveryLoadMoreRequested', () {
      test('appends new profiles to deck', () async {
        final initialDeck = [_testProfile('p1')];
        final moreDeck = [_testProfile('p2'), _testProfile('p3')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: initialDeck,
            moreDeck: moreDeck,
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load initial deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Request more
        bloc.add(DiscoveryLoadMoreRequested('user-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DiscoveryState>().having(
              (s) => s.isLoadingMore,
              'loading',
              true,
            ),
            isA<DiscoveryState>()
                .having((s) => s.isLoadingMore, 'loading', false)
                .having((s) => s.deck.length, 'length', 3),
          ]),
        );

        await bloc.close();
      });

      test('does not load when already loading more', () async {
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: [_testProfile('p1')],
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Manually set loading state would be needed here
        // For now just ensure the method doesn't crash
        bloc.add(DiscoveryLoadMoreRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 50));

        await bloc.close();
      });
    });

    group('DiscoveryMatchCelebrationShown', () {
      test('clears new match from state', () async {
        final profiles = [_testProfile('p1')];
        final match = _testMatch('match-1');
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(
            deck: profiles,
            matchOnSwipeRight: match,
          ),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck and swipe to get match
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(DiscoverySwipedRight(userId: 'user-1', targetUserId: 'p1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify match exists
        expect(bloc.state.newMatch, isNotNull);

        // Clear match
        bloc.add(DiscoveryMatchCelebrationShown());

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>().having((s) => s.newMatch, 'newMatch', isNull),
          ),
        );

        await bloc.close();
      });
    });

    group('DiscoveryResetRequested', () {
      test('resets state to initial', () async {
        final profiles = [_testProfile('p1'), _testProfile('p2')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(),
        );

        // Load deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify deck loaded
        expect(bloc.state.deck.isNotEmpty, true);

        // Reset
        bloc.add(DiscoveryResetRequested());

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.status, 'status', DeckStatus.initial)
                .having((s) => s.deck, 'deck', isEmpty)
                .having((s) => s.currentIndex, 'index', 0),
          ),
        );

        await bloc.close();
      });
    });

    group('Auth State Changes', () {
      test('resets state when user logs out', () async {
        final authController = StreamController<CrushUser?>();
        final profiles = [_testProfile('p1')];
        final bloc = DiscoveryBloc(
          discoveryRepository: _StubDiscoveryRepository(deck: profiles),
          subscriptionRepository: _StubSubscriptionRepository(
            SubscriptionPlan.free,
          ),
          authRepository: _StubAuthRepository(
            userStreamController: authController,
          ),
        );

        // Load deck
        bloc.add(DiscoveryDeckRequested('user-1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // User logs out
        authController.add(null);

        await expectLater(
          bloc.stream,
          emits(
            isA<DiscoveryState>()
                .having((s) => s.status, 'status', DeckStatus.initial)
                .having((s) => s.deck, 'deck', isEmpty),
          ),
        );

        await authController.close();
        await bloc.close();
      });
    });
  });
}

// =============================================================================
// Test Helpers
// =============================================================================

const _testPreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 50,
  maxDistanceKm: 100,
  showMeGenders: ['female'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'New York',
);

Profile _testProfile(String id) => Profile(
  id: id,
  name: 'Test $id',
  age: 25,
  gender: 'male',
  photoUrls: const [],
  videoUrls: const [],
  bio: 'Test bio',
  interests: const [],
  country: 'US',
  city: 'New York',
  isVerified: false,
  preferences: _testPreferences,
);

CrushMatch _testMatch(String id) => CrushMatch(
  id: id,
  userId: 'user-1',
  otherUserId: 'p1',
  status: MatchStatus.mutual,
  preMatchMessageRequestsCount: 0,
  pinnedForUser: false,
);

// =============================================================================
// Stub Repositories
// =============================================================================

class _StubDiscoveryRepository implements DiscoveryRepository {
  _StubDiscoveryRepository({
    required this.deck,
    this.moreDeck = const [],
    this.shouldFailFetch = false,
    this.matchOnSwipeRight,
    this.rewindProfile,
  });

  final List<Profile> deck;
  final List<Profile> moreDeck;
  final bool shouldFailFetch;
  final CrushMatch? matchOnSwipeRight;
  final Profile? rewindProfile;
  bool _firstFetch = true;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async {
    if (shouldFailFetch) {
      throw Exception('Failed to fetch deck');
    }
    if (_firstFetch) {
      _firstFetch = false;
      return deck;
    }
    return moreDeck;
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    return matchOnSwipeRight;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {}

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async => const [];

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => const [];

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    try {
      return deck.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async => matchOnSwipeRight;

  @override
  Future<Profile?> rewindLastSwipe(String userId) async => rewindProfile;
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  _StubSubscriptionRepository(this.plan, {this.dailySwipesRemaining = 10});

  final SubscriptionPlan plan;
  final int dailySwipesRemaining;

  @override
  Stream<SubscriptionPlan> watchPlan() => Stream.value(plan);

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => plan;

  @override
  Future<String> startPlusCheckout() async => 'stub';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(plan: plan);

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented in test');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.userStreamController});

  final StreamController<CrushUser?>? userStreamController;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Stream<CrushUser?> authStateChanges() =>
      userStreamController?.stream ?? const Stream.empty();

  @override
  Future<void> bootstrapSession() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signInWithApple() {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
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
  Future<CrushUser> acceptTermsAndConditions() {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
