import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/widgets/promo_code_sheet.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/data/models/subscription.dart';

void main() {
  group('PromoCodeSheet', () {
    testWidgets(
      'UpperCaseTextFormatter uppercases text and preserves selection',
      (tester) async {
        final formatter = UpperCaseTextFormatter();
        const oldValue = TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 2),
        );
        const newValue = TextEditingValue(
          text: 'ab12z',
          selection: TextSelection.collapsed(offset: 5),
        );

        final formatted = formatter.formatEditUpdate(oldValue, newValue);

        expect(formatted.text, equals('AB12Z'));
        expect(formatted.selection.baseOffset, equals(5));
      },
    );

    testWidgets('validates code via submit and renders benefit preview', (
      tester,
    ) async {
      final repo = _TestSubscriptionRepository()
        ..validateResponse = const PromoCode(
          code: 'WELCOME50',
          type: PromoCodeType.discount,
          description: '50% off first month',
          discountPercent: 50,
        );

      await tester.pumpWidget(
        _buildTestApp(child: PromoCodeSheet(repository: repo)),
      );

      await tester.enterText(find.byType(EditableText), 'welcome50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repo.lastValidatedCode, equals('WELCOME50'));
      expect(find.text('Valid Code'), findsOneWidget);
      expect(find.text('50% off'), findsOneWidget);
      expect(find.text('50% off first month'), findsOneWidget);
    });

    testWidgets('shows invalid message when validation returns null', (
      tester,
    ) async {
      final repo = _TestSubscriptionRepository()..validateResponse = null;

      await tester.pumpWidget(
        _buildTestApp(child: PromoCodeSheet(repository: repo)),
      );

      await tester.enterText(find.byType(EditableText), 'notreal');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Invalid or expired promo code'), findsOneWidget);
    });

    testWidgets('redeem failure and exception paths show user-facing errors', (
      tester,
    ) async {
      final repo = _TestSubscriptionRepository()
        ..validateResponse = const PromoCode(
          code: 'ABC',
          type: PromoCodeType.discount,
          discountPercent: 10,
        )
        ..redeemResponse = PromoCodeRedemptionResult.failure('Redeem failed');

      await tester.pumpWidget(
        _buildTestApp(child: PromoCodeSheet(repository: repo)),
      );

      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();
      expect(find.text('Redeem failed'), findsOneWidget);

      repo.redeemError = StateError('network down');
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();
      expect(
        find.text('Failed to redeem code. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('successful redemption pops sheet with result', (tester) async {
      const promo = PromoCode(
        code: 'SUPERLOVE',
        type: PromoCodeType.bonusSuperLikes,
        bonusSuperLikes: 5,
      );
      final repo = _TestSubscriptionRepository()
        ..validateResponse = promo
        ..redeemResponse = PromoCodeRedemptionResult.success(
          promoCode: promo,
          appliedBenefits: const ['5 bonus Super Likes added'],
        );

      Future<PromoCodeRedemptionResult?>? resultFuture;
      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    resultFuture =
                        showModalBottomSheet<PromoCodeRedemptionResult>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PromoCodeSheet(repository: repo),
                        );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(PromoCodeSheet), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'superlove');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(find.byType(PromoCodeSheet), findsNothing);
      final result = await resultFuture;
      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.promoCode?.code, equals('SUPERLOVE'));
      expect(repo.lastRedeemedCode, equals('SUPERLOVE'));
    });
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _TestSubscriptionRepository implements SubscriptionRepository {
  PromoCode? validateResponse;
  Object? validateError;
  PromoCodeRedemptionResult redeemResponse = PromoCodeRedemptionResult.failure(
    'not configured',
  );
  Object? redeemError;
  String? lastValidatedCode;
  String? lastRedeemedCode;

  @override
  Stream<SubscriptionTier> watchPlan() => const Stream.empty();

  @override
  Future<SubscriptionTier> getCurrentPlan() async => SubscriptionTier.free;

  @override
  Future<void> purchaseSubscription({required SubscriptionTier tier, required BillingPeriod period}) async {}

  @override
  Future<String> startCheckout({required SubscriptionTier tier, required BillingPeriod period}) async => 'https://example.com';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(tier: SubscriptionTier.free, status: 'none');

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    lastValidatedCode = code.trim().toUpperCase();
    if (validateError != null) {
      throw validateError!;
    }
    return validateResponse;
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    lastRedeemedCode = code.trim().toUpperCase();
    if (redeemError != null) {
      throw redeemError!;
    }
    return redeemResponse;
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => const [];
}
