import 'dart:async';
import 'dart:math';

import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:crushhour/features/analytics/domain/repositories/profile_insights_repository.dart';

/// Service for managing profile insights and analytics.
class ProfileInsightsService implements ProfileInsightsRepository {
  ProfileInsightsService._();
  static final ProfileInsightsService instance = ProfileInsightsService._();

  final _insightsController = StreamController<ProfileInsights>.broadcast();
  @override
  Stream<ProfileInsights> get insightsStream => _insightsController.stream;

  ProfileInsights? _currentInsights;

  @override
  ProfileInsights? get currentInsights => _currentInsights;

  /// Load insights for user.
  @override
  Future<ProfileInsights> loadInsights(String userId) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Generate demo data
    _currentInsights = ProfileInsights(
      userId: userId,
      periodStart: weekAgo,
      periodEnd: now,
      profileViews: Random().nextInt(100) + 50,
      likesReceived: Random().nextInt(30) + 10,
      likesSent: Random().nextInt(40) + 15,
      superLikesReceived: Random().nextInt(5),
      matchRate: 0.15 + (Random().nextDouble() * 0.25),
      responseRate: 0.60 + (Random().nextDouble() * 0.30),
      averageResponseTime: Duration(minutes: Random().nextInt(60) + 5),
      peakActivityHour: Random().nextInt(24),
      topPhotosViewed: [0, 1, 2].take(Random().nextInt(3) + 1).toList(),
      demographicBreakdown: _generateDemographics(),
      weeklyTrend: _generateWeeklyTrend(weekAgo),
    );

    _insightsController.add(_currentInsights!);
    return _currentInsights!;
  }

  /// Refresh insights.
  @override
  Future<ProfileInsights> refreshInsights(String userId) async {
    return loadInsights(userId);
  }

  /// Get insights for a specific date range.
  @override
  Future<ProfileInsights> getInsightsForRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    _currentInsights = ProfileInsights(
      userId: userId,
      periodStart: start,
      periodEnd: end,
      profileViews: Random().nextInt(100) + 50,
      likesReceived: Random().nextInt(30) + 10,
      likesSent: Random().nextInt(40) + 15,
      superLikesReceived: Random().nextInt(5),
      matchRate: 0.15 + (Random().nextDouble() * 0.25),
      responseRate: 0.60 + (Random().nextDouble() * 0.30),
      averageResponseTime: Duration(minutes: Random().nextInt(60) + 5),
      peakActivityHour: Random().nextInt(24),
      topPhotosViewed: [0, 1, 2].take(Random().nextInt(3) + 1).toList(),
      demographicBreakdown: _generateDemographics(),
      weeklyTrend: _generateWeeklyTrend(start),
    );

    _insightsController.add(_currentInsights!);
    return _currentInsights!;
  }

  /// Record a profile view.
  @override
  Future<void> recordProfileView(String viewerUserId) async {
    if (_currentInsights == null) return;

    _currentInsights = _currentInsights!.copyWith(
      profileViews: _currentInsights!.profileViews + 1,
    );

    _insightsController.add(_currentInsights!);
    // In production, sync with backend
  }

  /// Record a like received.
  @override
  Future<void> recordLikeReceived({bool isSuperLike = false}) async {
    if (_currentInsights == null) return;

    _currentInsights = _currentInsights!.copyWith(
      likesReceived: _currentInsights!.likesReceived + 1,
      superLikesReceived: isSuperLike
          ? _currentInsights!.superLikesReceived + 1
          : _currentInsights!.superLikesReceived,
    );

    _insightsController.add(_currentInsights!);
  }

  /// Record a like sent.
  @override
  Future<void> recordLikeSent() async {
    if (_currentInsights == null) return;

    _currentInsights = _currentInsights!.copyWith(
      likesSent: _currentInsights!.likesSent + 1,
    );

    _insightsController.add(_currentInsights!);
  }

  /// Get photo performance ranking.
  @override
  List<PhotoPerformance> getPhotoPerformance() {
    if (_currentInsights == null) return [];

    // In production, fetch actual photo performance data
    return List.generate(6, (index) {
      return PhotoPerformance(
        photoIndex: index,
        views: Random().nextInt(100) + 20,
        likes: Random().nextInt(30) + 5,
        likeRate: 0.1 + (Random().nextDouble() * 0.3),
      );
    })..sort((a, b) => b.likeRate.compareTo(a.likeRate));
  }

  /// Get best time to be active.
  @override
  String getBestTimeToBeActive() {
    if (_currentInsights?.peakActivityHour == null) return 'Evening';

    final hour = _currentInsights!.peakActivityHour!;
    if (hour >= 6 && hour < 12) return 'Morning (6 AM - 12 PM)';
    if (hour >= 12 && hour < 17) return 'Afternoon (12 PM - 5 PM)';
    if (hour >= 17 && hour < 21) return 'Evening (5 PM - 9 PM)';
    return 'Night (9 PM - 6 AM)';
  }

  DemographicBreakdown _generateDemographics() {
    return const DemographicBreakdown(
      ageRanges: {'18-24': 25, '25-34': 45, '35-44': 20, '45+': 10},
      topLocations: ['New York', 'Los Angeles', 'Chicago'],
      genderSplit: {'Men': 60, 'Women': 35, 'Other': 5},
    );
  }

  List<DailyMetric> _generateWeeklyTrend(DateTime start) {
    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      return DailyMetric(
        date: date,
        views: Random().nextInt(20) + 5,
        likes: Random().nextInt(10) + 1,
        matches: Random().nextInt(3),
      );
    });
  }

  @override
  void clearUserData() {
    _currentInsights = null;
  }

  @override
  void dispose() {
    _insightsController.close();
  }
}
