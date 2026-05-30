import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Continue applies the selected preview theme and exits', (
    tester,
  ) async {
    final harness = await _pumpAppearanceHost(tester);

    await tester.tap(find.text('Open appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(harness.themeCubit.state, AppThemeMode.dark);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(harness.themeCubit.state, AppThemeMode.light);
    expect(harness.preferences.getString('crush_theme_mode'), 'light');
    expect(find.byType(AppearanceSettingsScreen), findsNothing);
    expect(find.text('Open appearance'), findsOneWidget);
  });

  testWidgets('Later keeps the current theme and exits', (tester) async {
    final harness = await _pumpAppearanceHost(tester);

    await tester.tap(find.text('Open appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(harness.themeCubit.state, AppThemeMode.dark);
    expect(harness.preferences.getString('crush_theme_mode'), 'dark');
    expect(find.byType(AppearanceSettingsScreen), findsNothing);
    expect(find.text('Open appearance'), findsOneWidget);
  });
}

Future<_AppearanceHarness> _pumpAppearanceHost(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'crush_theme_mode': 'dark'});
  final preferences = await SharedPreferences.getInstance();
  final authRepository = FakeAuthRepository();
  final profileRepository = FakeProfileRepository();
  final subscriptionRepository = FakeSubscriptionRepository();
  final themeCubit = ThemeCubit(
    preferences: preferences,
    authRepository: authRepository,
    profileRepository: profileRepository,
  );
  final subscriptionBloc = SubscriptionBloc(
    subscriptionRepository: subscriptionRepository,
    authRepository: authRepository,
  );

  addTearDown(() async {
    await themeCubit.close();
    await subscriptionBloc.close();
    authRepository.dispose();
    subscriptionRepository.dispose();
  });

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _AppearanceHost(),
      ),
    ),
  );
  await tester.pump();

  return _AppearanceHarness(preferences: preferences, themeCubit: themeCubit);
}

class _AppearanceHarness {
  const _AppearanceHarness({
    required this.preferences,
    required this.themeCubit,
  });

  final SharedPreferences preferences;
  final ThemeCubit themeCubit;
}

class _AppearanceHost extends StatelessWidget {
  const _AppearanceHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AppearanceSettingsScreen(),
              ),
            );
          },
          child: const Text('Open appearance'),
        ),
      ),
    );
  }
}
