import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/screens/discovery_filters_settings_screen.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/stub_analytics_service.dart';

void main() {
  setUp(() {
    AnalyticsService.setInstance(StubAnalyticsService());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AnalyticsService.resetInstance();
  });

  testWidgets('free users are sent to the paywall from passport gating', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final discoverySettingsCubit = DiscoverySettingsCubit(
      preferences: preferences,
    );
    final subscriptionBloc = SubscriptionBloc(
      subscriptionRepository: _StubSubscriptionRepository(),
      authRepository: _NoopAuthRepository(),
    );
    addTearDown(discoverySettingsCubit.close);
    addTearDown(subscriptionBloc.close);

    final router = GoRouter(
      initialLocation: CrushRoutes.discoverySettings,
      routes: [
        GoRoute(
          path: CrushRoutes.discoverySettings,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<DiscoverySettingsCubit>.value(
                value: discoverySettingsCubit,
              ),
              BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
            ],
            child: const DiscoveryFiltersSettingsScreen(),
          ),
        ),
        GoRoute(
          path: CrushRoutes.paywall,
          builder: (context, state) =>
              const Scaffold(body: Text('Paywall Screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Upgrade to Plus').first);
    await tester.tap(find.text('Upgrade to Plus').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Paywall Screen'), findsOneWidget);
  });
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  @override
  Stream<SubscriptionTier> watchPlan() => const Stream.empty();

  @override
  Future<SubscriptionTier> getCurrentPlan() async => SubscriptionTier.free;

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {}

  @override
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  @override
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async => 'https://example.com';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(tier: SubscriptionTier.free, status: 'none');

  @override
  Future<SubscriptionStatus> restorePurchases() => refreshStatus();

  @override
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) => refreshStatus();

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async => const [];

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      const PromoCodeRedemptionResult(success: false, errorMessage: 'unused');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => const [];
}

class _NoopAuthRepository implements AuthRepository {
  static const _user = CrushUser(
    id: 'user-1',
    phoneNumber: '+10000000000',
    isEmailVerified: false,
    isPhoneVerified: true,
    isIdVerified: true,
    tier: SubscriptionTier.free,
  );

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => const Stream.empty();

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async => _user;

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async => _user;

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async => _user;

  @override
  Future<CrushUser> signInWithApple() async => _user;

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async => _user;

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async => 'token';

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => _user;

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> acceptTermsAndConditions() async => _user;

  @override
  Future<CrushUser?> refreshCurrentUser() async => _user;
}
