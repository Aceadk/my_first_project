import 'dart:async';
import '../models/daily_likes_limit.dart';

/// Service for managing daily likes limit.
class DailyLikesService {
  DailyLikesService._({
    Future<void> Function(Duration)? delayExecutor,
    Timer Function(Duration, void Function())? resetScheduler,
  }) : _delayExecutor = delayExecutor ?? Future.delayed,
       _resetScheduler =
           resetScheduler ?? ((delay, callback) => Timer(delay, callback));
  static final DailyLikesService instance = DailyLikesService._();

  factory DailyLikesService.test({
    Future<void> Function(Duration)? delayExecutor,
    Timer Function(Duration, void Function())? resetScheduler,
  }) {
    return DailyLikesService._(
      delayExecutor: delayExecutor,
      resetScheduler: resetScheduler,
    );
  }

  final Future<void> Function(Duration) _delayExecutor;
  final Timer Function(Duration, void Function()) _resetScheduler;
  final _limitController = StreamController<DailyLikesLimit>.broadcast();
  Stream<DailyLikesLimit> get limitStream => _limitController.stream;

  DailyLikesLimit? _currentLimit;
  Timer? _resetTimer;

  DailyLikesLimit? get currentLimit => _currentLimit;
  bool get canLike => _currentLimit?.canLike ?? false;
  bool get canSuperLike => _currentLimit?.canSuperLike ?? false;
  int get remainingLikes => _currentLimit?.remainingLikes ?? 0;
  int get remainingSuperLikes => _currentLimit?.remainingSuperLikes ?? 0;

  /// Load likes limit for user.
  Future<DailyLikesLimit> loadLimit({
    required String userId,
    bool isPremium = false,
    int bonusLikes = 0,
  }) async {
    // In production, fetch from backend
    await _delayExecutor(const Duration(milliseconds: 300));

    _currentLimit = DailyLikesLimit.forToday(
      userId: userId,
      isPremium: isPremium,
      bonusLikes: bonusLikes,
    );

    _limitController.add(_currentLimit!);

    // Schedule reset at midnight
    _scheduleReset();

    return _currentLimit!;
  }

  /// Use a like.
  Future<LikeResult> useLike() async {
    if (_currentLimit == null) {
      return const LikeResult(
        success: false,
        remainingLikes: 0,
        message: 'Likes not loaded. Please try again.',
      );
    }

    if (!_currentLimit!.canLike) {
      return LikeResult(
        success: false,
        remainingLikes: 0,
        message: 'No likes remaining. Upgrade to Premium for unlimited likes!',
        timeUntilReset: _currentLimit!.timeUntilReset,
      );
    }

    _currentLimit = _currentLimit!.useLike();
    _limitController.add(_currentLimit!);

    // In production, sync with backend
    await _syncUsage();

    final remaining = _currentLimit!.remainingLikes;
    return LikeResult(
      success: true,
      remainingLikes: remaining,
      message: remaining <= 5 ? 'Only $remaining likes left today!' : null,
    );
  }

  /// Use a super like.
  Future<LikeResult> useSuperLike() async {
    if (_currentLimit == null) {
      return const LikeResult(
        success: false,
        remainingLikes: 0,
        message: 'Likes not loaded. Please try again.',
      );
    }

    if (!_currentLimit!.canSuperLike) {
      return LikeResult(
        success: false,
        remainingLikes: 0,
        message: 'No Super Likes remaining. Get more with Premium!',
        timeUntilReset: _currentLimit!.timeUntilReset,
      );
    }

    _currentLimit = _currentLimit!.useSuperLike();
    _limitController.add(_currentLimit!);
    await _syncUsage();

    return LikeResult(
      success: true,
      remainingLikes: _currentLimit!.remainingSuperLikes,
      isSuperLike: true,
    );
  }

  /// Upgrade to premium (unlimited likes).
  Future<void> upgradeToPremium() async {
    if (_currentLimit == null) return;

    _currentLimit = _currentLimit!.copyWith(isPremium: true);
    _limitController.add(_currentLimit!);
  }

  /// Add bonus likes (from promotions, etc.).
  Future<void> addBonusLikes(int count) async {
    if (_currentLimit == null) return;

    _currentLimit = _currentLimit!.copyWith(
      bonusLikes: _currentLimit!.bonusLikes + count,
    );
    _limitController.add(_currentLimit!);
  }

  /// Reset daily limits (called at midnight or manually for testing).
  Future<void> resetLimits() async {
    if (_currentLimit == null) return;

    _currentLimit = DailyLikesLimit.forToday(
      userId: _currentLimit!.userId,
      isPremium: _currentLimit!.isPremium,
      bonusLikes: 0, // Bonus likes don't carry over
    );

    _limitController.add(_currentLimit!);
    _scheduleReset();
  }

  /// Get time until reset.
  Duration getTimeUntilReset() {
    return _currentLimit?.timeUntilReset ?? Duration.zero;
  }

  /// Get usage percentage.
  double getUsagePercentage() {
    return _currentLimit?.usagePercentage ?? 0.0;
  }

  /// Get formatted reset time display.
  String getResetTimeDisplay() {
    return _currentLimit?.resetTimeDisplay ?? 'Unknown';
  }

  void _scheduleReset() {
    final delay = _currentLimit?.timeUntilReset ?? Duration.zero;
    _resetTimer?.cancel();
    if (delay.isNegative || delay == Duration.zero) {
      return;
    }

    _resetTimer = _resetScheduler(delay, () {
      resetLimits();
    });
  }

  Future<void> _syncUsage() async {
    // In production, sync with backend
  }

  void dispose() {
    _resetTimer?.cancel();
    _limitController.close();
  }
}

/// Result of attempting to use a like.
class LikeResult {
  const LikeResult({
    required this.success,
    required this.remainingLikes,
    this.message,
    this.timeUntilReset,
    this.isSuperLike = false,
  });

  final bool success;
  final int remainingLikes;
  final String? message;
  final Duration? timeUntilReset;
  final bool isSuperLike;
}
