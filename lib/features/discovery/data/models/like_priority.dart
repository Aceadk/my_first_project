import 'package:equatable/equatable.dart';

/// Priority like system - premium users' likes are shown first to recipients.
class LikePriority extends Equatable {
  const LikePriority({
    required this.likeId,
    required this.fromUserId,
    required this.toUserId,
    required this.priority,
    required this.createdAt,
    this.boosted = false,
    this.superLike = false,
    this.expiresAt,
  });

  /// The like's unique ID.
  final String likeId;

  /// User who sent the like.
  final String fromUserId;

  /// User who received the like.
  final String toUserId;

  /// Priority level (higher = shown first).
  final LikePriorityLevel priority;

  /// When the like was sent.
  final DateTime createdAt;

  /// Whether this like was sent during an active boost.
  final bool boosted;

  /// Whether this is a super like.
  final bool superLike;

  /// When the priority boost expires (for time-limited boosts).
  final DateTime? expiresAt;

  /// Calculate display order score (higher = shown first).
  int get displayScore {
    int score = priority.baseScore;

    // Add bonus for super likes
    if (superLike) score += 500;

    // Add bonus for boosted likes
    if (boosted) score += 200;

    // Recency bonus (likes within last hour get extra priority)
    final hoursSinceLike = DateTime.now().difference(createdAt).inHours;
    if (hoursSinceLike < 1) {
      score += 100;
    } else if (hoursSinceLike < 24) {
      score += 50;
    }

    return score;
  }

  /// Check if priority is still active.
  bool get isActive {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  LikePriority copyWith({
    String? likeId,
    String? fromUserId,
    String? toUserId,
    LikePriorityLevel? priority,
    DateTime? createdAt,
    bool? boosted,
    bool? superLike,
    DateTime? expiresAt,
  }) {
    return LikePriority(
      likeId: likeId ?? this.likeId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      boosted: boosted ?? this.boosted,
      superLike: superLike ?? this.superLike,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'likeId': likeId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'boosted': boosted,
      'superLike': superLike,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory LikePriority.fromJson(Map<String, dynamic> json) {
    return LikePriority(
      likeId: json['likeId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      priority: LikePriorityLevel.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => LikePriorityLevel.standard,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      boosted: json['boosted'] as bool? ?? false,
      superLike: json['superLike'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        likeId,
        fromUserId,
        toUserId,
        priority,
        createdAt,
        boosted,
        superLike,
        expiresAt,
      ];
}

/// Priority levels for likes.
enum LikePriorityLevel {
  standard, // Free users
  premium, // Premium subscribers
  platinum, // Platinum subscribers
  spotlight, // Spotlight/featured (special promotion)
}

extension LikePriorityLevelExtension on LikePriorityLevel {
  int get baseScore {
    switch (this) {
      case LikePriorityLevel.standard:
        return 100;
      case LikePriorityLevel.premium:
        return 300;
      case LikePriorityLevel.platinum:
        return 500;
      case LikePriorityLevel.spotlight:
        return 1000;
    }
  }

  String get displayName {
    switch (this) {
      case LikePriorityLevel.standard:
        return 'Standard';
      case LikePriorityLevel.premium:
        return 'Priority';
      case LikePriorityLevel.platinum:
        return 'Top Priority';
      case LikePriorityLevel.spotlight:
        return 'Spotlight';
    }
  }

  String get description {
    switch (this) {
      case LikePriorityLevel.standard:
        return 'Your like will be shown in the regular queue';
      case LikePriorityLevel.premium:
        return 'Your like will be shown before standard likes';
      case LikePriorityLevel.platinum:
        return 'Your like will be shown at the top of their queue';
      case LikePriorityLevel.spotlight:
        return 'Your like will be featured prominently';
    }
  }
}
