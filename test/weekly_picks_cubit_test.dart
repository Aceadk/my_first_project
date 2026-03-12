import 'dart:async';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/data/services/weekly_picks_service.dart';
import 'package:crushhour/features/discovery/domain/models/weekly_picks.dart';
import 'package:crushhour/features/discovery/presentation/bloc/weekly_picks_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

// =============================================================================
// Test Helpers
// =============================================================================

const _testUserId = 'user-weekly-123';

CrushUser _makeUser({String id = _testUserId}) => CrushUser(
  id: id,
  phoneNumber: '+1234567890',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  tier: SubscriptionTier.free,
);

WeeklyPick _makePick({
  required String id,
  String profileId = 'profile-1',
  PickReason reason = PickReason.topPick,
  int? matchScore = 85,
  List<String> commonInterests = const ['Travel', 'Music'],
}) {
  return WeeklyPick(
    id: id,
    profileId: profileId,
    reason: reason,
    matchScore: matchScore,
    commonInterests: commonInterests,
  );
}

WeeklyPicks _makeWeeklyPicks({
  String userId = _testUserId,
  List<WeeklyPick>? picks,
  List<String> viewedPicks = const [],
  List<String> likedPicks = const [],
}) {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  return WeeklyPicks(
    userId: userId,
    weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
    weekEnd: DateTime(weekEnd.year, weekEnd.month, weekEnd.day),
    picks:
        picks ??
        [
          _makePick(id: 'pick-0'),
          _makePick(id: 'pick-1', reason: PickReason.sharedInterests),
          _makePick(id: 'pick-2', reason: PickReason.nearbyLocation),
        ],
    viewedPicks: viewedPicks,
    likedPicks: likedPicks,
    refreshedAt: now,
  );
}

// =============================================================================
// Mock AuthRepository (minimal — only authStateChanges needed)
// =============================================================================

class MockAuthRepository implements AuthRepository {
  final _authController = StreamController<CrushUser?>.broadcast();

  void pushUser(CrushUser? user) => _authController.add(user);

  @override
  Stream<CrushUser?> authStateChanges() => _authController.stream;

  void dispose() => _authController.close();

