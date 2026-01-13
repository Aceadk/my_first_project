import 'package:equatable/equatable.dart';

/// Profile insights and analytics for users to understand their performance.
class ProfileInsights extends Equatable {
  const ProfileInsights({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    this.profileViews = 0,
    this.likesReceived = 0,
    this.likesSent = 0,
    this.superLikesReceived = 0,
    this.matchRate = 0.0,
    this.responseRate = 0.0,
    this.averageResponseTime,
    this.peakActivityHour,
    this.topPhotosViewed = const [],
    this.demographicBreakdown,
    this.weeklyTrend = const [],
  });

  /// User ID these insights belong to.
  final String userId;

  /// Start of the analytics period.
  final DateTime periodStart;

  /// End of the analytics period.
  final DateTime periodEnd;

  /// Number of profile views in the period.
  final int profileViews;

  /// Number of likes received.
  final int likesReceived;

  /// Number of likes sent.
  final int likesSent;

  /// Number of super likes received.
  final int superLikesReceived;

  /// Match rate (matches / likes received).
  final double matchRate;

  /// Response rate in conversations.
  final double responseRate;

  /// Average time to respond to messages.
  final Duration? averageResponseTime;

  /// Hour of day with most activity (0-23).
  final int? peakActivityHour;

  /// Indices of photos that got the most views/engagement.
  final List<int> topPhotosViewed;

  /// Breakdown of who's viewing the profile.
  final DemographicBreakdown? demographicBreakdown;

  /// Daily metrics for the week.
  final List<DailyMetric> weeklyTrend;

  /// Get formatted match rate.
  String get matchRateDisplay => '${(matchRate * 100).toStringAsFixed(1)}%';

  /// Get formatted response rate.
  String get responseRateDisplay => '${(responseRate * 100).toStringAsFixed(1)}%';

  /// Get formatted average response time.
  String get avgResponseTimeDisplay {
    if (averageResponseTime == null) return 'N/A';
    final minutes = averageResponseTime!.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h ${minutes % 60}m';
  }

  /// Get peak activity time display.
  String get peakTimeDisplay {
    if (peakActivityHour == null) return 'N/A';
    final hour = peakActivityHour!;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Get views change from previous period.
  int get viewsChange {
    if (weeklyTrend.length < 2) return 0;
    final recent = weeklyTrend.last.views;
    final previous = weeklyTrend[weeklyTrend.length - 2].views;
    return recent - previous;
  }

  ProfileInsights copyWith({
    String? userId,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? profileViews,
    int? likesReceived,
    int? likesSent,
    int? superLikesReceived,
    double? matchRate,
    double? responseRate,
    Duration? averageResponseTime,
    int? peakActivityHour,
    List<int>? topPhotosViewed,
    DemographicBreakdown? demographicBreakdown,
    List<DailyMetric>? weeklyTrend,
  }) {
    return ProfileInsights(
      userId: userId ?? this.userId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      profileViews: profileViews ?? this.profileViews,
      likesReceived: likesReceived ?? this.likesReceived,
      likesSent: likesSent ?? this.likesSent,
      superLikesReceived: superLikesReceived ?? this.superLikesReceived,
      matchRate: matchRate ?? this.matchRate,
      responseRate: responseRate ?? this.responseRate,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      peakActivityHour: peakActivityHour ?? this.peakActivityHour,
      topPhotosViewed: topPhotosViewed ?? this.topPhotosViewed,
      demographicBreakdown: demographicBreakdown ?? this.demographicBreakdown,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'profileViews': profileViews,
      'likesReceived': likesReceived,
      'likesSent': likesSent,
      'superLikesReceived': superLikesReceived,
      'matchRate': matchRate,
      'responseRate': responseRate,
      'averageResponseTime': averageResponseTime?.inMinutes,
      'peakActivityHour': peakActivityHour,
      'topPhotosViewed': topPhotosViewed,
      'demographicBreakdown': demographicBreakdown?.toJson(),
      'weeklyTrend': weeklyTrend.map((d) => d.toJson()).toList(),
    };
  }

  factory ProfileInsights.fromJson(Map<String, dynamic> json) {
    return ProfileInsights(
      userId: json['userId'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      profileViews: json['profileViews'] as int? ?? 0,
      likesReceived: json['likesReceived'] as int? ?? 0,
      likesSent: json['likesSent'] as int? ?? 0,
      superLikesReceived: json['superLikesReceived'] as int? ?? 0,
      matchRate: (json['matchRate'] as num?)?.toDouble() ?? 0.0,
      responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0.0,
      averageResponseTime: json['averageResponseTime'] != null
          ? Duration(minutes: json['averageResponseTime'] as int)
          : null,
      peakActivityHour: json['peakActivityHour'] as int?,
      topPhotosViewed: (json['topPhotosViewed'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      demographicBreakdown: json['demographicBreakdown'] != null
          ? DemographicBreakdown.fromJson(
              json['demographicBreakdown'] as Map<String, dynamic>)
          : null,
      weeklyTrend: (json['weeklyTrend'] as List<dynamic>?)
              ?.map((e) => DailyMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        userId,
        periodStart,
        periodEnd,
        profileViews,
        likesReceived,
        likesSent,
        superLikesReceived,
        matchRate,
        responseRate,
        averageResponseTime,
        peakActivityHour,
        topPhotosViewed,
        demographicBreakdown,
        weeklyTrend,
      ];
}

/// Daily metrics for trend analysis.
class DailyMetric extends Equatable {
  const DailyMetric({
    required this.date,
    this.views = 0,
    this.likes = 0,
    this.matches = 0,
  });

  final DateTime date;
  final int views;
  final int likes;
  final int matches;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'views': views,
      'likes': likes,
      'matches': matches,
    };
  }

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: DateTime.parse(json['date'] as String),
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [date, views, likes, matches];
}

/// Demographic breakdown of profile viewers.
class DemographicBreakdown extends Equatable {
  const DemographicBreakdown({
    this.ageRanges = const {},
    this.topLocations = const [],
    this.genderSplit = const {},
  });

  /// Age range distribution (e.g., "18-24": 30, "25-34": 45).
  final Map<String, int> ageRanges;

  /// Top locations of viewers.
  final List<String> topLocations;

  /// Gender split of viewers.
  final Map<String, int> genderSplit;

  Map<String, dynamic> toJson() {
    return {
      'ageRanges': ageRanges,
      'topLocations': topLocations,
      'genderSplit': genderSplit,
    };
  }

  factory DemographicBreakdown.fromJson(Map<String, dynamic> json) {
    return DemographicBreakdown(
      ageRanges: (json['ageRanges'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      topLocations: (json['topLocations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      genderSplit: (json['genderSplit'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }

  @override
  List<Object?> get props => [ageRanges, topLocations, genderSplit];
}
