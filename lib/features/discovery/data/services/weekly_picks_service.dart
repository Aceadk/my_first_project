import 'dart:async';
import 'dart:math';
import '../models/weekly_picks.dart';

/// Service for managing weekly curated picks.
class WeeklyPicksService {
  WeeklyPicksService._();
  static final WeeklyPicksService instance = WeeklyPicksService._();

  final _picksController = StreamController<WeeklyPicks>.broadcast();
  Stream<WeeklyPicks> get picksStream => _picksController.stream;

  WeeklyPicks? _currentPicks;

  WeeklyPicks? get currentPicks => _currentPicks;
  bool get hasUnseenPicks => (_currentPicks?.unseenCount ?? 0) > 0;
  int get unseenCount => _currentPicks?.unseenCount ?? 0;

  /// Load weekly picks for user.
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
  Future<void> markPickViewed(String pickId) async {
    if (_currentPicks == null) return;

    _currentPicks = _currentPicks!.markViewed(pickId);
    _picksController.add(_currentPicks!);
  }

  /// Mark a pick as liked (also marks as viewed).
  Future<void> markPickLiked(String pickId) async {
    if (_currentPicks == null) return;

    _currentPicks = _currentPicks!.markLiked(pickId);
    _picksController.add(_currentPicks!);
  }

  /// Check if a pick has been viewed.
  bool isPickViewed(String pickId) {
    return _currentPicks?.viewedPicks.contains(pickId) ?? false;
  }

  /// Check if a pick has been liked.
  bool isPickLiked(String pickId) {
    return _currentPicks?.likedPicks.contains(pickId) ?? false;
  }

  /// Get unviewed picks.
  List<WeeklyPick> getUnviewedPicks() {
    if (_currentPicks == null) return [];
    return _currentPicks!.picks
        .where((p) => !_currentPicks!.viewedPicks.contains(p.id))
        .toList();
  }

  /// Get all picks.
  List<WeeklyPick> getAllPicks() {
    return _currentPicks?.picks ?? [];
  }

  /// Get time until next refresh.
  Duration getTimeUntilRefresh() {
    return _currentPicks?.timeUntilNewPicks ?? Duration.zero;
  }

  /// Get formatted time until new picks.
  String getNewPicksTimeDisplay() {
    return _currentPicks?.newPicksTimeDisplay ?? 'Loading...';
  }

  /// Check if picks are current.
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

  void clearUserData() {
    _currentPicks = null;
  }

  void dispose() {
    _picksController.close();
  }
}
