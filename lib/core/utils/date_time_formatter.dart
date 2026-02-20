import 'package:intl/intl.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// Centralized, locale-aware date/time formatting utility.
///
/// All date/time display in the app should use this class to ensure
/// consistent locale-aware formatting across all 20 supported languages.
///
/// Uses the `intl` package [DateFormat] for locale awareness and
/// [AppLocalizations] for translated relative labels (Today, Yesterday, etc.).
class DateTimeFormatter {
  DateTimeFormatter._();

  // ---------------------------------------------------------------------------
  // Absolute time formatting
  // ---------------------------------------------------------------------------

  /// Format a time for display (e.g., "2:45 PM" or "14:45" depending on locale).
  ///
  /// Used for: chat message timestamps, read receipts, search results.
  static String formatTime(DateTime time, {required String locale}) {
    return DateFormat.jm(locale).format(time);
  }

  /// Format a full date (e.g., "Jan 15, 2026" or "15 Jan 2026" depending on locale).
  ///
  /// Used for: subscription renewal dates, account action dates.
  static String formatDate(DateTime date, {required String locale}) {
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Format a short numeric date (e.g., "1/15" or "15/1" depending on locale).
  ///
  /// Used for: chat list items older than a week.
  static String formatShortDate(DateTime date, {required String locale}) {
    return DateFormat.Md(locale).format(date);
  }

  /// Format a weekday abbreviation (e.g., "Mon" or locale-appropriate).
  ///
  /// Used for: chat date separators within the last week.
  static String formatWeekday(DateTime date, {required String locale}) {
    return DateFormat.E(locale).format(date);
  }

  // ---------------------------------------------------------------------------
  // Chat date separator — "Today" / "Yesterday" / weekday / full date
  // ---------------------------------------------------------------------------

  /// Format a date for chat separators with relative labels.
  ///
  /// Returns "Today", "Yesterday", abbreviated weekday (within 7 days),
  /// or a locale-formatted date for older messages.
  static String formatChatSeparator(
    DateTime date, {
    required AppLocalizations l10n,
    required String locale,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return l10n.chatToday;
    } else if (dateOnly == yesterday) {
      return l10n.chatYesterday;
    } else if (now.difference(date).inDays < 7) {
      return formatWeekday(date, locale: locale);
    } else {
      return formatDate(date, locale: locale);
    }
  }

  // ---------------------------------------------------------------------------
  // Relative / time-ago formatting
  // ---------------------------------------------------------------------------

  /// Compact relative time for chat list previews (e.g., "now", "5m", "2h", "3d").
  ///
  /// Uses short abbreviations. Falls back to locale-aware short date for >7d.
  static String formatRelativeCompact(
    DateTime time, {
    required AppLocalizations l10n,
    required String locale,
  }) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return l10n.wordNow.toLowerCase();
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return formatShortDate(time, locale: locale);
    }
  }

  /// Verbose relative time for accessibility labels.
  ///
  /// Uses full localized strings: "just now", "5 minutes ago", etc.
  static String formatRelativeVerbose(
    DateTime time, {
    required AppLocalizations l10n,
    required String locale,
  }) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return l10n.wordNow.toLowerCase();
    } else if (diff.inHours < 1) {
      return l10n.timeMinutesAgo(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return l10n.timeHoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.timeDaysAgo(diff.inDays);
    } else if (diff.inDays < 30) {
      return l10n.timeWeeksAgo((diff.inDays / 7).floor());
    } else {
      return formatDate(time, locale: locale);
    }
  }

  /// Message search result time — shows time today, "Yesterday", weekday
  /// within a week, or short date for older.
  static String formatSearchResultTime(
    DateTime time, {
    required AppLocalizations l10n,
    required String locale,
  }) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return formatTime(time, locale: locale);
    } else if (diff.inDays == 1) {
      return l10n.chatYesterday;
    } else if (diff.inDays < 7) {
      return formatWeekday(time, locale: locale);
    } else {
      return formatShortDate(time, locale: locale);
    }
  }

  // ---------------------------------------------------------------------------
  // Number formatting
  // ---------------------------------------------------------------------------

  /// Format an integer with locale-aware grouping (e.g., "1,234" or "1.234").
  static String formatNumber(int value, {required String locale}) {
    return NumberFormat.decimalPattern(locale).format(value);
  }

  /// Format a distance with units. Uses km for most locales, miles for US/UK.
  static String formatDistance(
    double km, {
    required String locale,
    required AppLocalizations l10n,
  }) {
    final useMiles = locale.startsWith('en_US') || locale.startsWith('en_GB');
    if (useMiles) {
      final miles = km * 0.621371;
      if (miles < 1) {
        return '< 1 mi';
      }
      return '${NumberFormat('#,##0', locale).format(miles.round())} mi';
    }
    if (km < 1) {
      return '< 1 km';
    }
    return '${NumberFormat('#,##0', locale).format(km.round())} km';
  }
}
