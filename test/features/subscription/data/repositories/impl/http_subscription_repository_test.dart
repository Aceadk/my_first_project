import 'dart:convert';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/http_subscription_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const apiConfig = ApiConfig(
    baseUrl: 'https://api.example.com',
    timeout: Duration(seconds: 1),
    retryCount: 0,
    retryDelay: Duration(milliseconds: 1),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('HttpSubscriptionRepository', () {
    test(
      'getCurrentPlan reads the live subscription current endpoint',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/subscription/current');
          return http.Response(
            jsonEncode(<String, dynamic>{'plan': 'plus'}),
            200,
          );
        });

        final repository = HttpSubscriptionRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final tier = await repository.getCurrentPlan();

        expect(tier, SubscriptionTier.plus);
        repository.dispose();
      },
    );

    test(
      'startCheckout posts a Stripe price id to the checkout endpoint',
      () async {
        final previousPlatform = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = previousPlatform;
        });

        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/subscription/checkout');
          expect(jsonDecode(request.body), <String, dynamic>{
            'price_id': 'price_plus_yearly',
            'success_url': 'https://crushhour.app/checkout/success',
            'cancel_url': 'https://crushhour.app/checkout/cancel',
          });
          return http.Response(
            jsonEncode(<String, dynamic>{
              'url': 'https://checkout.example.com/session',
            }),
            200,
          );
        });

        final repository = HttpSubscriptionRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final checkoutUrl = await repository.startCheckout(
          tier: SubscriptionTier.plus,
          period: BillingPeriod.yearly,
        );

        expect(checkoutUrl, 'https://checkout.example.com/session');
        repository.dispose();
      },
    );

    test(
      'local promo code redemption activates a local premium fallback',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{'error': 'unavailable'}),
            500,
          );
        });

        final repository = HttpSubscriptionRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final redemption = await repository.redeemPromoCode('crushfree');
        final tier = await repository.getCurrentPlan();
        final status = await repository.refreshStatus();

        expect(redemption.success, isTrue);
        expect(tier, SubscriptionTier.plus);
        expect(status.tier, SubscriptionTier.plus);
        expect(status.status, 'active');
        repository.dispose();
      },
    );

    test(
      'validatePromoCode uses the local fallback catalog without network support',
      () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount += 1;
          return http.Response('{}', 500);
        });

        final repository = HttpSubscriptionRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final promoCode = await repository.validatePromoCode('  welcome50 ');

        expect(promoCode, isNotNull);
        expect(promoCode!.code, 'WELCOME50');
        expect(requestCount, 0);
        repository.dispose();
      },
    );
  });
}
