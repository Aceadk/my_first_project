import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/discovery/data/services/weekly_picks_service.dart';
import 'package:crushhour/features/discovery/data/models/weekly_picks.dart';

void main() {
  group('WeeklyPicksService', () {
    late WeeklyPicksService service;

    setUp(() {
      service = WeeklyPicksService.instance;
    });

    group('loadPicks', () {
      test('loads picks for user', () async {
        final picks = await service.loadPicks('test_user');

        expect(picks.userId, 'test_user');
        expect(picks.picks, isNotEmpty);
        expect(picks.picks.length, lessThanOrEqualTo(WeeklyPicks.maxPicks));
      });

      test('sets week start and end dates', () async {
        final picks = await service.loadPicks('date_test_user');

        expect(picks.weekStart, isNotNull);
        expect(picks.weekEnd, isNotNull);
        expect(picks.weekEnd.isAfter(picks.weekStart), isTrue);
      });

      test('generates picks with valid reasons', () async {
        final picks = await service.loadPicks('reason_test_user');

        for (final pick in picks.picks) {
          expect(PickReason.values.contains(pick.reason), isTrue);
        }
      });
    });

    group('markPickViewed', () {
      test('marks a pick as viewed', () async {
        await service.loadPicks('view_test_user');
        final pickId = service.currentPicks!.picks.first.id;

        expect(service.isPickViewed(pickId), isFalse);

        await service.markPickViewed(pickId);

        expect(service.isPickViewed(pickId), isTrue);
      });
    });

    group('markPickLiked', () {
      test('marks a pick as liked and viewed', () async {
        await service.loadPicks('like_test_user');
        final pickId = service.currentPicks!.picks.first.id;

        await service.markPickLiked(pickId);

        expect(service.isPickLiked(pickId), isTrue);
        expect(service.isPickViewed(pickId), isTrue);
      });
    });

    group('getters', () {
      test('hasUnseenPicks returns true when picks not viewed', () async {
        await service.loadPicks('unseen_test_user');

        expect(service.hasUnseenPicks, isTrue);
      });

      test('unseenCount returns correct count', () async {
        await service.loadPicks('count_test_user');
        final totalPicks = service.currentPicks!.picks.length;

        expect(service.unseenCount, totalPicks);

        // View one pick
        await service.markPickViewed(service.currentPicks!.picks.first.id);

        expect(service.unseenCount, totalPicks - 1);
      });

      test('getUnviewedPicks returns only unviewed picks', () async {
        await service.loadPicks('unviewed_test_user');
        final initialCount = service.getUnviewedPicks().length;

        await service.markPickViewed(service.currentPicks!.picks.first.id);

        expect(service.getUnviewedPicks().length, initialCount - 1);
      });

      test('getAllPicks returns all picks', () async {
        await service.loadPicks('all_picks_test_user');

        final allPicks = service.getAllPicks();

        expect(allPicks.length, service.currentPicks!.picks.length);
      });
    });

    group('time display', () {
      test('getNewPicksTimeDisplay returns non-empty string', () async {
        await service.loadPicks('time_test_user');

        expect(service.getNewPicksTimeDisplay(), isNotEmpty);
      });

      test('isCurrentWeek returns true for current week picks', () async {
        await service.loadPicks('current_week_user');

        expect(service.isCurrentWeek, isTrue);
      });
    });
  });
}
