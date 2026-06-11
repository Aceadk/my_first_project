import 'dart:async';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required SubscriptionBloc bloc,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SubscriptionBloc>.value(
          value: bloc,
          child: const PaywallScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('paywall shows restore action for public purchase recovery', (
    tester,
  ) async {
    final repository = _ControlledSubscriptionRepository(
      onRefreshStatus: () async =>
          SubscriptionStatus(tier: SubscriptionTier.free, status: 'none'),
      onFetchAvailableProducts: () async => const [
        SubscriptionProduct(
          productId: 'plus_quarterly',
          tier: SubscriptionTier.plus,
          period: BillingPeriod.quarterly,
          title: 'Crush+ Quarterly',
          description: 'Quarterly premium access',
          priceLabel: '\$21.49',
          price: 21.49,
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
        SubscriptionProduct(
          productId: 'plus_yearly',
          tier: SubscriptionTier.plus,
          period: BillingPeriod.yearly,
          title: 'Crush+ Yearly',
          description: 'Yearly premium access',
          priceLabel: '\$71.49',
          price: 71.49,
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
      ],
    );
    final bloc = SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: repository,
    );
    addTearDown(() async {
      await bloc.close();
      repository.dispose();
    });

    await pumpScreen(tester, bloc: bloc);

    await tester.scrollUntilVisible(
      find.byKey(const Key('paywall_restore_button')),
      300,
    );

    expect(find.byKey(const Key('paywall_restore_button')), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });

  testWidgets('paywall shows comparison grid and legal links', (tester) async {
    final repository = _ControlledSubscriptionRepository(
      onRefreshStatus: () async =>
          SubscriptionStatus(tier: SubscriptionTier.free, status: 'none'),
    );
    final bloc = SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: repository,
    );
    addTearDown(() async {
      await bloc.close();
      repository.dispose();
    });

    await pumpScreen(tester, bloc: bloc);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Compare premium features'), 300);
    expect(find.text('Compare premium features'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('paywall_terms_button')),
      300,
    );

    expect(find.byKey(const Key('paywall_terms_button')), findsOneWidget);
    expect(find.byKey(const Key('paywall_privacy_button')), findsOneWidget);
  });

  testWidgets('paywall updates the CTA price when the billing period changes', (
    tester,
  ) async {
    final repository = _ControlledSubscriptionRepository(
      onRefreshStatus: () async =>
          SubscriptionStatus(tier: SubscriptionTier.free, status: 'none'),
      onFetchAvailableProducts: () async => const [
        SubscriptionProduct(
          productId: 'plus_quarterly',
          tier: SubscriptionTier.plus,
          period: BillingPeriod.quarterly,
          title: 'Crush+ Quarterly',
          description: 'Quarterly premium access',
          priceLabel: '\$21.49',
          price: 21.49,
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
        SubscriptionProduct(
          productId: 'plus_yearly',
          tier: SubscriptionTier.plus,
          period: BillingPeriod.yearly,
          title: 'Crush+ Yearly',
          description: 'Yearly premium access',
          priceLabel: '\$71.49',
          price: 71.49,
          currencyCode: 'USD',
          currencySymbol: '\$',
        ),
      ],
    );
    final bloc = SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: repository,
    );
    addTearDown(() async {
      await bloc.close();
      repository.dispose();
    });

    await pumpScreen(tester, bloc: bloc);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(FilledButton), 300);

    String ctaLabel() {
      final textWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Text),
        ),
      );
      return textWidget.data ?? '';
    }

    expect(ctaLabel(), contains('Get Crush+ for'));
    expect(ctaLabel(), contains('21.49'));

    await tester.tap(find.text('12 Months'));
    await tester.pumpAndSettle();

    expect(ctaLabel(), contains('71.49'));
  });

  testWidgets(
    'paywall restore action shows loading then no-purchase feedback',
    (tester) async {
      final restoreCompleter = Completer<SubscriptionStatus>();
      final repository = _ControlledSubscriptionRepository(
        onRefreshStatus: () => restoreCompleter.future,
      );
      final bloc = SubscriptionBloc(
        authRepository: FakeAuthRepository(),
        subscriptionRepository: repository,
      );
      addTearDown(() async {
        await bloc.close();
        repository.dispose();
      });

      await pumpScreen(tester, bloc: bloc);

      await tester.scrollUntilVisible(
        find.byKey(const Key('paywall_restore_button')),
        300,
      );

      await tester.tap(find.byKey(const Key('paywall_restore_button')));
      await tester.pump();

      expect(find.byKey(const Key('paywall_restore_loading')), findsOneWidget);

      restoreCompleter.complete(
        SubscriptionStatus(tier: SubscriptionTier.free, status: 'none'),
      );
      await tester.pumpAndSettle();

      expect(find.text('No purchases found to restore.'), findsOneWidget);
    },
  );
}

class _ControlledSubscriptionRepository extends FakeSubscriptionRepository {
  _ControlledSubscriptionRepository({
    required this.onRefreshStatus,
    this.onFetchAvailableProducts,
  });

  final Future<SubscriptionStatus> Function() onRefreshStatus;
  final Future<List<SubscriptionProduct>> Function()? onFetchAvailableProducts;

  @override
  Future<SubscriptionStatus> refreshStatus() {
    return onRefreshStatus();
  }

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async {
    return onFetchAvailableProducts?.call() ?? super.fetchAvailableProducts();
  }
}
