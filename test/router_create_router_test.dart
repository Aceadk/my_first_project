import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/about/presentation/screens/pricing_screen.dart';
import 'package:crushhour/features/about/presentation/screens/product_features_screen.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/change_email_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/logout_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/new_device_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/otp_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/support_screen.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/dev/widget_catalog/widget_catalog_screen.dart';
import 'package:crushhour/presentation/screens/community_guidelines_screen.dart';
import 'package:crushhour/presentation/screens/privacy_policy_screen.dart';
import 'package:crushhour/presentation/screens/terms_of_service_screen.dart';

void main() {
  const packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
          if (call.method == 'getAll') {
            return <String, dynamic>{
              'appName': 'CrushHour',
              'packageName': 'com.crushhour.app',
              'version': '1.0.0',
              'buildNumber': '1',
              'buildSignature': '',
              'installerStore': null,
            };
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  AuthState buildState({required AuthStatus status, CrushUser? user}) {
    return AuthState(
      status: status,
      user: user,
      phoneInProgress: null,
      emailInProgress: null,
      emailOtpIdentifier: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  CrushUser buildUser({
    bool hasAcceptedTerms = true,
    bool hasSkippedBasicInfo = true,
    bool hasSkippedProfileSetup = true,
    bool isEmailVerified = true,
    bool isPhoneVerified = false,
  }) {
    return CrushUser(
      id: 'router-user-1',
      phoneNumber: '+15555550123',
      email: 'router@example.com',
      username: 'router_user',
      isEmailVerified: isEmailVerified,
      profile: null,
      isPhoneVerified: isPhoneVerified,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
      hasAcceptedTerms: hasAcceptedTerms,
      hasSkippedBasicInfo: hasSkippedBasicInfo,
      hasSkippedProfileSetup: hasSkippedProfileSetup,
    );
  }

  Future<void> pumpRouterApp(
    WidgetTester tester, {
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    DiscoveryRepository? discoveryRepository,
    required String initialRoute,
    bool settle = true,
  }) async {
    final router = createRouter(authBloc, initialRoute: initialRoute);
    final repo = discoveryRepository ?? _NoopDiscoveryRepository();

    addTearDown(() async {
      router.dispose();
      await authBloc.close();
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<DiscoveryRepository>.value(value: repo),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );

    await tester.pump();
    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  group('createRouter', () {
    test(
      'uses splash by default and respects explicit initial route',
      () async {
        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.unauthenticated),
        );
        final defaultRouter = createRouter(authBloc);
        expect(
          defaultRouter.routeInformationProvider.value.uri.path,
          CrushRoutes.splash,
        );
        defaultRouter.dispose();

        final explicitRouter = createRouter(
          authBloc,
          initialRoute: CrushRoutes.login,
        );
        expect(
          explicitRouter.routeInformationProvider.value.uri.path,
          CrushRoutes.login,
        );
        explicitRouter.dispose();
        await authBloc.close();
      },
    );

    testWidgets('redirects unauthenticated protected initial route to auth', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.unauthenticated),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: CrushRoutes.home,
      );

      expect(find.byType(AuthGatewayScreen), findsOneWidget);
    });

    testWidgets('unmatched auth path uses error page builder', (tester) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.unauthenticated),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: '/auth/not-a-real-route',
      );

      expect(find.byType(AuthGatewayScreen), findsOneWidget);
    });

    testWidgets('auth sub-routes render expected screens', (tester) async {
      Future<void> assertRouteShows({
        required String route,
        required Type widgetType,
      }) async {
        final authRepository = _NoopAuthRepository();
        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.unauthenticated),
        );

        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          initialRoute: route,
        );

        expect(find.byType(widgetType), findsOneWidget);
      }

      await assertRouteShows(route: CrushRoutes.login, widgetType: LoginScreen);
      await assertRouteShows(
        route: CrushRoutes.signUp,
        widgetType: SignUpScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.forgotPassword,
        widgetType: ForgotPasswordScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.resetPassword,
        widgetType: ForgotPasswordScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.phoneAuth,
        widgetType: PhoneAuthScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.emailAuth,
        widgetType: EmailAuthScreen,
      );
    });

    testWidgets('otp route without phone query falls back to auth gateway', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.unauthenticated),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: CrushRoutes.otp,
      );

      expect(find.byType(AuthGatewayScreen), findsOneWidget);
      expect(find.byType(OtpScreen), findsNothing);
    });

    testWidgets('otp route with phone query renders OTP screen', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.unauthenticated),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: '${CrushRoutes.otp}?phone=15555550123',
      );

      expect(find.byType(OtpScreen), findsOneWidget);
      expect(find.byType(AuthGatewayScreen), findsNothing);
    });

    testWidgets('email protection query parsing route stays accessible', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(
          status: AuthStatus.authenticated,
          user: buildUser(
            hasAcceptedTerms: true,
            hasSkippedBasicInfo: true,
            hasSkippedProfileSetup: true,
            isEmailVerified: false,
            isPhoneVerified: true,
          ),
        ),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: '${CrushRoutes.emailProtection}?redirect=true',
      );

      expect(find.byType(EmailProtectionScreen), findsOneWidget);
    });

    testWidgets('authenticated non-onboarding routes render expected screens', (
      tester,
    ) async {
      Future<void> assertRouteShows({
        required String route,
        required Type widgetType,
        CrushUser? user,
      }) async {
        final authRepository = _NoopAuthRepository();
        final authBloc = _TestAuthBloc(
          buildState(
            status: AuthStatus.authenticated,
            user:
                user ??
                buildUser(
                  hasAcceptedTerms: true,
                  hasSkippedBasicInfo: true,
                  hasSkippedProfileSetup: true,
                  isEmailVerified: true,
                  isPhoneVerified: false,
                ),
          ),
        );

        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          initialRoute: route,
        );

        expect(find.byType(widgetType), findsOneWidget);
      }

      await assertRouteShows(
        route: CrushRoutes.phoneProtection,
        widgetType: PhoneProtectionScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.termsConditions,
        widgetType: TermsConditionsScreen,
        user: buildUser(
          hasAcceptedTerms: false,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: true,
          isEmailVerified: true,
          isPhoneVerified: false,
        ),
      );
      await assertRouteShows(
        route: CrushRoutes.changeEmail,
        widgetType: ChangeEmailScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.newDevice,
        widgetType: NewDeviceScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.logout,
        widgetType: LogoutScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.privacyPolicy,
        widgetType: PrivacyPolicyScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.termsOfService,
        widgetType: TermsOfServiceScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.communityGuidelines,
        widgetType: CommunityGuidelinesScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.safetyGuidelines,
        widgetType: CommunityGuidelinesScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.productFeatures,
        widgetType: ProductFeaturesScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.support,
        widgetType: SupportScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.pricing,
        widgetType: PricingScreen,
      );
      await assertRouteShows(
        route: CrushRoutes.widgetCatalog,
        widgetType: WidgetCatalogScreen,
      );
    });

    testWidgets('chat deep-link loader shows loading then not-found state', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      final chatMatchesCompleter = Completer<List<CrushMatch>>();
      final discoveryRepository = _TestDiscoveryRepository(
        fetchMatchesHandler: (_) => chatMatchesCompleter.future,
        fetchProfileByIdHandler: (_) async => null,
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        discoveryRepository: discoveryRepository,
        initialRoute: '${CrushRoutes.chat}/missing-match',
        settle: false,
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Opening chat...'), findsOneWidget);

      chatMatchesCompleter.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('Chat not found.'), findsOneWidget);
    });

    testWidgets(
      'user profile deep-link loader shows loading then error state',
      (tester) async {
        final authRepository = _NoopAuthRepository();
        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.authenticated, user: buildUser()),
        );
        final profileCompleter = Completer<Profile?>();
        final discoveryRepository = _TestDiscoveryRepository(
          fetchMatchesHandler: (_) async => const [],
          fetchProfileByIdHandler: (_) => profileCompleter.future,
        );

        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          discoveryRepository: discoveryRepository,
          initialRoute: '${CrushRoutes.userProfile}/user-404',
          settle: false,
        );

        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Loading profile...'), findsOneWidget);

        profileCompleter.complete(null);
        await tester.pumpAndSettle();
        expect(find.text('Profile not found.'), findsOneWidget);
      },
    );
  });
}

class _NoopAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authStateChanges) {
      return const Stream<CrushUser?>.empty();
    }
    if (invocation.memberName == #bootstrapSession) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc(AuthState initialState)
    : super(authRepository: _NoopAuthRepository()) {
    emit(initialState);
  }

  @override
  Stream<AuthState> get stream => const Stream<AuthState>.empty();
}

class _NoopDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];

  @override
  Future<Profile?> fetchProfileById(String profileId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _TestDiscoveryRepository implements DiscoveryRepository {
  _TestDiscoveryRepository({
    required this.fetchMatchesHandler,
    required this.fetchProfileByIdHandler,
  });

  final Future<List<CrushMatch>> Function(String userId) fetchMatchesHandler;
  final Future<Profile?> Function(String profileId) fetchProfileByIdHandler;

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) {
    return fetchMatchesHandler(userId);
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) {
    return fetchProfileByIdHandler(profileId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
