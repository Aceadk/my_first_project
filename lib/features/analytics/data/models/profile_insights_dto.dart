import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';

/// Profile insights DTO.
class ProfileInsightsDto extends ProfileInsights {
  const ProfileInsightsDto({
    required super.userId,
    required super.periodStart,
    required super.periodEnd,
    super.profileViews = 0,
    super.likesReceived = 0,
    super.likesSent = 0,
    super.superLikesReceived = 0,
    super.matchRate = 0.0,
    super.responseRate = 0.0,
    super.averageResponseTime,
    super.peakActivityHour,
    super.topPhotosViewed = const [],
    super.demographicBreakdown,
    super.weeklyTrend = const [],
  });

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
      'demographicBreakdown': (demographicBreakdown as DemographicBreakdownDto?)
          ?.toJson(),
      'weeklyTrend': weeklyTrend
          .map((d) => (d as DailyMetricDto).toJson())
          .toList(),
    };
  }

  factory ProfileInsightsDto.fromJson(Map<String, dynamic> json) {
    return ProfileInsightsDto(
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
      topPhotosViewed:
          (json['topPhotosViewed'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      demographicBreakdown: json['demographicBreakdown'] != null
          ? DemographicBreakdownDto.fromJson(
              json['demographicBreakdown'] as Map<String, dynamic>,
            )
          : null,
      weeklyTrend:
          (json['weeklyTrend'] as List<dynamic>?)
              ?.map((e) => DailyMetricDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Daily metrics DTO.
class DailyMetricDto extends DailyMetric {
  const DailyMetricDto({
    required super.date,
    super.views = 0,
    super.likes = 0,
    super.matches = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'views': views,
      'likes': likes,
      'matches': matches,
    };
  }

  factory DailyMetricDto.fromJson(Map<String, dynamic> json) {
    return DailyMetricDto(
      date: DateTime.parse(json['date'] as String),
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
    );
  }
}

/// Demographic breakdown DTO.
class DemographicBreakdownDto extends DemographicBreakdown {
  const DemographicBreakdownDto({
    super.ageRanges = const {},
    super.topLocations = const [],
    super.genderSplit = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'ageRanges': ageRanges,
      'topLocations': topLocations,
      'genderSplit': genderSplit,
    };
  }

  factory DemographicBreakdownDto.fromJson(Map<String, dynamic> json) {
    return DemographicBreakdownDto(
      ageRanges:
          (json['ageRanges'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      topLocations:
          (json['topLocations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      genderSplit:
          (json['genderSplit'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }
}
