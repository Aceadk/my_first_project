import 'dart:async';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/analytics/data/models/profile_insights_dto.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';
import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:crushhour/features/analytics/presentation/bloc/profile_insights_cubit.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

CrushUser _makeAuthUser(String id) => CrushUser(
  id: id,
  phoneNumber: '+10000000000',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  plan: SubscriptionPlan.free,
);

void main() {
  setupFirebaseAnalyticsMocks();

  // Clear singleton state between tests
  setUp(() {
    ProfileInsightsService.instance.clearUserData();
  });

  // ===========================================================================
  // PROFILE INSIGHTS STATE
  // ===========================================================================

  group('ProfileInsightsState', () {
    test('default state has correct initial values', () {
      const state = ProfileInsightsState();
      expect(state.insights, isNull);
      expect(state.photoPerformance, isEmpty);
      expect(state.isLoading, false);
      expect(state.isRefreshing, false);
      expect(state.errorMessage, isNull);
    });

    test('convenience getters return 0 when insights is null', () {
      const state = ProfileInsightsState();
      expect(state.profileViews, 0);
      expect(state.likesReceived, 0);
      expect(state.likesSent, 0);
      expect(state.superLikesReceived, 0);
      expect(state.matchRate, 0);
      expect(state.responseRate, 0);
      expect(state.averageResponseTime, isNull);
      expect(state.peakActivityHour, isNull);
      expect(state.weeklyTrend, isEmpty);
    });

    test('convenience getters reflect insights data', () {
      final now = DateTime.now();
      final state = ProfileInsightsState(
        insights: ProfileInsights(
          userId: 'user-1',
          periodStart: now.subtract(const Duration(days: 7)),
          periodEnd: now,
          profileViews: 50,
          likesReceived: 10,
          likesSent: 20,
          superLikesReceived: 2,
          matchRate: 0.25,
          responseRate: 0.80,
          averageResponseTime: const Duration(minutes: 15),
          peakActivityHour: 20,
        ),
      );
      expect(state.profileViews, 50);
      expect(state.likesReceived, 10);
      expect(state.likesSent, 20);
      expect(state.superLikesReceived, 2);
      expect(state.matchRate, 0.25);
      expect(state.responseRate, 0.80);
      expect(state.averageResponseTime, const Duration(minutes: 15));
      expect(state.peakActivityHour, 20);
    });

    test('copyWith preserves values when no overrides', () {
      const state = ProfileInsightsState(
        isLoading: true,
        isRefreshing: true,
        errorMessage: 'error',
      );
      final copied = state.copyWith();
      expect(copied.isLoading, true);
      expect(copied.isRefreshing, true);
      // errorMessage is NOT preserved by copyWith unless passed (it clears on null)
    });

    test('copyWith overrides specified values', () {
      const state = ProfileInsightsState();
      final modified = state.copyWith(
        isLoading: true,
        isRefreshing: true,
        errorMessage: 'error',
      );
      expect(modified.isLoading, true);
      expect(modified.isRefreshing, true);
      expect(modified.errorMessage, 'error');
    });

    test('copyWith clears errorMessage when set to null', () {
      const state = ProfileInsightsState(errorMessage: 'old error');
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });

    test('Equatable compares correctly', () {
      const a = ProfileInsightsState(isLoading: true);
      const b = ProfileInsightsState(isLoading: true);
      const c = ProfileInsightsState(isLoading: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ===========================================================================
  // PROFILE INSIGHTS CUBIT
  // ===========================================================================

  group('ProfileInsightsCubit', () {
    group('Initial State', () {
      test('starts with empty default state', () {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );
        expect(cubit.state.insights, isNull);
        expect(cubit.state.isLoading, false);
        expect(cubit.state.errorMessage, isNull);
        cubit.close();
      });
    });

    group('loadInsights', () {
      test('emits loading then loaded state with insights', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        final states = <ProfileInsightsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.loadInsights('user-1');
        // Service has 500ms delay, add buffer
        await Future<void>.delayed(const Duration(milliseconds: 700));

        // Should have emitted at least: loading=true, then loaded with insights
        expect(states.isNotEmpty, true);

        final loadingStates = states.where((s) => s.isLoading).toList();
        expect(
          loadingStates,
          isNotEmpty,
          reason: 'Should have a loading state',
        );

        final loadedStates = states
            .where((s) => !s.isLoading && s.insights != null)
            .toList();
        expect(
          loadedStates,
          isNotEmpty,
          reason: 'Should have a loaded state with insights',
        );

        final finalState = loadedStates.last;
        expect(finalState.insights!.userId, 'user-1');
        expect(finalState.insights!.profileViews, greaterThan(0));
        expect(finalState.photoPerformance, isNotEmpty);

        await sub.cancel();
        await cubit.close();
      });

      test('insights data has expected fields populated', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final insights = cubit.state.insights;
        expect(insights, isNotNull);
        expect(insights!.userId, 'user-1');
        expect(insights.periodStart, isNotNull);
        expect(insights.periodEnd, isNotNull);
        expect(insights.profileViews, greaterThanOrEqualTo(50));
        expect(insights.likesReceived, greaterThanOrEqualTo(10));
        expect(insights.likesSent, greaterThanOrEqualTo(15));
        expect(insights.matchRate, greaterThan(0));
        expect(insights.responseRate, greaterThan(0));
        expect(insights.averageResponseTime, isNotNull);
        expect(insights.peakActivityHour, isNotNull);
        expect(insights.weeklyTrend, isNotEmpty);

        await cubit.close();
      });
    });

    group('refreshInsights', () {
      test('emits refreshing then updated state', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        // Load first
        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final states = <ProfileInsightsState>[];
        final sub = cubit.stream.listen(states.add);

        // Refresh
        await cubit.refreshInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(states.isNotEmpty, true);

        final refreshingStates = states.where((s) => s.isRefreshing).toList();
        expect(
          refreshingStates,
          isNotEmpty,
          reason: 'Should have a refreshing state',
        );

        final refreshedStates = states
            .where((s) => !s.isRefreshing && s.insights != null)
            .toList();
        expect(
          refreshedStates,
          isNotEmpty,
          reason: 'Should have a refreshed state with insights',
        );

        await sub.cancel();
        await cubit.close();
      });
    });

    group('getInsightsForRange', () {
      test('loads insights for specific date range', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        final start = DateTime(2026, 1, 1);
        final end = DateTime(2026, 1, 31);

        final states = <ProfileInsightsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.getInsightsForRange(
          userId: 'user-1',
          start: start,
          end: end,
        );
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(states.isNotEmpty, true);

        final loadedStates = states
            .where((s) => !s.isLoading && s.insights != null)
            .toList();
        expect(loadedStates, isNotEmpty);

        final insights = loadedStates.last.insights!;
        expect(insights.periodStart, start);
        expect(insights.periodEnd, end);
        expect(insights.userId, 'user-1');

        await sub.cancel();
        await cubit.close();
      });
    });

    group('recordProfileView', () {
      test('increments profile views in current insights', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        // Load first
        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final viewsBefore = cubit.state.profileViews;

        await cubit.recordProfileView('viewer-1');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Profile views should be incremented by 1
        expect(cubit.state.profileViews, viewsBefore + 1);

        await cubit.close();
      });
    });

    group('recordLikeReceived', () {
      test('increments likes received', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final likesBefore = cubit.state.likesReceived;

        await cubit.recordLikeReceived();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state.likesReceived, likesBefore + 1);

        await cubit.close();
      });

      test('increments super likes when isSuperLike is true', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final superLikesBefore = cubit.state.superLikesReceived;

        await cubit.recordLikeReceived(isSuperLike: true);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state.superLikesReceived, superLikesBefore + 1);

        await cubit.close();
      });
    });

    group('recordLikeSent', () {
      test('increments likes sent', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final sentBefore = cubit.state.likesSent;

        await cubit.recordLikeSent();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state.likesSent, sentBefore + 1);

        await cubit.close();
      });
    });

    group('getBestTimeToBeActive', () {
      test('returns a non-empty string', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final bestTime = cubit.getBestTimeToBeActive();
        expect(bestTime, isNotEmpty);

        await cubit.close();
      });
    });

    group('Auth state changes (logout)', () {
      test('resets state when user logs out via auth stream', () async {
        final authController = StreamController<CrushUser?>.broadcast();
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(
            userStreamController: authController,
          ),
          insightsRepository: ProfileInsightsService.instance,
        );

        // Load insights
        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));
        expect(cubit.state.insights, isNotNull);

        final states = <ProfileInsightsState>[];
        final sub = cubit.stream.listen(states.add);

        // Simulate logout
        authController.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // State should be reset to initial
        final resetStates = states
            .where((s) => s.insights == null && !s.isLoading)
            .toList();
        expect(
          resetStates,
          isNotEmpty,
          reason: 'State should be reset after logout',
        );

        await sub.cancel();
        await authController.close();
        await cubit.close();
      });

      test('resets state when auth user switches accounts', () async {
        final authController = StreamController<CrushUser?>.broadcast();
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(
            userStreamController: authController,
          ),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));
        expect(cubit.state.insights, isNotNull);

        authController.add(_makeAuthUser('user-a'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cubit.state.insights, isNotNull);

        authController.add(_makeAuthUser('user-b'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state, const ProfileInsightsState());

        await authController.close();
        await cubit.close();
      });
    });

    group('Lifecycle', () {
      test('can close cleanly', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );
        await expectLater(cubit.close(), completes);
      });

      test('can close after loading insights', () async {
        final cubit = ProfileInsightsCubit(
          authRepository: _StubAuthRepository(),
          insightsRepository: ProfileInsightsService.instance,
        );

        await cubit.loadInsights('user-1');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        await expectLater(cubit.close(), completes);
      });
    });
  });

  // ===========================================================================
  // PROFILE INSIGHTS MODEL
  // ===========================================================================

  group('ProfileInsights model', () {
    final now = DateTime(2026, 2, 13);
    final weekAgo = DateTime(2026, 2, 6);

    test('matchRateDisplay formats correctly', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        matchRate: 0.253,
      );
      expect(insights.matchRateDisplay, '25.3%');
    });

    test('responseRateDisplay formats correctly', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        responseRate: 0.801,
      );
      expect(insights.responseRateDisplay, '80.1%');
    });

    test('avgResponseTimeDisplay handles null', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
      );
      expect(insights.avgResponseTimeDisplay, 'N/A');
    });

    test('avgResponseTimeDisplay formats minutes', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        averageResponseTime: const Duration(minutes: 45),
      );
      expect(insights.avgResponseTimeDisplay, '45m');
    });

    test('avgResponseTimeDisplay formats hours and minutes', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        averageResponseTime: const Duration(hours: 2, minutes: 30),
      );
      expect(insights.avgResponseTimeDisplay, '2h 30m');
    });

    test('peakTimeDisplay handles null', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
      );
      expect(insights.peakTimeDisplay, 'N/A');
    });

    test('peakTimeDisplay formats midnight', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        peakActivityHour: 0,
      );
      expect(insights.peakTimeDisplay, '12 AM');
    });

    test('peakTimeDisplay formats morning', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        peakActivityHour: 9,
      );
      expect(insights.peakTimeDisplay, '9 AM');
    });

    test('peakTimeDisplay formats noon', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        peakActivityHour: 12,
      );
      expect(insights.peakTimeDisplay, '12 PM');
    });

    test('peakTimeDisplay formats afternoon', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        peakActivityHour: 15,
      );
      expect(insights.peakTimeDisplay, '3 PM');
    });

    test('viewsChange returns 0 with insufficient data', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        weeklyTrend: const [],
      );
      expect(insights.viewsChange, 0);
    });

    test('viewsChange calculates correctly', () {
      final insights = ProfileInsights(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        weeklyTrend: [
          DailyMetric(date: DateTime(2026, 2, 11), views: 10),
          DailyMetric(date: DateTime(2026, 2, 12), views: 15),
        ],
      );
      expect(insights.viewsChange, 5);
    });

    test('toJson and fromJson round-trip', () {
      final original = ProfileInsightsDto(
        userId: 'u1',
        periodStart: weekAgo,
        periodEnd: now,
        profileViews: 100,
        likesReceived: 30,
        likesSent: 50,
        superLikesReceived: 3,
        matchRate: 0.25,
        responseRate: 0.80,
        averageResponseTime: const Duration(minutes: 15),
        peakActivityHour: 20,
        topPhotosViewed: const [0, 2],
        weeklyTrend: [
          DailyMetricDto(
            date: DateTime(2026, 2, 12),
            views: 10,
            likes: 5,
            matches: 1,
          ),
        ],
      );

      final json = original.toJson();
      final restored = ProfileInsightsDto.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.profileViews, original.profileViews);
      expect(restored.likesReceived, original.likesReceived);
      expect(restored.likesSent, original.likesSent);
      expect(restored.superLikesReceived, original.superLikesReceived);
      expect(restored.matchRate, original.matchRate);
      expect(restored.responseRate, original.responseRate);
      expect(restored.averageResponseTime, original.averageResponseTime);
      expect(restored.peakActivityHour, original.peakActivityHour);
      expect(restored.topPhotosViewed, original.topPhotosViewed);
      expect(restored.weeklyTrend.length, original.weeklyTrend.length);
    });

    test('fromJson handles missing fields with defaults', () {
      final insights = ProfileInsightsDto.fromJson(const {
        'userId': 'u1',
        'periodStart': '2026-02-06T00:00:00.000',
        'periodEnd': '2026-02-13T00:00:00.000',
      });
      expect(insights.profileViews, 0);
      expect(insights.likesReceived, 0);
      expect(insights.matchRate, 0.0);
      expect(insights.averageResponseTime, isNull);
      expect(insights.peakActivityHour, isNull);
      expect(insights.topPhotosViewed, isEmpty);
      expect(insights.weeklyTrend, isEmpty);
    });
  });

  // ===========================================================================
  // DAILY METRIC MODEL
  // ===========================================================================

  group('DailyMetric', () {
    test('default values', () {
      final metric = DailyMetric(date: DateTime(2026, 2, 13));
      expect(metric.views, 0);
      expect(metric.likes, 0);
      expect(metric.matches, 0);
    });

    test('toJson and fromJson round-trip', () {
      final original = DailyMetricDto(
        date: DateTime(2026, 2, 13),
        views: 10,
        likes: 5,
        matches: 2,
      );
      final json = original.toJson();
      final restored = DailyMetricDto.fromJson(json);
      expect(restored, equals(original));
    });
  });

  // ===========================================================================
  // DEMOGRAPHIC BREAKDOWN MODEL
  // ===========================================================================

  group('DemographicBreakdown', () {
    test('default values', () {
      const breakdown = DemographicBreakdown();
      expect(breakdown.ageRanges, isEmpty);
      expect(breakdown.topLocations, isEmpty);
      expect(breakdown.genderSplit, isEmpty);
    });

    test('toJson and fromJson round-trip', () {
      const original = DemographicBreakdownDto(
        ageRanges: {'18-24': 30, '25-34': 50},
        topLocations: ['NYC', 'LA'],
        genderSplit: {'Men': 60, 'Women': 40},
      );
      final json = original.toJson();
      final restored = DemographicBreakdownDto.fromJson(json);
      expect(restored, equals(original));
    });
  });
}

// =============================================================================
// Stub Repository
// =============================================================================

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
  Future<CrushUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();

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
  Future<CrushUser> acceptTermsAndConditions() => throw UnimplementedError();

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
