import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/account_security_settings_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized account security section labels', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final authBloc = AuthBloc(authRepository: authRepository);
    final biometricCubit = BiometricCubit();

    addTearDown(() async {
      await authBloc.close();
      await biometricCubit.close();
    });

    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: authRepository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<BiometricCubit>.value(value: biometricCubit),
          ],
          child: const MaterialApp(
            locale: Locale('en', 'XA'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccountSecuritySettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Protect Your Account xxxx'), findsOneWidget);
    expect(find.text('Linked Accounts xxxx'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Security tips xxxx'), 250);
    expect(find.text('Security tips xxxx'), findsOneWidget);
  });
}
