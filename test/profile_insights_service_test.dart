import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileInsightsService', () {
    final service = ProfileInsightsService.instance;

    setUp(() {
      service.clearUserData();
    });

    test('loadInsights populates current state and emits to stream', () async {
      final emission = service.insightsStream.first;
      final insights = await service.loadInsights('user-1');
      final streamed = await emission;

      expect(insights.userId, 'user-1');
      expect(service.currentInsights, isNotNull);
      expect(streamed.userId, 'user-1');
      expect(streamed.weeklyTrend.length, 7);
    });

    test(
      'refreshInsights returns a new period snapshot for same user',
      () async {
        final first = await service.loadInsights('user-2');
        final refreshed = await service.refreshInsights('user-2');

        expect(refreshed.userId, 'user-2');
        expect(refreshed.periodEnd.isAfter(first.periodStart), isTrue);
      },
    );

    test('range query uses provided period boundaries', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 2, 15);

      final insights = await service.getInsightsForRange(
        userId: 'user-3',
        start: start,
        end: end,
      );

      expect(insights.userId, 'user-3');
      expect(insights.periodStart, start);
      expect(insights.periodEnd, end);
    });

    test('record counters update loaded insights safely', () async {
      await service.loadInsights('user-4');
      final before = service.currentInsights!;

      await service.recordProfileView('viewer-1');
      await service.recordLikeReceived();
      await service.recordLikeReceived(isSuperLike: true);
      await service.recordLikeSent();

      final after = service.currentInsights!;
      expect(after.profileViews, before.profileViews + 1);
      expect(after.likesReceived, before.likesReceived + 2);
      expect(after.superLikesReceived, before.superLikesReceived + 1);
      expect(after.likesSent, before.likesSent + 1);
    });

    test('photo performance returns sorted list and best-time label', () async {
      service.clearUserData();
      expect(service.getPhotoPerformance(), isEmpty);
      expect(service.getBestTimeToBeActive(), 'Evening');

      await service.loadInsights('user-5');
      final performance = service.getPhotoPerformance();
      expect(performance.length, 6);
      expect(performance.first.likeRate >= performance.last.likeRate, isTrue);

      expect([
        'Morning (6 AM - 12 PM)',
        'Afternoon (12 PM - 5 PM)',
        'Evening (5 PM - 9 PM)',
        'Night (9 PM - 6 AM)',
      ], contains(service.getBestTimeToBeActive()));
    });
  });
}
