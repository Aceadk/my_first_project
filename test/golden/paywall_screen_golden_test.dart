// Tagged `golden` and excluded from the cross-platform CI `flutter test` run:
// golden pixel-comparisons are not portable to the Linux CI runner. Run locally
// with a matched toolchain (`flutter test test/golden/`).
@Tags(['golden'])
library;

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
  testWidgets('paywall default state', (tester) async {
    final repository = _GoldenSubscriptionRepository();
    final bloc = SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: repository,
    );
    addTearDown(() async {
      await bloc.close();
      repository.dispose();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(430, 1900));

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
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/paywall_screen_default.png'),
    );
  });
}

class _GoldenSubscriptionRepository extends FakeSubscriptionRepository {
  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async => const [
    SubscriptionProduct(
      productId: 'plus_monthly',
      tier: SubscriptionTier.plus,
      period: BillingPeriod.monthly,
      title: 'Crush+ Monthly',
      description: 'Monthly premium access',
      priceLabel: '\$8.99',
      price: 8.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
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
    SubscriptionProduct(
      productId: 'platinum_monthly',
      tier: SubscriptionTier.platinum,
      period: BillingPeriod.monthly,
      title: 'Crush Platinum Monthly',
      description: 'Monthly platinum access',
      priceLabel: '\$17.99',
      price: 17.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    SubscriptionProduct(
      productId: 'platinum_quarterly',
      tier: SubscriptionTier.platinum,
      period: BillingPeriod.quarterly,
      title: 'Crush Platinum Quarterly',
      description: 'Quarterly platinum access',
      priceLabel: '\$44.99',
      price: 44.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    SubscriptionProduct(
      productId: 'platinum_yearly',
      tier: SubscriptionTier.platinum,
      period: BillingPeriod.yearly,
      title: 'Crush Platinum Yearly',
      description: 'Yearly platinum access',
      priceLabel: '\$129.99',
      price: 129.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
  ];
}
