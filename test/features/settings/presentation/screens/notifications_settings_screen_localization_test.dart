import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders localized notification category labels', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final cubit = NotificationSettingsCubit(preferences: prefs);

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

    expect(find.text('Notification Categories'), findsOneWidget);
    expect(find.text('6 of 6 enabled'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Messages'), 200);
    expect(find.text('Messages'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Quiet Hours'), 200);
    expect(find.text('Quiet Hours'), findsOneWidget);

    await cubit.close();
  });
}
