import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/di.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/features/auth/data/repositories/impl/http_auth_repository.dart';
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/http_call_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/stub_call_repository.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/http_chat_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/http_discovery_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_boost_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/boost_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/feature_flags/data/repositories/impl/stub_feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/domain/repositories/feature_flag_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/http_profile_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/http_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/stub_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  group('CrushDI', () {
    late TargetPlatform? previousPlatform;

    setUp(() {
      previousPlatform = debugDefaultTargetPlatformOverride;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
      CrushDI.dispose();
      CrushDI.resetBackendModeForTesting();
    });

    test('apiClient is cached and recreated after dispose', () {
      final first = CrushDI.apiClient;
      final second = CrushDI.apiClient;

      expect(identical(first, second), isTrue);

      CrushDI.dispose();

      final third = CrushDI.apiClient;
      expect(identical(first, third), isFalse);
      expect(third, isA<ApiClient>());
    });

    testWidgets(
      'buildRepositories resolves stub implementations in stub mode',
      (tester) async {
        CrushDI.setBackendModeForTesting(BackendMode.stub);

        AuthRepository? authRepository;
        ProfileRepository? profileRepository;
        SubscriptionRepository? subscriptionRepository;
        DiscoveryRepository? discoveryRepository;
        ChatRepository? chatRepository;
        CallRepository? callRepository;
        CallManagerRepository? callManagerRepository;
        FeatureFlagRepository? featureFlagRepository;
        BoostRepository? boostRepository;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiRepositoryProvider(
              providers: CrushDI.buildRepositories(),
              child: Builder(
                builder: (context) {
                  authRepository = context.read<AuthRepository>();
                  profileRepository = context.read<ProfileRepository>();
                  subscriptionRepository = context
                      .read<SubscriptionRepository>();
                  discoveryRepository = context.read<DiscoveryRepository>();
                  chatRepository = context.read<ChatRepository>();
                  callRepository = context.read<CallRepository>();
                  callManagerRepository = context.read<CallManagerRepository>();
                  featureFlagRepository = context.read<FeatureFlagRepository>();
                  boostRepository = context.read<BoostRepository>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(authRepository, isA<StubAuthRepository>());
        expect(profileRepository, isA<StubProfileRepository>());
        expect(subscriptionRepository, isA<StubSubscriptionRepository>());
        expect(discoveryRepository, isA<StubDiscoveryRepository>());
        expect(chatRepository, isA<StubChatRepository>());
        expect(callRepository, isA<StubCallRepository>());
        expect(callManagerRepository, same(CallService.instance));
        expect(featureFlagRepository, isA<StubFeatureFlagRepository>());
        expect(boostRepository, isA<StubBoostRepository>());
      },
    );

    testWidgets(
      'buildRepositories resolves http implementations in http mode',
      (tester) async {
        CrushDI.setBackendModeForTesting(BackendMode.http);

        AuthRepository? authRepository;
        ProfileRepository? profileRepository;
        SubscriptionRepository? subscriptionRepository;
        DiscoveryRepository? discoveryRepository;
        ChatRepository? chatRepository;
        CallRepository? callRepository;
        CallManagerRepository? callManagerRepository;
        FeatureFlagRepository? featureFlagRepository;
        BoostRepository? boostRepository;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiRepositoryProvider(
              providers: CrushDI.buildRepositories(),
              child: Builder(
                builder: (context) {
                  authRepository = context.read<AuthRepository>();
                  profileRepository = context.read<ProfileRepository>();
                  subscriptionRepository = context
                      .read<SubscriptionRepository>();
                  discoveryRepository = context.read<DiscoveryRepository>();
                  chatRepository = context.read<ChatRepository>();
                  callRepository = context.read<CallRepository>();
                  callManagerRepository = context.read<CallManagerRepository>();
                  featureFlagRepository = context.read<FeatureFlagRepository>();
                  boostRepository = context.read<BoostRepository>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(authRepository, isA<HttpAuthRepository>());
        expect(profileRepository, isA<HttpProfileRepository>());
        expect(subscriptionRepository, isA<HttpSubscriptionRepository>());
        expect(discoveryRepository, isA<HttpDiscoveryRepository>());
        expect(chatRepository, isA<HttpChatRepository>());
        expect(callRepository, isA<HttpCallRepository>());
        expect(callManagerRepository, same(CallService.instance));
        expect(featureFlagRepository, isA<StubFeatureFlagRepository>());
        expect(boostRepository, isA<StubBoostRepository>());
      },
    );

    test('backend mode can be overridden and reset for tests', () {
      expect(CrushDI.backendMode, BackendMode.firebase);

      CrushDI.setBackendModeForTesting(BackendMode.stub);
      expect(CrushDI.backendMode, BackendMode.stub);

      CrushDI.resetBackendModeForTesting();
      expect(CrushDI.backendMode, BackendMode.firebase);
    });

    test(
      'initializePlatformServices primes native billing on mobile Firebase',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final billingService = _FakeNativeBillingService();
        CrushDI.setBackendModeForTesting(BackendMode.firebase);
        CrushDI.setNativeBillingServiceForTesting(billingService);

        await CrushDI.initializePlatformServices();

        expect(billingService.initializeCalls, 1);
      },
    );

    test(
      'initializePlatformServices skips non-mobile or non-Firebase modes',
      () async {
        final billingService = _FakeNativeBillingService();
        CrushDI.setNativeBillingServiceForTesting(billingService);

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        CrushDI.setBackendModeForTesting(BackendMode.stub);
        await CrushDI.initializePlatformServices();

        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        CrushDI.setBackendModeForTesting(BackendMode.firebase);
        await CrushDI.initializePlatformServices();

        expect(billingService.initializeCalls, 0);
      },
    );
  });
}

class _FakeNativeBillingService implements NativeBillingService {
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async =>
      const [];

  @override
  Future<NativeSubscriptionPurchase> purchaseProduct({
    required String productId,
  }) async => throw UnimplementedError();

  @override
  Future<List<NativeSubscriptionPurchase>> restorePurchases() async => const [];

  @override
  Future<NativeSubscriptionPurchase> purchaseSubscription({
    required String productId,
  }) => purchaseProduct(productId: productId);

  @override
  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases() =>
      restorePurchases();

  @override
  Future<NativeSubscriptionPurchase> verifyPurchase(
    PurchaseDetails purchase,
  ) async => throw UnimplementedError();

  @override
  void dispose() {}
}
