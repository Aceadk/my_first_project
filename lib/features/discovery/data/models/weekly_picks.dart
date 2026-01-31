import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/profile.dart';

/// Weekly curated picks for a user.
class WeeklyPicks extends Equatable {
  const WeeklyPicks({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.picks,
    this.viewedPicks = const [],
    this.likedPicks = const [],
    this.refreshedAt,
  });

  /// User ID these picks are for.
  final String userId;

  /// Start of the week these picks are valid for.
  final DateTime weekStart;

  /// End of the week.
  final DateTime weekEnd;

  /// The curated profile picks.
  final List<WeeklyPick> picks;

  /// IDs of picks that have been viewed.
  final List<String> viewedPicks;

  /// IDs of picks that have been liked.
  final List<String> likedPicks;

  /// When picks were last refreshed.
  final DateTime? refreshedAt;

  /// Maximum picks per week.
  static const int maxPicks = 10;

  /// Check if picks are still valid for this week.
  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(weekStart) && now.isBefore(weekEnd);
  }

  /// Get number of unseen picks.
  int get unseenCount => picks.length - viewedPicks.length;

  /// Check if all picks have been viewed.
  bool get allViewed => viewedPicks.length >= picks.length;

  /// Get time until new picks.
  Duration get timeUntilNewPicks => weekEnd.difference(DateTime.now());

  /// Get formatted time until new picks.
  String get newPicksTimeDisplay {
    final remaining = timeUntilNewPicks;
    if (remaining.isNegative) return 'New picks available!';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) {
      return 'New picks in ${days}d ${hours}h';
    } else {
      return 'New picks in ${hours}h';
    }
  }

  WeeklyPicks copyWith({
    String? userId,
    DateTime? weekStart,
    DateTime? weekEnd,
    List<WeeklyPick>? picks,
    List<String>? viewedPicks,
    List<String>? likedPicks,
    DateTime? refreshedAt,
  }) {
    return WeeklyPicks(
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      picks: picks ?? this.picks,
      viewedPicks: viewedPicks ?? this.viewedPicks,
      likedPicks: likedPicks ?? this.likedPicks,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }

  /// Mark a pick as viewed.
  WeeklyPicks markViewed(String pickId) {
    if (viewedPicks.contains(pickId)) return this;
    return copyWith(viewedPicks: [...viewedPicks, pickId]);
  }

  /// Mark a pick as liked.
  WeeklyPicks markLiked(String pickId) {
    if (likedPicks.contains(pickId)) return this;
    return copyWith(
      likedPicks: [...likedPicks, pickId],
      viewedPicks:
          viewedPicks.contains(pickId) ? viewedPicks : [...viewedPicks, pickId],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'picks': picks.map((p) => p.toJson()).toList(),
      'viewedPicks': viewedPicks,
      'likedPicks': likedPicks,
      'refreshedAt': refreshedAt?.toIso8601String(),
    };
  }

  factory WeeklyPicks.fromJson(Map<String, dynamic> json) {
    return WeeklyPicks(
      userId: json['userId'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      picks: (json['picks'] as List<dynamic>)
          .map((e) => WeeklyPick.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewedPicks: (json['viewedPicks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      likedPicks: (json['likedPicks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      refreshedAt: json['refreshedAt'] != null
          ? DateTime.parse(json['refreshedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        weekStart,
        weekEnd,
        picks,
        viewedPicks,
        likedPicks,
        refreshedAt,
      ];
}

/// A single weekly pick with reason for recommendation.
class WeeklyPick extends Equatable {
  const WeeklyPick({
    required this.id,
    required this.profileId,
    required this.reason,
    this.profile,
    this.matchScore,
    this.commonInterests = const [],
    this.highlightedPromptIndex,
  });

  /// Unique pick ID.
  final String id;

  /// Profile ID of the pick.
  final String profileId;

  /// Reason this person was picked.
  final PickReason reason;

  /// The full profile (loaded separately).
  final Profile? profile;

  /// Compatibility match score (0-100).
  final int? matchScore;

  /// Common interests with the user.
  final List<String> commonInterests;

  /// Index of a prompt to highlight.
  final int? highlightedPromptIndex;

  /// Get display text for the reason.
  String get reasonDisplay => reason.displayText;

  WeeklyPick copyWith({
    String? id,
    String? profileId,
    PickReason? reason,
    Profile? profile,
    int? matchScore,
    List<String>? commonInterests,
    int? highlightedPromptIndex,
  }) {
    return WeeklyPick(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      reason: reason ?? this.reason,
      profile: profile ?? this.profile,
      matchScore: matchScore ?? this.matchScore,
      commonInterests: commonInterests ?? this.commonInterests,
      highlightedPromptIndex:
          highlightedPromptIndex ?? this.highlightedPromptIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'reason': reason.name,
      'matchScore': matchScore,
      'commonInterests': commonInterests,
      'highlightedPromptIndex': highlightedPromptIndex,
    };
  }

  factory WeeklyPick.fromJson(Map<String, dynamic> json) {
    return WeeklyPick(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      reason: PickReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => PickReason.topPick,
      ),
      matchScore: json['matchScore'] as int?,
      commonInterests: (json['commonInterests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      highlightedPromptIndex: json['highlightedPromptIndex'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        reason,
        profile,
        matchScore,
        commonInterests,
        highlightedPromptIndex,
      ];
}

/// Reasons for recommending a weekly pick.
enum PickReason {
  topPick,
  sharedInterests,
  nearbyLocation,
  highCompatibility,
  newToArea,
  popularProfile,
  similarLifestyle,
  educationMatch,
  relationshipGoalsMatch,
}

extension PickReasonExtension on PickReason {
  String get displayText {
    switch (this) {
      case PickReason.topPick:
        return 'Top Pick for You';
      case PickReason.sharedInterests:
        return 'Shared Interests';
      case PickReason.nearbyLocation:
        return 'Lives Nearby';
      case PickReason.highCompatibility:
        return 'High Compatibility';
      case PickReason.newToArea:
        return 'New to Your Area';
      case PickReason.popularProfile:
        return 'Popular Profile';
      case PickReason.similarLifestyle:
        return 'Similar Lifestyle';
      case PickReason.educationMatch:
        return 'Education Match';
      case PickReason.relationshipGoalsMatch:
        return 'Same Relationship Goals';
    }
  }

  String get emoji {
    switch (this) {
      case PickReason.topPick:
        return '⭐';
      case PickReason.sharedInterests:
        return '🎯';
      case PickReason.nearbyLocation:
        return '📍';
      case PickReason.highCompatibility:
        return '💫';
      case PickReason.newToArea:
        return '🆕';
      case PickReason.popularProfile:
        return '🔥';
      case PickReason.similarLifestyle:
        return '🏃';
      case PickReason.educationMatch:
        return '🎓';
      case PickReason.relationshipGoalsMatch:
        return '💕';
    }
  }
}
