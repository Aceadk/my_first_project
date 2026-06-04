import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SET-UI-002: settings toggles must expose their label to screen readers.
/// A bare `Switch` in `ListTile.trailing` is announced as just "on/off, switch";
/// `MergeSemantics` folds the label + control into one node so the merged node
/// carries both the toggled state and a non-empty label.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'gdpr_consent_timestamp': DateTime.utc(2026, 5, 30).toIso8601String(),
    });
  });

  testWidgets('privacy toggles expose a merged, labeled semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final prefs = await SharedPreferences.getInstance();
    final cubit = PrivacySettingsCubit(preferences: prefs);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<PrivacySettingsCubit>.value(
        value: cubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sem = tester.getSemantics(find.byType(Switch).first);
    expect(sem, isSemantics(hasToggledState: true));
    expect(
      sem.label.trim(),
      isNotEmpty,
      reason: 'toggle must announce its label, not just on/off',
    );

    handle.dispose();
  });

  testWidgets('notification toggles expose a merged, labeled semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final prefs = await SharedPreferences.getInstance();
    final cubit = NotificationSettingsCubit(preferences: prefs);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<NotificationSettingsCubit>.value(
        value: cubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sem = tester.getSemantics(find.byType(Switch).first);
    expect(sem, isSemantics(hasToggledState: true));
    expect(sem.label.trim(), isNotEmpty);

    handle.dispose();
  });
}
