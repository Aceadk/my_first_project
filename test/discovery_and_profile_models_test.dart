import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';
import 'package:crushhour/features/discovery/domain/models/weekly_picks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyPicks', () {
    final now = DateTime.now();

    WeeklyPick buildPick(String id, PickReason reason) {
      return WeeklyPick(
        id: id,
        profileId: 'profile_$id',
        reason: reason,
        matchScore: 80,
        commonInterests: const ['music'],
      );
    }

    test('week state, counters, display strings and constants', () {
      final current = WeeklyPicks(
        userId: 'u1',
        weekStart: now.subtract(const Duration(days: 1)),
        weekEnd: now.add(const Duration(days: 2)),
        picks: [
          buildPick('1', PickReason.topPick),
          buildPick('2', PickReason.sharedInterests),
        ],
        viewedPicks: const ['1'],
      );
      final expired = WeeklyPicks(
        userId: 'u1',
        weekStart: now.subtract(const Duration(days: 10)),
        weekEnd: now.subtract(const Duration(days: 1)),
        picks: [buildPick('1', PickReason.topPick)],
      );

      expect(WeeklyPicks.maxPicks, 10);
      expect(current.isCurrentWeek, isTrue);
      expect(expired.isCurrentWeek, isFalse);
      expect(current.unseenCount, 1);
      expect(current.allViewed, isFalse);
      expect(expired.newPicksTimeDisplay, 'New picks available!');
      expect(current.newPicksTimeDisplay, startsWith('New picks in'));
    });

    test('markViewed and markLiked avoid duplicates and sync viewed state', () {
      final picks = WeeklyPicks(
        userId: 'u1',
        weekStart: now.subtract(const Duration(days: 1)),
        weekEnd: now.add(const Duration(days: 6)),
        picks: [buildPick('1', PickReason.topPick)],
      );

      final viewed = picks.markViewed('1');
      final viewedAgain = viewed.markViewed('1');
      expect(viewed.viewedPicks, ['1']);
      expect(viewedAgain, viewed);

      final liked = picks.markLiked('1');
      expect(liked.likedPicks, ['1']);
      expect(liked.viewedPicks, ['1']);
      expect(liked.markLiked('1'), liked);
    });

    test('copyWith and json mapping preserve values', () {
      final source = WeeklyPicks(
        userId: 'u9',
        weekStart: now.subtract(const Duration(days: 2)),
        weekEnd: now.add(const Duration(days: 5)),
        picks: [buildPick('a', PickReason.nearbyLocation)],
      );
      final updated = source.copyWith(viewedPicks: const ['a']);
      final parsed = WeeklyPicks.fromJson(updated.toJson());

      expect(parsed, updated);
      expect(parsed.viewedPicks, ['a']);
      expect(parsed.picks.first.reasonDisplay, 'Lives Nearby');
    });

    test('weekly pick fallback reason and reason metadata coverage', () {
      final fallback = WeeklyPick.fromJson(const {
        'id': 'x',
        'profileId': 'p1',
        'reason': 'unknown_reason',
      });
      expect(fallback.reason, PickReason.topPick);

      for (final reason in PickReason.values) {
        expect(reason.displayText, isNotEmpty);
        expect(reason.emoji, isNotEmpty);
      }
    });
  });

  group('IncognitoSettings', () {
    final now = DateTime.now();

    test('expiration and active state branches', () {
      const disabled = IncognitoSettings();
      final premiumNoExpiry = IncognitoSettings(
        isEnabled: true,
        enabledAt: now,
        expiresAt: null,
      );
      final expired = IncognitoSettings(
        isEnabled: true,
        enabledAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(IncognitoSettings.freeDuration, const Duration(hours: 1));
      expect(disabled.isExpired, isTrue);
      expect(disabled.isActive, isFalse);
      expect(premiumNoExpiry.isExpired, isFalse);
      expect(premiumNoExpiry.isActive, isTrue);
      expect(expired.isExpired, isTrue);
      expect(expired.isActive, isFalse);
    });

    test('remaining time display and json/copyWith behavior', () {
      final withHours = IncognitoSettings(
        isEnabled: true,
        enabledAt: now,
        expiresAt: now.add(const Duration(hours: 1, minutes: 20)),
      );
      final withMinutes = IncognitoSettings(
        isEnabled: true,
        enabledAt: now,
        expiresAt: now.add(const Duration(minutes: 20)),
      );

      expect(withHours.remainingTimeDisplay, contains('h'));
      expect(withMinutes.remainingTimeDisplay, contains('m remaining'));

      final updated = withMinutes.copyWith(
        hideReadReceipts: false,
        onlyShowToLiked: true,
      );
      final parsed = IncognitoSettings.fromJson(updated.toJson());
      expect(parsed, updated);
      expect(parsed.hideReadReceipts, isFalse);
      expect(parsed.onlyShowToLiked, isTrue);
    });
  });

  group('ProfileFavourites', () {
    test('hasAnyFavourites and filledCount reflect selected fields', () {
      const empty = ProfileFavourites();
      const partial = ProfileFavourites(
        athlete: 'Messi',
        food: 'Pizza',
        travelDestination: 'Tokyo',
      );

      expect(empty.hasAnyFavourites, isFalse);
      expect(empty.filledCount, 0);
      expect(partial.hasAnyFavourites, isTrue);
      expect(partial.filledCount, 3);
    });

    test('copyWith supports updates and clear flags', () {
      const base = ProfileFavourites(
        athlete: 'Ronaldo',
        food: 'Sushi',
        tvShow: 'Dark',
      );

      final updated = base.copyWith(food: 'Tacos', clearTvShow: true);
      expect(updated.athlete, 'Ronaldo');
      expect(updated.food, 'Tacos');
      expect(updated.tvShow, isNull);
    });

    test('json mapping and options lists are available', () {
      const fav = ProfileFavourites(athlete: 'LeBron James', singer: 'Adele');
      final parsed = ProfileFavourites.fromJson(fav.toJson());

      expect(parsed, fav);
      expect(FavouritesOptions.athletes, isNotEmpty);
      expect(FavouritesOptions.foods, isNotEmpty);
      expect(FavouritesOptions.sports, isNotEmpty);
      expect(FavouritesOptions.tvShows, isNotEmpty);
      expect(FavouritesOptions.actors, isNotEmpty);
      expect(FavouritesOptions.singers, isNotEmpty);
      expect(FavouritesOptions.movies, isNotEmpty);
      expect(FavouritesOptions.books, isNotEmpty);
      expect(FavouritesOptions.hobbies, isNotEmpty);
      expect(FavouritesOptions.travelDestinations, isNotEmpty);
    });
  });

  group('ProfileReaction', () {
    final now = DateTime(2026, 2, 12, 10);

    test('comment/emoji helpers, copyWith and json fallback work', () {
      final reaction = ProfileReaction(
        id: 'r1',
        fromUserId: 'u1',
        toUserId: 'u2',
        contentType: ReactionContentType.photo,
        contentIndex: 0,
        reactionType: 'fire',
        createdAt: now,
        comment: 'Great shot',
      );

      expect(reaction.hasComment, isTrue);
      expect(reaction.emoji, '🔥');

      final updated = reaction.copyWith(reactionType: 'unknown');
      expect(updated.emoji, '❤️');

      final parsed = ProfileReaction.fromJson({
        ...updated.toJson(),
        'contentType': 'bad_type',
      });
      expect(parsed.contentType, ReactionContentType.photo);
      expect(parsed.isRead, isFalse);
    });

    test('reaction type helpers and quick reactions are available', () {
      expect(availableReactionTypes, isNotEmpty);
      expect(getReactionEmoji('love'), '😍');
      expect(getReactionEmoji('nonexistent'), '❤️');
      expect(QuickReaction.photoReactions.length, 4);
      expect(QuickReaction.promptReactions.length, 4);
    });
  });
}
