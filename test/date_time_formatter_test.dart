import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn('en');

  group('DateTimeFormatter absolute formatting', () {
    test('formatTime returns localized time', () {
      final value = DateTimeFormatter.formatTime(
        DateTime(2026, 2, 21, 14, 45),
        locale: 'en_US',
      );

      expect(value, isNotEmpty);
      expect(value, contains(':'));
    });

    test('formatDate, formatShortDate, and formatWeekday return non-empty', () {
      final date = DateTime(2026, 2, 21);

      final full = DateTimeFormatter.formatDate(date, locale: 'en_US');
      final short = DateTimeFormatter.formatShortDate(date, locale: 'en_US');
      final weekday = DateTimeFormatter.formatWeekday(date, locale: 'en_US');

      expect(full, isNotEmpty);
      expect(short, isNotEmpty);
      expect(weekday, isNotEmpty);
    });
  });

  group('DateTimeFormatter chat separator', () {
    test('formatChatSeparator returns today label for current date', () {
      // Anchored to the start of today (not `now - 2h`) so the fixture stays
      // inside "today" even when the test runs shortly after midnight.
      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(minutes: 30));

      final value = DateTimeFormatter.formatChatSeparator(
        today,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(value, l10n.chatToday);
    });

    test('formatChatSeparator returns yesterday label for previous day', () {
      final now = DateTime.now();
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(hours: 12));

      final value = DateTimeFormatter.formatChatSeparator(
        yesterday,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(value, l10n.chatYesterday);
    });

    test('formatChatSeparator returns weekday within last week', () {
      final withinWeek = DateTime.now().subtract(const Duration(days: 3));
      final weekday = DateTimeFormatter.formatWeekday(
        withinWeek,
        locale: 'en_US',
      );

      final value = DateTimeFormatter.formatChatSeparator(
        withinWeek,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(value, weekday);
    });

    test('formatChatSeparator returns full date for older messages', () {
      final older = DateTime.now().subtract(const Duration(days: 10));
      final fullDate = DateTimeFormatter.formatDate(older, locale: 'en_US');

      final value = DateTimeFormatter.formatChatSeparator(
        older,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(value, fullDate);
    });
  });

  group('DateTimeFormatter relative compact', () {
    test('returns now label for <1 minute', () {
      final value = DateTimeFormatter.formatRelativeCompact(
        DateTime.now().subtract(const Duration(seconds: 30)),
        l10n: l10n,
        locale: 'en_US',
      );

      expect(value, l10n.wordNow.toLowerCase());
    });

    test('returns minute/hour/day units and short date for old values', () {
      final minute = DateTimeFormatter.formatRelativeCompact(
        DateTime.now().subtract(const Duration(minutes: 5)),
        l10n: l10n,
        locale: 'en_US',
      );
      final hour = DateTimeFormatter.formatRelativeCompact(
        DateTime.now().subtract(const Duration(hours: 3)),
        l10n: l10n,
        locale: 'en_US',
      );
      final day = DateTimeFormatter.formatRelativeCompact(
        DateTime.now().subtract(const Duration(days: 2)),
        l10n: l10n,
        locale: 'en_US',
      );
      final olderDate = DateTime.now().subtract(const Duration(days: 10));
      final older = DateTimeFormatter.formatRelativeCompact(
        olderDate,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(minute, '5m');
      expect(hour, '3h');
      expect(day, '2d');
      expect(
        older,
        DateTimeFormatter.formatShortDate(olderDate, locale: 'en_US'),
      );
    });
  });

  group('DateTimeFormatter relative verbose', () {
    test('returns localized minute/hour/day/week and date branches', () {
      final minute = DateTimeFormatter.formatRelativeVerbose(
        DateTime.now().subtract(const Duration(minutes: 5)),
        l10n: l10n,
        locale: 'en_US',
      );
      final hour = DateTimeFormatter.formatRelativeVerbose(
        DateTime.now().subtract(const Duration(hours: 3)),
        l10n: l10n,
        locale: 'en_US',
      );
      final day = DateTimeFormatter.formatRelativeVerbose(
        DateTime.now().subtract(const Duration(days: 2)),
        l10n: l10n,
        locale: 'en_US',
      );
      final week = DateTimeFormatter.formatRelativeVerbose(
        DateTime.now().subtract(const Duration(days: 20)),
        l10n: l10n,
        locale: 'en_US',
      );
      final olderDate = DateTime.now().subtract(const Duration(days: 45));
      final older = DateTimeFormatter.formatRelativeVerbose(
        olderDate,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(minute, l10n.timeMinutesAgo(5));
      expect(hour, l10n.timeHoursAgo(3));
      expect(day, l10n.timeDaysAgo(2));
      expect(week, l10n.timeWeeksAgo((20 / 7).floor()));
      expect(older, DateTimeFormatter.formatDate(olderDate, locale: 'en_US'));
    });
  });

  group('DateTimeFormatter search result time', () {
    test('returns time/yesterday/weekday/short-date branches', () {
      final today = DateTime.now().subtract(const Duration(hours: 2));
      final yesterday = DateTime.now().subtract(
        const Duration(days: 1, hours: 1),
      );
      final week = DateTime.now().subtract(const Duration(days: 3));
      final older = DateTime.now().subtract(const Duration(days: 20));

      final todayValue = DateTimeFormatter.formatSearchResultTime(
        today,
        l10n: l10n,
        locale: 'en_US',
      );
      final yesterdayValue = DateTimeFormatter.formatSearchResultTime(
        yesterday,
        l10n: l10n,
        locale: 'en_US',
      );
      final weekValue = DateTimeFormatter.formatSearchResultTime(
        week,
        l10n: l10n,
        locale: 'en_US',
      );
      final olderValue = DateTimeFormatter.formatSearchResultTime(
        older,
        l10n: l10n,
        locale: 'en_US',
      );

      expect(todayValue, DateTimeFormatter.formatTime(today, locale: 'en_US'));
      expect(yesterdayValue, l10n.chatYesterday);
      expect(weekValue, DateTimeFormatter.formatWeekday(week, locale: 'en_US'));
      expect(
        olderValue,
        DateTimeFormatter.formatShortDate(older, locale: 'en_US'),
      );
    });
  });

  group('DateTimeFormatter numbers and distance', () {
    test('formatNumber applies grouping', () {
      expect(
        DateTimeFormatter.formatNumber(1234567, locale: 'en_US'),
        '1,234,567',
      );
    });

    test('formatDistance uses miles for en_US and km for non-US locales', () {
      expect(
        DateTimeFormatter.formatDistance(2.0, locale: 'en_US', l10n: l10n),
        '1 mi',
      );
      expect(
        DateTimeFormatter.formatDistance(5.0, locale: 'fr_FR', l10n: l10n),
        '5 km',
      );
    });

    test('formatDistance handles below-1 thresholds', () {
      expect(
        DateTimeFormatter.formatDistance(0.3, locale: 'en_US', l10n: l10n),
        '< 1 mi',
      );
      expect(
        DateTimeFormatter.formatDistance(0.3, locale: 'fr_FR', l10n: l10n),
        '< 1 km',
      );
    });
  });
}
