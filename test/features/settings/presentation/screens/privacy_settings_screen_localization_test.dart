import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders localized privacy section titles', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final cubit = PrivacySettingsCubit(preferences: prefs);

    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<PrivacySettingsCubit>.value(
        value: cubit,
        child: const MaterialApp(
          locale: Locale('en', 'XA'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacySettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Control Your Privacy xxxx'), findsOneWidget);
    expect(find.text('Name Visibility xxxx'), findsOneWidget);
    expect(find.text('Sensitive Information xxxx'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Lifestyle xxxx'), 300);
    expect(find.text('Lifestyle xxxx'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Activity Status xxxx'), 300);
    expect(find.text('Activity Status xxxx'), findsOneWidget);
  });
}
