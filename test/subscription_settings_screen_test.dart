import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/settings/presentation/screens/subscription_settings_screen.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

void main() {
  SubscriptionBloc buildBloc() {
    return SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: FakeSubscriptionRepository(),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required SubscriptionBloc bloc,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SubscriptionBloc>.value(
          value: bloc,
          child: const SubscriptionSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('free users see upgrade action', (tester) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc: bloc);

    expect(find.text('Upgrade to Plus'), findsOneWidget);
    expect(
      find.text('Free Plan - Upgrade for unlimited likes'),
      findsOneWidget,
    );
    expect(find.text('Refresh subscription status'), findsNothing);
  });

  testWidgets('plus users see management action and renewal copy', (
    tester,
  ) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(
          tier: SubscriptionTier.plus,
          status: 'active',
          nextRenewal: DateTime(2026, 3, 1),
          cancelAtPeriodEnd: false,
        ),
      ),
    );

    await pumpScreen(tester, bloc: bloc);
    await tester.pump();

    expect(find.text('Refresh subscription status'), findsOneWidget);
    expect(find.textContaining('Plus Member - Renews on'), findsOneWidget);
    expect(find.text('Upgrade to Plus'), findsNothing);
  });
}
