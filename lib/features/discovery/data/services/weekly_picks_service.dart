import 'dart:async';
import 'dart:math';
import '../models/weekly_picks.dart';

/// Service for managing weekly curated picks.
import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';

class WeeklyPicksService implements WeeklyPicksRepository {
  WeeklyPicksService._();
  static final WeeklyPicksService instance = WeeklyPicksService._();

  final _picksController = StreamController<WeeklyPicks>.broadcast();
  @override
  Stream<WeeklyPicks> get picksStream => _picksController.stream;

  WeeklyPicks? _currentPicks;

  @override
  WeeklyPicks? get currentPicks => _currentPicks;
  @override
  bool get hasUnseenPicks => (_currentPicks?.unseenCount ?? 0) > 0;
  @override
  int get unseenCount => _currentPicks?.unseenCount ?? 0;

  /// Load weekly picks for user.
  @override
  Future<WeeklyPicks> loadPicks(String userId) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    // Calculate week start (Monday) and end (Sunday)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    _currentPicks = WeeklyPicks(
      userId: userId,
      weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
      weekEnd: DateTime(weekEnd.year, weekEnd.month, weekEnd.day),
      picks: _generateDemoPicks(),
      refreshedAt: now,
    );

    _picksController.add(_currentPicks!);

    // Schedule refresh for next week
    _scheduleRefresh();

    return _currentPicks!;
  }

  /// Mark a pick as viewed.
  @override
  Future<void> markPickViewed(String pickId) async {
    if (_currentPicks == null) return;

    _currentPicks = _currentPicks!.markViewed(pickId);
    _picksController.add(_currentPicks!);
  }

  /// Mark a pick as liked (also marks as viewed).
  @override
  Future<void> markPickLiked(String pickId) async {
    if (_currentPicks == null) return;

    _currentPicks = _currentPicks!.markLiked(pickId);
    _picksController.add(_currentPicks!);
  }

  /// Check if a pick has been viewed.
  @override
  bool isPickViewed(String pickId) {
    return _currentPicks?.viewedPicks.contains(pickId) ?? false;
  }

  /// Check if a pick has been liked.
  @override
  bool isPickLiked(String pickId) {
    return _currentPicks?.likedPicks.contains(pickId) ?? false;
  }

  /// Get unviewed picks.
  @override
  List<WeeklyPick> getUnviewedPicks() {
    if (_currentPicks == null) return [];
    return _currentPicks!.picks
        .where((p) => !_currentPicks!.viewedPicks.contains(p.id))
        .toList();
  }

  /// Get all picks.
  @override
  List<WeeklyPick> getAllPicks() {
    return _currentPicks?.picks ?? [];
  }

  /// Get time until next refresh.
  @override
  Duration getTimeUntilRefresh() {
    return _currentPicks?.timeUntilNewPicks ?? Duration.zero;
  }

  /// Get formatted time until new picks.
  @override
  String getNewPicksTimeDisplay() {
    return _currentPicks?.newPicksTimeDisplay ?? 'Loading...';
  }

  /// Check if picks are current.
  @override
  bool get isCurrentWeek => _currentPicks?.isCurrentWeek ?? false;

  void _scheduleRefresh() {
    final delay = _currentPicks?.timeUntilNewPicks ?? Duration.zero;
    if (delay.isNegative || delay == Duration.zero) return;

    Future.delayed(delay, () {
      if (_currentPicks?.userId != null) {
        loadPicks(_currentPicks!.userId);
      }
    });
  }

  List<WeeklyPick> _generateDemoPicks() {
    const reasons = PickReason.values;

    return List.generate(WeeklyPicks.maxPicks, (index) {
      return WeeklyPick(
        id: 'pick_$index',
        profileId: 'user_${Random().nextInt(1000)}',
        reason: reasons[index % reasons.length],
        matchScore: 60 + Random().nextInt(35),
        commonInterests: _getRandomInterests(),
      );
    });
  }

  List<String> _getRandomInterests() {
    final allInterests = [
      'Travel',
      'Photography',
      'Music',
      'Cooking',
      'Hiking',
      'Reading',
      'Movies',
      'Fitness',
      'Art',
      'Gaming',
    ];

    allInterests.shuffle();
    return allInterests.take(Random().nextInt(3) + 2).toList();
  }

  @override
  void clearUserData() {
    _currentPicks = null;
  }

  @override
  void dispose() {
    _picksController.close();
  }
}
