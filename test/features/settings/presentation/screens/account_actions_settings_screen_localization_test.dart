import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/account_actions_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders localized account actions section and action labels', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final authBloc = AuthBloc(authRepository: FakeAuthRepository());
    final discoveryCubit = DiscoverySettingsCubit(preferences: prefs);

    addTearDown(() async {
      await authBloc.close();
      await discoveryCubit.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<DiscoverySettingsCubit>.value(value: discoveryCubit),
        ],
        child: const MaterialApp(
          locale: Locale('en', 'XA'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountActionsSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manage Your Account xxxx'), findsOneWidget);
    expect(find.text('Security xxxx'), findsOneWidget);
    expect(find.text('Add phone number xxxx'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Data & Privacy xxxx'), 300);
    expect(find.text('Data & Privacy xxxx'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Danger zone xxxx'), 300);
    expect(find.text('Danger zone xxxx'), findsOneWidget);
  });
}
