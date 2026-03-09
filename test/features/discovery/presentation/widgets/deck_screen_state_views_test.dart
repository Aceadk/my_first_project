import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_error_state_view.dart';
import 'package:crushhour/features/discovery/presentation/widgets/deck_out_of_people_view.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeckErrorStateView', () {
    testWidgets('renders retry details and triggers retry callback', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(
          child: DeckErrorStateView(
            appBar: AppBar(title: const Text('Deck')),
            retryInSeconds: 12,
            isPlus: true,
            locationLabel: 'Austin, United States',
            radiusKm: 50,
            onRetry: () => retries++,
            onShowPassportUpsell: () {},
          ),
        ),
      );

      expect(find.text('Trouble loading people'), findsOneWidget);
      expect(
        find.textContaining('Looking near Austin, United States within ~50 km.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, equals(1));
    });
  });

  group('DeckOutOfPeopleView', () {
    testWidgets('shows passport-mode messaging and refresh callback', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsCubit = DiscoverySettingsCubit(preferences: prefs);
      addTearDown(settingsCubit.close);

      var refreshed = 0;
      await tester.pumpWidget(
        _host(
          child: BlocProvider<DiscoverySettingsCubit>.value(
            value: settingsCubit,
            child: DeckOutOfPeopleView(
              discoveryState: const DiscoveryState(
                passportModeActive: true,
                currentDistanceLimitKm: 120,
              ),
              isPlus: true,
              locationLabel: 'Tokyo, Japan',
              onRefresh: () => refreshed++,
              onShowPassportUpsell: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No one in this city yet'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
      expect(find.text('Enable Passport mode'), findsNothing);
      expect(find.text('Try Passport with Plus'), findsNothing);

      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.refresh));
      await tester.pump();

      expect(refreshed, equals(1));
    });
  });
}

Widget _host({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 430,
        height: 900,
        child: child,
      ),
    ),
  );
}
