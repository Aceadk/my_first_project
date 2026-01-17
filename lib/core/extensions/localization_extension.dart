import 'package:flutter/widgets.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// Extension on BuildContext for easy access to localized strings.
///
/// Usage:
/// ```dart
/// Text(context.l10n.authWelcomeBack)
/// ```
extension LocalizationExtension on BuildContext {
  /// Get the localized strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
