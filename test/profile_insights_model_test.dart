import 'package:crushhour/features/analytics/data/models/profile_insights_dto.dart';
import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileInsights model', () {
    final start = DateTime(2026, 2, 1);
    final end = DateTime(2026, 2, 8);

    ProfileInsights buildInsights({
      double matchRate = 0.256,
      double responseRate = 0.734,
      Duration? averageResponseTime,
      int? peakActivityHour,
      List<DailyMetric> weeklyTrend = const [],
    }) {
      return ProfileInsights(
        userId: 'u1',
        periodStart: start,
        periodEnd: end,
        profileViews: 88,
        likesReceived: 20,
        likesSent: 24,
        superLikesReceived: 3,
        matchRate: matchRate,
        responseRate: responseRate,
        averageResponseTime: averageResponseTime,
        peakActivityHour: peakActivityHour,
        topPhotosViewed: const [1, 3],
        demographicBreakdown: const DemographicBreakdown(
          ageRanges: {'18-24': 10},
          topLocations: ['NYC'],
          genderSplit: {'Women': 70},
        ),
        weeklyTrend: weeklyTrend,
      );
    }

    test('display helpers render all branches', () {
      final mins = buildInsights(
        averageResponseTime: const Duration(minutes: 45),
        peakActivityHour: 0,
      );
      final hours = buildInsights(
        averageResponseTime: const Duration(minutes: 135),
        peakActivityHour: 17,
      );
      final none = buildInsights(
        averageResponseTime: null,
        peakActivityHour: null,
      );
      final am = buildInsights(peakActivityHour: 9);
      final noon = buildInsights(peakActivityHour: 12);

      expect(mins.matchRateDisplay, '25.6%');
      expect(mins.responseRateDisplay, '73.4%');
      expect(mins.avgResponseTimeDisplay, '45m');
      expect(hours.avgResponseTimeDisplay, '2h 15m');
      expect(none.avgResponseTimeDisplay, 'N/A');

      expect(mins.peakTimeDisplay, '12 AM');
      expect(am.peakTimeDisplay, '9 AM');
      expect(noon.peakTimeDisplay, '12 PM');
      expect(hours.peakTimeDisplay, '5 PM');
      expect(none.peakTimeDisplay, 'N/A');
    });

    test('viewsChange handles empty and populated trends', () {
      final noTrend = buildInsights();
      final trend = buildInsights(
        weeklyTrend: [
          DailyMetric(date: DateTime(2026, 2, 1), views: 8),
          DailyMetric(date: DateTime(2026, 2, 2), views: 13),
        ],
      );

      expect(noTrend.viewsChange, 0);
      expect(trend.viewsChange, 5);
    });

    test('DTO round-trip preserves data', () {
      final insightsDto = ProfileInsightsDto(
        userId: 'u1',
        periodStart: start,
        periodEnd: end,
        profileViews: 99,
        likesReceived: 20,
        likesSent: 40,
        averageResponseTime: const Duration(minutes: 20),
        peakActivityHour: 14,
        weeklyTrend: [
          DailyMetricDto(date: DateTime(2026, 2, 1), views: 10, likes: 2),
        ],
        demographicBreakdown: const DemographicBreakdownDto(
          ageRanges: {'18-24': 10},
          topLocations: ['NYC'],
          genderSplit: {'Women': 70},
        ),
      );

      final parsed = ProfileInsightsDto.fromJson(insightsDto.toJson());
      expect(parsed, insightsDto);
      expect(parsed.demographicBreakdown, isNotNull);
      expect(parsed.weeklyTrend, isNotEmpty);
    });
  });

  group('DailyMetricDto and DemographicBreakdownDto', () {
    test('DailyMetricDto json mapping is stable', () {
      final metric = DailyMetricDto(
        date: DateTime(2026, 2, 1),
        views: 11,
        likes: 4,
        matches: 2,
      );

      final parsed = DailyMetricDto.fromJson(metric.toJson());
      expect(parsed, metric);
    });

    test('DemographicBreakdownDto json mapping supports defaults', () {
      const breakdown = DemographicBreakdownDto(
        ageRanges: {'25-34': 42},
        topLocations: ['Los Angeles'],
        genderSplit: {'Men': 55},
      );

      final parsed = DemographicBreakdownDto.fromJson(breakdown.toJson());
      expect(parsed, breakdown);

      final defaultParsed = DemographicBreakdownDto.fromJson(const {});
      expect(defaultParsed.ageRanges, isEmpty);
      expect(defaultParsed.topLocations, isEmpty);
      expect(defaultParsed.genderSplit, isEmpty);
    });
  });
}
