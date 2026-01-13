import 'package:equatable/equatable.dart';

/// Tracks daily likes usage for free tier users.
class DailyLikesLimit extends Equatable {
  const DailyLikesLimit({
    required this.userId,
    required this.date,
    this.likesUsed = 0,
    this.superLikesUsed = 0,
    this.isPremium = false,
    this.bonusLikes = 0,
  });

  /// User ID.
  final String userId;

  /// The date this limit applies to.
  final DateTime date;

  /// Number of likes used today.
  final int likesUsed;

  /// Number of super likes used today.
  final int superLikesUsed;

  /// Whether user has premium (unlimited likes).
  final bool isPremium;

  /// Bonus likes from promotions or rewards.
  final int bonusLikes;

  /// Maximum daily likes for free users.
  static const int maxFreeLikes = 50;

  /// Maximum daily super likes for free users.
  static const int maxFreeSuperLikes = 1;

  /// Maximum daily super likes for premium users.
  static const int maxPremiumSuperLikes = 5;

  /// Get total available likes.
  int get totalAvailableLikes => isPremium ? 999999 : maxFreeLikes + bonusLikes;

  /// Get remaining likes.
  int get remainingLikes {
    if (isPremium) return 999999;
    return (maxFreeLikes + bonusLikes - likesUsed).clamp(0, maxFreeLikes + bonusLikes);
  }

  /// Get remaining super likes.
  int get remainingSuperLikes {
    final max = isPremium ? maxPremiumSuperLikes : maxFreeSuperLikes;
    return (max - superLikesUsed).clamp(0, max);
  }

  /// Check if user can like.
  bool get canLike => isPremium || likesUsed < (maxFreeLikes + bonusLikes);

  /// Check if user can super like.
  bool get canSuperLike {
    final max = isPremium ? maxPremiumSuperLikes : maxFreeSuperLikes;
    return superLikesUsed < max;
  }

  /// Get percentage of likes used.
  double get usagePercentage {
    if (isPremium) return 0.0;
    return likesUsed / (maxFreeLikes + bonusLikes);
  }

  /// Get time until likes reset (midnight).
  Duration get timeUntilReset {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Get formatted reset time.
  String get resetTimeDisplay {
    final remaining = timeUntilReset;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return 'Resets in ${hours}h ${minutes}m';
    } else {
      return 'Resets in ${minutes}m';
    }
  }

  DailyLikesLimit copyWith({
    String? userId,
    DateTime? date,
    int? likesUsed,
    int? superLikesUsed,
    bool? isPremium,
    int? bonusLikes,
  }) {
    return DailyLikesLimit(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      likesUsed: likesUsed ?? this.likesUsed,
      superLikesUsed: superLikesUsed ?? this.superLikesUsed,
      isPremium: isPremium ?? this.isPremium,
      bonusLikes: bonusLikes ?? this.bonusLikes,
    );
  }

  /// Increment likes used.
  DailyLikesLimit useLike() {
    return copyWith(likesUsed: likesUsed + 1);
  }

  /// Increment super likes used.
  DailyLikesLimit useSuperLike() {
    return copyWith(superLikesUsed: superLikesUsed + 1);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'likesUsed': likesUsed,
      'superLikesUsed': superLikesUsed,
      'isPremium': isPremium,
      'bonusLikes': bonusLikes,
    };
  }

  factory DailyLikesLimit.fromJson(Map<String, dynamic> json) {
    return DailyLikesLimit(
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      likesUsed: json['likesUsed'] as int? ?? 0,
      superLikesUsed: json['superLikesUsed'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      bonusLikes: json['bonusLikes'] as int? ?? 0,
    );
  }

  /// Create a fresh limit for today.
  factory DailyLikesLimit.forToday({
    required String userId,
    bool isPremium = false,
    int bonusLikes = 0,
  }) {
    final now = DateTime.now();
    return DailyLikesLimit(
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      isPremium: isPremium,
      bonusLikes: bonusLikes,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        date,
        likesUsed,
        superLikesUsed,
        isPremium,
        bonusLikes,
      ];
}
