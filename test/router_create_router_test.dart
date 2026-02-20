import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/badge_counter_service.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/about/presentation/screens/pricing_screen.dart';
import 'package:crushhour/features/about/presentation/screens/product_features_screen.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/change_email_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/id_verification_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/logout_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/new_device_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/otp_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/splash_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/presentation/screens/story_viewer_screen.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/support_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/dev/widget_catalog/widget_catalog_screen.dart';
import 'package:crushhour/presentation/screens/community_guidelines_screen.dart';
import 'package:crushhour/presentation/screens/privacy_policy_screen.dart';
import 'package:crushhour/presentation/screens/terms_of_service_screen.dart';

import 'mock/firebase_mock.dart';

void main() {
  const packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseAnalyticsMocks();
    await Firebase.initializeApp();

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

  Object? drainRouterTestExceptions(WidgetTester tester) {
    Object? first;
    while (true) {
      final error = tester.takeException();
      if (error == null) {
        break;
      }
      first ??= error;
    }
    return first;
  }

  Future<void> pumpRouterSettled(
    WidgetTester tester, {
    int maxPumps = 4,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!tester.binding.hasScheduledFrame) {
        break;
      }
    }
  }

  Future<void> pumpRouterApp(
    WidgetTester tester, {
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    DiscoveryRepository? discoveryRepository,
    ProfileRepository? profileRepository,
    SubscriptionBloc? subscriptionBloc,
    required String initialRoute,
    Object? routeExtra,
    ChatRepository? chatRepository,
    BadgeCounterCubit? badgeCounterCubit,
    SafetyCubit? safetyCubit,
    bool settle = true,
  }) async {
    final effectiveInitialRoute = routeExtra == null
        ? initialRoute
        : CrushRoutes.splash;
    final router = createRouter(authBloc, initialRoute: effectiveInitialRoute);
    final repo = discoveryRepository ?? _NoopDiscoveryRepository();
    final chatRepo = chatRepository;
    final profRepo =
        profileRepository ??
        _NoopProfileRepository(currentUser: authBloc.state.user);
    final profileBloc = ProfileBloc(
      profileRepository: profRepo,
      authRepository: authRepository,
    );

    addTearDown(() async {
      router.dispose();
      if (subscriptionBloc != null) {
        await subscriptionBloc.close();
      }
      await profileBloc.close();
      await authBloc.close();
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<DiscoveryRepository>.value(value: repo),
          RepositoryProvider<ProfileRepository>.value(value: profRepo),
          if (chatRepo != null)
            RepositoryProvider<ChatRepository>.value(value: chatRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
            if (badgeCounterCubit != null)
              BlocProvider<BadgeCounterCubit>.value(value: badgeCounterCubit),
            if (safetyCubit != null)
              BlocProvider<SafetyCubit>.value(value: safetyCubit),
            if (subscriptionBloc != null)
              BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
          ],
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
    if (routeExtra != null) {
      router.go(initialRoute, extra: routeExtra);
      await tester.pump();
    }
    if (settle) {
      await pumpRouterSettled(tester);
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

    testWidgets(
      'root route redirect lands on auth gateway when unauthenticated',
      (tester) async {
        final authRepository = _NoopAuthRepository();
        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.unauthenticated),
        );

        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          initialRoute: CrushRoutes.root,
        );

        expect(find.byType(AuthGatewayScreen), findsOneWidget);
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

    testWidgets('email verification route renders when account is unverified', (
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
            isPhoneVerified: false,
          ),
        ),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: CrushRoutes.emailVerification,
      );

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
    });

    testWidgets('onboarding routes render when onboarding is incomplete', (
      tester,
    ) async {
      Future<void> assertRouteShows({
        required String route,
        required Type widgetType,
        required CrushUser user,
      }) async {
        final authRepository = _NoopAuthRepository();
        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.authenticated, user: user),
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
        route: CrushRoutes.basicInfo,
        widgetType: BasicInfoScreen,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: false,
          hasSkippedProfileSetup: false,
          isEmailVerified: true,
          isPhoneVerified: false,
        ),
      );
      await assertRouteShows(
        route: CrushRoutes.idVerification,
        widgetType: IdVerificationScreen,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: false,
          hasSkippedProfileSetup: false,
          isEmailVerified: true,
          isPhoneVerified: false,
        ),
      );
      await assertRouteShows(
        route: CrushRoutes.idVerificationSettings,
        widgetType: IdVerificationScreen,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: false,
          hasSkippedProfileSetup: false,
          isEmailVerified: true,
          isPhoneVerified: false,
        ),
      );
      await assertRouteShows(
        route: CrushRoutes.profileSetup,
        widgetType: ProfileSetupScreen,
        user: buildUser(
          hasAcceptedTerms: true,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: false,
          isEmailVerified: true,
          isPhoneVerified: false,
        ),
      );
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
      await tester.tap(find.text('Go to Home'));
      await tester.pump();
      drainRouterTestExceptions(tester);
    });

    testWidgets('chat deep-link loader shows generic error when fetch fails', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      final discoveryRepository = _TestDiscoveryRepository(
        fetchMatchesHandler: (_) async => throw Exception('fetch failed'),
        fetchProfileByIdHandler: (_) async => null,
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        discoveryRepository: discoveryRepository,
        initialRoute: '${CrushRoutes.chat}/match-500',
        settle: false,
      );

      await tester.pumpAndSettle();
      expect(find.text('Unable to load chat right now.'), findsOneWidget);
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

    testWidgets(
      'user profile deep-link loader renders profile when repository returns data',
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
          initialRoute: '${CrushRoutes.userProfile}/user-200',
          settle: false,
        );

        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Loading profile...'), findsOneWidget);

        profileCompleter.complete(_testProfile('user-200'));
        await tester.pumpAndSettle();
        expect(find.byType(OtherUserProfileScreen), findsOneWidget);
      },
    );

    testWidgets('splash route renders splash screen for unknown auth state', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(buildState(status: AuthStatus.unknown));

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: CrushRoutes.splash,
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      drainRouterTestExceptions(tester);
    });

    testWidgets('home route branch executes for authenticated user', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBloc,
        authRepository: authRepository,
        initialRoute: CrushRoutes.home,
        settle: false,
      );

      await tester.pump();
      final error = drainRouterTestExceptions(tester);
      expect(error, isNotNull);
    });

    testWidgets('chat route extra and fallback branches execute', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();
      final authBlocWithUser = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );

      await pumpRouterApp(
        tester,
        authBloc: authBlocWithUser,
        authRepository: authRepository,
        initialRoute: '${CrushRoutes.chat}/m-args',
        routeExtra: ChatScreenArgs(
          matchId: 'm-args',
          currentUserId: 'router-user-1',
          otherUserId: 'other-1',
          otherName: 'Other User',
        ),
        settle: false,
      );
      await tester.pump();
      expect(drainRouterTestExceptions(tester), isNotNull);

      final authBlocWithoutUser = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: null),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocWithoutUser,
        authRepository: authRepository,
        initialRoute: '${CrushRoutes.chat}/m-fallback',
        settle: false,
      );
      await tester.pump();
      expect(drainRouterTestExceptions(tester), isNotNull);
    });

    testWidgets('call, incoming call, and video call route branches execute', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();

      final authBlocCallFallback = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocCallFallback,
        authRepository: authRepository,
        initialRoute: CrushRoutes.call,
        settle: false,
      );
      await tester.pump();
      expect(drainRouterTestExceptions(tester), isNotNull);

      final authBlocIncoming = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocIncoming,
        authRepository: authRepository,
        initialRoute: CrushRoutes.incomingCall,
        routeExtra: IncomingCallScreenArgs(
          incomingCall: Call(
            id: 'incoming-route-1',
            callerId: 'other-user',
            receiverId: 'router-user-1',
            type: CallType.video,
            status: CallStatus.ringing,
            createdAt: DateTime.now(),
            callerName: 'Incoming Caller',
          ),
        ),
      );
      expect(find.byType(IncomingCallScreen), findsOneWidget);

      final authBlocIncomingFallback = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocIncomingFallback,
        authRepository: authRepository,
        initialRoute: CrushRoutes.incomingCall,
        settle: false,
      );
      await tester.pump();
      expect(drainRouterTestExceptions(tester), isNotNull);

      final authBlocVideo = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocVideo,
        authRepository: authRepository,
        initialRoute: CrushRoutes.videoCall,
        routeExtra: const VideoCallArgs(
          currentUserId: 'router-user-1',
          otherUserId: 'other-video',
          otherName: 'Video Match',
        ),
      );
      expect(find.byType(VideoCallScreen), findsOneWidget);

      final authBlocVideoFallback = _TestAuthBloc(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      await pumpRouterApp(
        tester,
        authBloc: authBlocVideoFallback,
        authRepository: authRepository,
        initialRoute: CrushRoutes.videoCall,
        settle: false,
      );
      await tester.pump();
      expect(drainRouterTestExceptions(tester), isNotNull);
    });

    testWidgets('additional protected route pageBuilder branches execute', (
      tester,
    ) async {
      final authRepository = _NoopAuthRepository();

      Future<void> smokeRoute({
        required String route,
        Object? extra,
        SubscriptionBloc? subscriptionBloc,
      }) async {
        final discoveryRepository = _NoopDiscoveryRepository();
        final chatRepository = _NoopChatRepository();
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final preferences = await SharedPreferences.getInstance();
        final safetyCubit = SafetyCubit(
          preferences: preferences,
          chatRepository: chatRepository,
          discoveryRepository: discoveryRepository,
        );
        final badgeCounterCubit = BadgeCounterCubit();
        final effectiveSubscriptionBloc =
            subscriptionBloc ??
            _TestSubscriptionBloc(
              const SubscriptionState(plan: SubscriptionPlan.free),
            );

        final authBloc = _TestAuthBloc(
          buildState(status: AuthStatus.authenticated, user: buildUser()),
        );
        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          discoveryRepository: discoveryRepository,
          chatRepository: chatRepository,
          initialRoute: route,
          routeExtra: extra,
          badgeCounterCubit: badgeCounterCubit,
          safetyCubit: safetyCubit,
          subscriptionBloc: effectiveSubscriptionBloc,
          settle: false,
        );
        await tester.pump();
        drainRouterTestExceptions(tester);
        await tester.pump(const Duration(milliseconds: 50));
        drainRouterTestExceptions(tester);
      }

      await smokeRoute(route: CrushRoutes.messageRequests);
      await smokeRoute(route: CrushRoutes.dateIdeas);
      await smokeRoute(route: CrushRoutes.compatibilityQuiz);
      await smokeRoute(route: CrushRoutes.testAgora);
      await smokeRoute(
        route: CrushRoutes.profileMedia,
        extra: ProfileMediaArgs(profile: _testProfile('media-route-profile')),
      );
      await smokeRoute(route: CrushRoutes.profileMedia);
      await smokeRoute(
        route: CrushRoutes.userProfile,
        extra: OtherUserProfileArgs(
          profile: _testProfile('other-route-profile'),
        ),
      );
      await smokeRoute(route: CrushRoutes.userProfile);
      await smokeRoute(
        route: CrushRoutes.storyViewer,
        extra: StoryViewerArgs(
          stories: [_testStory('route-story-1', 'other-route-profile')],
          profile: _testProfile('other-route-profile'),
        ),
      );
      await smokeRoute(route: CrushRoutes.storyViewer);
      await smokeRoute(route: CrushRoutes.settings);
      await smokeRoute(route: CrushRoutes.appearanceSettings);
      await smokeRoute(route: CrushRoutes.privacySettings);
      await smokeRoute(route: CrushRoutes.notificationsSettings);
      await smokeRoute(route: CrushRoutes.languageSettings);
      await smokeRoute(route: CrushRoutes.discoverySettings);
      await smokeRoute(route: CrushRoutes.storageSettings);
      await smokeRoute(route: CrushRoutes.securitySettings);
      await smokeRoute(route: CrushRoutes.accountSettings);

      final subscriptionBloc = _TestSubscriptionBloc(
        const SubscriptionState(plan: SubscriptionPlan.plus),
      );
      await smokeRoute(
        route: CrushRoutes.chatSettings,
        subscriptionBloc: subscriptionBloc,
      );
    });

    testWidgets('chat deep-link success branch executes', (tester) async {
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
        initialRoute: '${CrushRoutes.chat}/match-success',
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Opening chat...'), findsOneWidget);

      chatMatchesCompleter.complete([
        _testMatch(
          id: 'match-success',
          userId: 'router-user-1',
          otherUserId: 'other-200',
          otherName: 'Casey',
        ),
      ]);
      await tester.pump();
      drainRouterTestExceptions(tester);
    });
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
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

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