  // --- Stubs for all other methods ---
  @override
  bool get isVerificationBypassEnabled => false;
  @override
  bool get supportsUsernameLogin => false;
  @override
  bool get supportsAppleSignIn => false;
  @override
  Future<void> bootstrapSession() async {}
  @override
  Future<void> sendOtp(String phoneNumber) async {}
  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) => throw UnimplementedError();
  @override
  Future<void> sendEmailSignInLink(String email) async {}
  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<CrushUser> signInWithApple() => throw UnimplementedError();
  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) => throw UnimplementedError();
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
  }) async => null;
  @override
  Future<void> requestPasswordReset({required String email}) async {}
  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) => throw UnimplementedError();
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
  Future<void> verifyPassword(String password) async {}

  @override
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
  Future<CrushUser> acceptTermsAndConditions() => throw UnimplementedError();
  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setupFirebaseAnalyticsMocks();

  // ─── WeeklyPick model tests ───────────────────────────────────────────────

  group('WeeklyPick model', () {
    test('constructor sets all fields', () {
      final pick = _makePick(
        id: 'p1',
        profileId: 'prof-1',
        reason: PickReason.highCompatibility,
        matchScore: 92,
        commonInterests: ['Hiking', 'Art'],
      );

      expect(pick.id, 'p1');
      expect(pick.profileId, 'prof-1');
      expect(pick.reason, PickReason.highCompatibility);
      expect(pick.matchScore, 92);
      expect(pick.commonInterests, ['Hiking', 'Art']);
      expect(pick.profile, isNull);
      expect(pick.highlightedPromptIndex, isNull);
    });

    test('reasonDisplay returns correct text', () {
      expect(
        _makePick(id: 'a', reason: PickReason.topPick).reasonDisplay,
        'Top Pick for You',
      );
      expect(
        _makePick(id: 'b', reason: PickReason.sharedInterests).reasonDisplay,
        'Shared Interests',
      );
      expect(
        _makePick(id: 'c', reason: PickReason.nearbyLocation).reasonDisplay,
        'Lives Nearby',
      );
      expect(
        _makePick(id: 'd', reason: PickReason.highCompatibility).reasonDisplay,
        'High Compatibility',
      );
      expect(
        _makePick(id: 'e', reason: PickReason.newToArea).reasonDisplay,
        'New to Your Area',
      );
      expect(
        _makePick(id: 'f', reason: PickReason.popularProfile).reasonDisplay,
        'Popular Profile',
      );
      expect(
        _makePick(id: 'g', reason: PickReason.similarLifestyle).reasonDisplay,
        'Similar Lifestyle',
      );
      expect(
        _makePick(id: 'h', reason: PickReason.educationMatch).reasonDisplay,
        'Education Match',
      );
      expect(
        _makePick(
          id: 'i',
          reason: PickReason.relationshipGoalsMatch,
        ).reasonDisplay,
        'Same Relationship Goals',
      );
    });

    test('copyWith preserves unchanged fields', () {
      final pick = _makePick(id: 'orig', matchScore: 80);
      final copy = pick.copyWith(matchScore: 95);
      expect(copy.id, 'orig');
      expect(copy.matchScore, 95);
      expect(copy.reason, pick.reason);
    });

    test('toJson and fromJson round-trip correctly', () {
      final pick = _makePick(id: 'rt-1', matchScore: 75);
      final json = pick.toJson();
      final restored = WeeklyPick.fromJson(json);

      expect(restored.id, pick.id);
      expect(restored.profileId, pick.profileId);
      expect(restored.reason, pick.reason);
      expect(restored.matchScore, pick.matchScore);
      expect(restored.commonInterests, pick.commonInterests);
    });

    test('fromJson with unknown reason defaults to topPick', () {
      final json = {
        'id': 'unknown-reason',
        'profileId': 'p1',
        'reason': 'nonexistent_reason',
      };
      final pick = WeeklyPick.fromJson(json);
      expect(pick.reason, PickReason.topPick);
    });

    test('Equatable compares correctly', () {
      final a = _makePick(id: 'same');
      final b = _makePick(id: 'same');
      expect(a, equals(b));

      final c = _makePick(id: 'diff');
      expect(a, isNot(equals(c)));
    });
  });

  // ─── PickReason enum tests ────────────────────────────────────────────────

  group('PickReason', () {
    test('has all expected values', () {
      expect(PickReason.values, hasLength(9));
    });

    test('each reason has an emoji', () {
      for (final reason in PickReason.values) {
        expect(reason.emoji, isNotEmpty);
      }
    });

    test('each reason has display text', () {
      for (final reason in PickReason.values) {
        expect(reason.displayText, isNotEmpty);
      }
    });
  });

  // ─── WeeklyPicks model tests ──────────────────────────────────────────────

  group('WeeklyPicks model', () {
    test('constructor sets all fields with defaults', () {
      final picks = _makeWeeklyPicks();
      expect(picks.userId, _testUserId);
      expect(picks.picks, hasLength(3));
      expect(picks.viewedPicks, isEmpty);
      expect(picks.likedPicks, isEmpty);
    });

    test('maxPicks is 10', () {
      expect(WeeklyPicks.maxPicks, 10);
    });

    test('unseenCount returns picks.length minus viewedPicks.length', () {
      final picks = _makeWeeklyPicks(viewedPicks: ['pick-0']);
      expect(picks.unseenCount, 2); // 3 picks - 1 viewed
    });

    test('allViewed returns true when all picks are viewed', () {
      final picks = _makeWeeklyPicks(
        viewedPicks: ['pick-0', 'pick-1', 'pick-2'],
      );
      expect(picks.allViewed, isTrue);
    });

    test('allViewed returns false when not all viewed', () {
      final picks = _makeWeeklyPicks(viewedPicks: ['pick-0']);
      expect(picks.allViewed, isFalse);
    });

    test('isCurrentWeek returns true for current week', () {
      final picks = _makeWeeklyPicks();
      expect(picks.isCurrentWeek, isTrue);
    });

    test('isCurrentWeek returns false for past week', () {
      final pastPicks = WeeklyPicks(
        userId: _testUserId,
        weekStart: DateTime(2020, 1, 1),
        weekEnd: DateTime(2020, 1, 7),
        picks: const [],
      );
      expect(pastPicks.isCurrentWeek, isFalse);
    });

    test('markViewed adds pickId to viewedPicks', () {
      final picks = _makeWeeklyPicks();
      final updated = picks.markViewed('pick-0');
      expect(updated.viewedPicks, contains('pick-0'));
    });

    test('markViewed does not duplicate already-viewed pick', () {
      final picks = _makeWeeklyPicks(viewedPicks: ['pick-0']);
      final updated = picks.markViewed('pick-0');
      expect(updated.viewedPicks.where((id) => id == 'pick-0'), hasLength(1));
    });

    test('markLiked adds to both likedPicks and viewedPicks', () {
      final picks = _makeWeeklyPicks();
      final updated = picks.markLiked('pick-1');
      expect(updated.likedPicks, contains('pick-1'));
      expect(updated.viewedPicks, contains('pick-1'));
    });

    test('markLiked does not duplicate already-liked pick', () {
      final picks = _makeWeeklyPicks(likedPicks: ['pick-0']);
      final updated = picks.markLiked('pick-0');
      expect(updated.likedPicks.where((id) => id == 'pick-0'), hasLength(1));
    });

    test('markLiked preserves existing viewedPicks', () {
      final picks = _makeWeeklyPicks(viewedPicks: ['pick-0']);
      final updated = picks.markLiked('pick-1');
      expect(updated.viewedPicks, containsAll(['pick-0', 'pick-1']));
    });

    test('newPicksTimeDisplay shows days and hours for future end', () {
      final picks = _makeWeeklyPicks();
      final display = picks.newPicksTimeDisplay;
      // Should be a non-empty string; exact content depends on current time
      expect(display, isNotEmpty);
    });

    test('newPicksTimeDisplay shows "New picks available!" for past end', () {
      final pastPicks = WeeklyPicks(
        userId: _testUserId,
        weekStart: DateTime(2020, 1, 1),
        weekEnd: DateTime(2020, 1, 7),
        picks: const [],
      );
      expect(pastPicks.newPicksTimeDisplay, 'New picks available!');
    });

    test('toJson and fromJson round-trip correctly', () {
      final picks = _makeWeeklyPicks();
      final json = picks.toJson();
      final restored = WeeklyPicks.fromJson(json);

      expect(restored.userId, picks.userId);
      expect(restored.picks.length, picks.picks.length);
      expect(restored.viewedPicks, picks.viewedPicks);
      expect(restored.likedPicks, picks.likedPicks);
    });

    test('copyWith preserves unmodified fields', () {
      final picks = _makeWeeklyPicks();
      final copy = picks.copyWith(viewedPicks: ['pick-0']);
      expect(copy.userId, picks.userId);
      expect(copy.picks, picks.picks);
      expect(copy.viewedPicks, ['pick-0']);
    });

    test('Equatable compares correctly', () {
      final now = DateTime(2026, 2, 13, 12, 0, 0);
      final weekStart = DateTime(2026, 2, 9);
      final weekEnd = DateTime(2026, 2, 16);
      final picks = [_makePick(id: 'p1')];

      final a = WeeklyPicks(
        userId: 'u1',
        weekStart: weekStart,
        weekEnd: weekEnd,
        picks: picks,
        refreshedAt: now,
      );
      final b = WeeklyPicks(
        userId: 'u1',
        weekStart: weekStart,
        weekEnd: weekEnd,
        picks: picks,
        refreshedAt: now,
      );
      expect(a, equals(b));

      final c = WeeklyPicks(
        userId: 'u2', // different userId
        weekStart: weekStart,
        weekEnd: weekEnd,
        picks: picks,
        refreshedAt: now,
      );
      expect(a, isNot(equals(c)));
    });
  });

  // ─── WeeklyPicksState tests ───────────────────────────────────────────────

  group('WeeklyPicksState', () {
    test('default state has correct values', () {
      const state = WeeklyPicksState();
      expect(state.picks, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.currentIndex, 0);
    });

    test('picksList returns empty list when picks is null', () {
      const state = WeeklyPicksState();
      expect(state.picksList, isEmpty);
    });

    test('picksList returns picks list when picks is set', () {
      final weeklyPicks = _makeWeeklyPicks();
      final state = WeeklyPicksState(picks: weeklyPicks);
      expect(state.picksList, hasLength(3));
    });

    test('unseenCount returns 0 when picks is null', () {
      const state = WeeklyPicksState();
      expect(state.unseenCount, 0);
    });

    test('unseenCount returns correct value from picks', () {
      final weeklyPicks = _makeWeeklyPicks(viewedPicks: ['pick-0']);
      final state = WeeklyPicksState(picks: weeklyPicks);
      expect(state.unseenCount, 2);
    });

    test('hasUnseenPicks returns false when no picks', () {
      const state = WeeklyPicksState();
      expect(state.hasUnseenPicks, isFalse);
    });

    test('hasUnseenPicks returns true when unseen picks exist', () {
      final weeklyPicks = _makeWeeklyPicks();
      final state = WeeklyPicksState(picks: weeklyPicks);
      expect(state.hasUnseenPicks, isTrue);
    });

    test('newPicksTimeDisplay returns empty string when no picks', () {
      const state = WeeklyPicksState();
      expect(state.newPicksTimeDisplay, '');
    });

    test('currentPick returns null when no picks', () {
      const state = WeeklyPicksState();
      expect(state.currentPick, isNull);
    });

    test('currentPick returns pick at currentIndex', () {
      final weeklyPicks = _makeWeeklyPicks();
      const state = WeeklyPicksState(currentIndex: 1);
      final stateWithPicks = state.copyWith(picks: weeklyPicks);
      expect(stateWithPicks.currentPick?.id, 'pick-1');
    });

    test('currentPick returns null when index is out of range', () {
      final weeklyPicks = _makeWeeklyPicks();
      final state = WeeklyPicksState(picks: weeklyPicks, currentIndex: 99);
      expect(state.currentPick, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      final weeklyPicks = _makeWeeklyPicks();
      final state = WeeklyPicksState(picks: weeklyPicks, currentIndex: 2);
      final updated = state.copyWith(isLoading: true);
      expect(updated.picks, weeklyPicks);
      expect(updated.currentIndex, 2);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clears errorMessage when not provided', () {
      const state = WeeklyPicksState(errorMessage: 'old error');
      final updated = state.copyWith(isLoading: false);
      // errorMessage in copyWith is nullable without default, so it becomes null
      expect(updated.errorMessage, isNull);
    });

    test('Equatable compares correctly', () {
      const a = WeeklyPicksState(isLoading: true, currentIndex: 1);
      const b = WeeklyPicksState(isLoading: true, currentIndex: 1);
      const c = WeeklyPicksState(isLoading: false, currentIndex: 1);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ─── WeeklyPicksCubit tests ───────────────────────────────────────────────

  group('WeeklyPicksCubit', () {
    late MockAuthRepository authRepo;
    late WeeklyPicksCubit cubit;

    setUp(() {
      authRepo = MockAuthRepository();
      // Clear singleton state from previous tests
      WeeklyPicksService.instance.clearUserData();
      cubit = WeeklyPicksCubit(
        authRepository: authRepo,
        weeklyPicksRepository: WeeklyPicksService.instance,
      );
    });

    tearDown(() {
      cubit.close();
      authRepo.dispose();
    });

    test('initial state is default WeeklyPicksState', () {
      expect(cubit.state, const WeeklyPicksState());
      expect(cubit.state.picks, isNull);
      expect(cubit.state.isLoading, isFalse);
    });

    // ── loadPicks() ──

    test('loadPicks emits loading then data on success', () async {
      final states = <WeeklyPicksState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadPicks(_testUserId);
      // The service has a 500ms simulated delay
      await Future.delayed(const Duration(milliseconds: 700));

      // First emission: loading=true
      expect(states.first.isLoading, isTrue);
      expect(states.first.errorMessage, isNull);

      // Should eventually have data loaded
      final dataState = states.lastWhere(
        (s) => !s.isLoading && s.picks != null,
      );
      expect(dataState.picks, isNotNull);
      expect(dataState.picks!.picks, hasLength(WeeklyPicks.maxPicks));
      expect(dataState.isLoading, isFalse);

      await sub.cancel();
    });

    test('loadPicks sets picks with demo data from service', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      expect(cubit.state.picks, isNotNull);
      expect(cubit.state.picks!.userId, _testUserId);
      expect(cubit.state.picks!.picks, hasLength(10));
    });

    // ── moveToNextPick() ──

    test('moveToNextPick increments currentIndex', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      expect(cubit.state.currentIndex, 0);

      cubit.moveToNextPick();
      expect(cubit.state.currentIndex, 1);

      cubit.moveToNextPick();
      expect(cubit.state.currentIndex, 2);
    });

    test('moveToNextPick does not exceed last pick index', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final lastIndex = cubit.state.picksList.length - 1;

      // Move to last pick
      for (int i = 0; i < lastIndex; i++) {
        cubit.moveToNextPick();
      }
      expect(cubit.state.currentIndex, lastIndex);

      // Try to move past the end
      cubit.moveToNextPick();
      expect(cubit.state.currentIndex, lastIndex); // Should not change
    });

    test('moveToNextPick does nothing when no picks loaded', () {
      expect(cubit.state.currentIndex, 0);
      cubit.moveToNextPick();
      expect(cubit.state.currentIndex, 0);
    });

    // ── goToPick() ──

    test('goToPick sets currentIndex to specified index', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      cubit.goToPick(5);
      expect(cubit.state.currentIndex, 5);
    });

    test('goToPick ignores negative index', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      cubit.goToPick(3);
      cubit.goToPick(-1);
      expect(cubit.state.currentIndex, 3); // Unchanged
    });

    test('goToPick ignores out-of-bounds index', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      cubit.goToPick(2);
      cubit.goToPick(999);
      expect(cubit.state.currentIndex, 2); // Unchanged
    });

    test('goToPick marks the pick as viewed', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final pickId = cubit.state.picksList[3].id;
      expect(cubit.isPickViewed(pickId), isFalse);

      cubit.goToPick(3);
      // markPickViewed is async in the service, give it time
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.isPickViewed(pickId), isTrue);
    });

    // ── viewCurrentPick() ──

    test('viewCurrentPick marks current pick as viewed', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final pickId = cubit.state.picksList[0].id;
      expect(cubit.isPickViewed(pickId), isFalse);

      cubit.viewCurrentPick();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.isPickViewed(pickId), isTrue);
    });

    test('viewCurrentPick does nothing when no picks loaded', () {
      // No picks loaded, currentPick is null
      cubit.viewCurrentPick(); // Should not throw
    });

    // ── likeCurrentPick() ──

    test('likeCurrentPick marks pick as liked and moves to next', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final pickId = cubit.state.picksList[0].id;
      expect(cubit.isPickLiked(pickId), isFalse);
      expect(cubit.state.currentIndex, 0);

      cubit.likeCurrentPick();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.isPickLiked(pickId), isTrue);
      expect(cubit.state.currentIndex, 1);
    });

    test('likeCurrentPick does nothing when no picks loaded', () {
      cubit.likeCurrentPick(); // Should not throw
      expect(cubit.state.currentIndex, 0);
    });

    // ── passCurrentPick() ──

    test('passCurrentPick moves to next pick without liking', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final pickId = cubit.state.picksList[0].id;
      expect(cubit.state.currentIndex, 0);

      cubit.passCurrentPick();

      expect(cubit.state.currentIndex, 1);
      expect(cubit.isPickLiked(pickId), isFalse);
    });

    test('passCurrentPick does nothing at last pick', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final lastIndex = cubit.state.picksList.length - 1;
      for (int i = 0; i < lastIndex; i++) {
        cubit.passCurrentPick();
      }
      expect(cubit.state.currentIndex, lastIndex);

      cubit.passCurrentPick();
      expect(cubit.state.currentIndex, lastIndex); // No change
    });

    // ── isPickViewed() / isPickLiked() delegation ──

    test('isPickViewed delegates to service', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      expect(cubit.isPickViewed('pick_0'), isFalse);
      WeeklyPicksService.instance.markPickViewed('pick_0');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.isPickViewed('pick_0'), isTrue);
    });

    test('isPickLiked delegates to service', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      expect(cubit.isPickLiked('pick_0'), isFalse);
      WeeklyPicksService.instance.markPickLiked('pick_0');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(cubit.isPickLiked('pick_0'), isTrue);
    });

    // ── Auth state change resets state ──

    test('signing out resets state to default', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      expect(cubit.state.picks, isNotNull);

      final states = <WeeklyPicksState>[];
      final sub = cubit.stream.listen(states.add);

      // Simulate sign out (null user)
      authRepo.pushUser(null);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(states.last, const WeeklyPicksState());
      expect(states.last.picks, isNull);
      expect(states.last.isLoading, isFalse);

      await sub.cancel();
    });

    test('auth state with non-null user does NOT reset state', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      final picksBefore = cubit.state.picks;
      expect(picksBefore, isNotNull);

      // Push a non-null user (e.g., user re-auth)
      authRepo.pushUser(_makeUser());
      await Future.delayed(const Duration(milliseconds: 100));

      // State should NOT have been reset
      expect(cubit.state.picks, isNotNull);
    });

    test('switching to a different authenticated user resets state', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));
      expect(cubit.state.picks, isNotNull);

      // Establish current auth identity
      authRepo.pushUser(_makeUser(id: 'user-a'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.picks, isNotNull);

      // Different authenticated user should trigger reset
      authRepo.pushUser(_makeUser(id: 'user-b'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(cubit.state, const WeeklyPicksState());
    });

    // ── close() / lifecycle ──

    test('close cancels subscriptions without error', () async {
      await cubit.loadPicks(_testUserId);
      await Future.delayed(const Duration(milliseconds: 700));

      await cubit.close();
      // No exception expected
    });

    test('close can be called immediately without loading', () async {
      await cubit.close();
      // No exception expected
    });
  });

  // ─── WeeklyPicksService tests ─────────────────────────────────────────────

  group('WeeklyPicksService', () {
    setUp(() {
      WeeklyPicksService.instance.clearUserData();
    });

    test('singleton returns the same instance', () {
      final a = WeeklyPicksService.instance;
      final b = WeeklyPicksService.instance;
      expect(identical(a, b), isTrue);
    });

    test('currentPicks is null before loading', () {
      expect(WeeklyPicksService.instance.currentPicks, isNull);
    });

    test('loadPicks returns WeeklyPicks with demo data', () async {
      final picks = await WeeklyPicksService.instance.loadPicks('user-1');
      expect(picks.userId, 'user-1');
      expect(picks.picks, hasLength(10));
    });

    test('loadPicks sets currentPicks', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.currentPicks, isNotNull);
    });

    test('hasUnseenPicks is true after fresh load', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.hasUnseenPicks, isTrue);
    });

    test('hasUnseenPicks is false before loading', () {
      expect(WeeklyPicksService.instance.hasUnseenPicks, isFalse);
    });

    test('unseenCount matches number of picks before viewing', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.unseenCount, 10);
    });

    test('markPickViewed reduces unseenCount', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      final pickId = WeeklyPicksService.instance.currentPicks!.picks.first.id;

      await WeeklyPicksService.instance.markPickViewed(pickId);

      expect(WeeklyPicksService.instance.unseenCount, 9);
      expect(WeeklyPicksService.instance.isPickViewed(pickId), isTrue);
    });

    test('markPickLiked also marks as viewed', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      final pickId = WeeklyPicksService.instance.currentPicks!.picks.first.id;

      await WeeklyPicksService.instance.markPickLiked(pickId);

      expect(WeeklyPicksService.instance.isPickLiked(pickId), isTrue);
      expect(WeeklyPicksService.instance.isPickViewed(pickId), isTrue);
    });

    test('isPickViewed returns false for unviewed pick', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.isPickViewed('nonexistent'), isFalse);
    });

    test('isPickLiked returns false for unliked pick', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.isPickLiked('nonexistent'), isFalse);
    });

    test('getUnviewedPicks returns all picks initially', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.getUnviewedPicks(), hasLength(10));
    });

    test('getUnviewedPicks decreases after viewing', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      final pickId = WeeklyPicksService.instance.currentPicks!.picks.first.id;
      await WeeklyPicksService.instance.markPickViewed(pickId);

      expect(WeeklyPicksService.instance.getUnviewedPicks(), hasLength(9));
    });

    test('getAllPicks returns empty list before loading', () {
      expect(WeeklyPicksService.instance.getAllPicks(), isEmpty);
    });

    test('getAllPicks returns all picks after loading', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.getAllPicks(), hasLength(10));
    });

    test('isCurrentWeek returns false before loading', () {
      expect(WeeklyPicksService.instance.isCurrentWeek, isFalse);
    });

    test('isCurrentWeek returns true after loading current week', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.isCurrentWeek, isTrue);
    });

    test('getNewPicksTimeDisplay returns "Loading..." before loading', () {
      expect(
        WeeklyPicksService.instance.getNewPicksTimeDisplay(),
        'Loading...',
      );
    });

    test('clearUserData clears currentPicks', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      expect(WeeklyPicksService.instance.currentPicks, isNotNull);

      WeeklyPicksService.instance.clearUserData();
      expect(WeeklyPicksService.instance.currentPicks, isNull);
    });

    test('markPickViewed does nothing when no picks loaded', () async {
      await WeeklyPicksService.instance.markPickViewed('some-id');
      // No exception expected
    });

    test('markPickLiked does nothing when no picks loaded', () async {
      await WeeklyPicksService.instance.markPickLiked('some-id');
      // No exception expected
    });

    test('picksStream emits updates when picks change', () async {
      final emissions = <WeeklyPicks>[];
      final sub = WeeklyPicksService.instance.picksStream.listen(emissions.add);

      await WeeklyPicksService.instance.loadPicks('user-1');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emissions, isNotEmpty);
      expect(emissions.first.userId, 'user-1');

      await sub.cancel();
    });

    test('picksStream emits on markPickViewed', () async {
      await WeeklyPicksService.instance.loadPicks('user-1');
      final pickId = WeeklyPicksService.instance.currentPicks!.picks.first.id;

      final emissions = <WeeklyPicks>[];
      final sub = WeeklyPicksService.instance.picksStream.listen(emissions.add);

      await WeeklyPicksService.instance.markPickViewed(pickId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emissions, isNotEmpty);
      expect(emissions.last.viewedPicks, contains(pickId));

      await sub.cancel();
    });

    test('getTimeUntilRefresh returns Duration.zero before loading', () {
      expect(WeeklyPicksService.instance.getTimeUntilRefresh(), Duration.zero);
    });
  });
}