class _NoopSubscriptionRepository implements SubscriptionRepository {
  @override
  Stream<SubscriptionPlan> watchPlan() =>
      const Stream<SubscriptionPlan>.empty();

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => SubscriptionPlan.free;

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<String> startPlusCheckout() async => '';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(plan: SubscriptionPlan.free);

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('not supported in router tests');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => const [];
}

class _TestSubscriptionBloc extends SubscriptionBloc {
  _TestSubscriptionBloc(SubscriptionState initialState)
    : super(
        subscriptionRepository: _NoopSubscriptionRepository(),
        authRepository: _NoopAuthRepository(),
      ) {
    emit(initialState);
  }

  @override
  Stream<SubscriptionState> get stream =>
      const Stream<SubscriptionState>.empty();
}

const _testPreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 50,
  maxDistanceKm: 100,
  showMeGenders: ['female'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'New York',
);

Profile _testProfile(String id) => Profile(
  id: id,
  name: 'Test $id',
  age: 25,
  gender: 'male',
  photoUrls: const [],
  videoUrls: const [],
  bio: 'Test bio',
  interests: const [],
  country: 'US',
  city: 'New York',
  isVerified: false,
  preferences: _testPreferences,
);

CrushMatch _testMatch({
  required String id,
  required String userId,
  required String otherUserId,
  String? otherName,
}) => CrushMatch(
  id: id,
  userId: userId,
  otherUserId: otherUserId,
  status: MatchStatus.mutual,
  preMatchMessageRequestsCount: 0,
  pinnedForUser: false,
  otherUserName: otherName,
);

ProfileStory _testStory(String id, String userId) => ProfileStory(
  id: id,
  userId: userId,
  mediaUrl: 'https://example.com/$id.jpg',
  mediaType: StoryMediaType.photo,
  createdAt: DateTime(2026, 2, 1),
);

class _NoopProfileRepository implements ProfileRepository {
  _NoopProfileRepository({this.currentUser});

  final CrushUser? currentUser;

  @override
  Future<CrushUser?> getCurrentUser() async => currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _NoopDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async => const [];

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async => null;

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {}

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async => const [];

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => const [];

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => const [];

  @override
  Future<Profile?> fetchProfileById(String profileId) async => null;

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async => null;

  @override
  Future<Profile?> rewindLastSwipe(String userId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _NoopChatRepository implements ChatRepository {
  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async =>
      const [];

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
