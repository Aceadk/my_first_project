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
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:crushhour/features/calls/presentation/screens/call_history_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/discovery/data/services/story_service.dart';
import 'package:crushhour/features/discovery/domain/repositories/boost_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/screens/story_viewer_screen.dart';
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/support_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/social/domain/models/compatibility_quiz.dart';
import 'package:crushhour/features/social/domain/models/date_idea.dart';
import 'package:crushhour/features/social/domain/repositories/compatibility_quiz_repository.dart';
import 'package:crushhour/features/social/domain/repositories/date_idea_repository.dart';
import 'package:crushhour/features/social/presentation/bloc/compatibility_quiz_cubit.dart';
import 'package:crushhour/features/social/presentation/bloc/date_ideas_cubit.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/dev/widget_catalog/widget_catalog_screen.dart';
import 'package:crushhour/presentation/screens/community_guidelines_screen.dart';
import 'package:crushhour/presentation/screens/home_screen.dart';
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
    int maxPumps = 20,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!tester.binding.hasScheduledFrame) {
        break;
      }
    }
  }

  Future<void> disposePumpedTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 16));
    drainRouterTestExceptions(tester);
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
    bool lightweight = false,
    bool settle = true,
  }) async {
    final effectiveInitialRoute = routeExtra == null
        ? initialRoute
        : CrushRoutes.splash;
    final router = createRouter(authBloc, initialRoute: effectiveInitialRoute);

    if (lightweight) {
      addTearDown(() async {
        await disposePumpedTree(tester);
        router.dispose();
        await authBloc.close();
      });

      await tester.pumpWidget(
        RepositoryProvider<AuthRepository>.value(
          value: authRepository,
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
      if (routeExtra != null) {
        router.go(initialRoute, extra: routeExtra);
        await tester.pump();
      }
      if (settle) {
        await pumpRouterSettled(tester);
      }
      return;
    }

    final repo = discoveryRepository ?? _NoopDiscoveryRepository();
    final chatRepo = chatRepository ?? StubChatRepository();
    final profRepo =
        profileRepository ??
        _NoopProfileRepository(currentUser: authBloc.state.user);
    final validationRepo = ProfileValidationService();
    final callManagerRepository = _NoopCallManagerRepository();
    final storyRepository = _NoopStoryRepository();
    final boostRepository = _NoopBoostRepository();
    final dateIdeaRepository = _NoopDateIdeaRepository();
    final compatibilityQuizRepository = _NoopCompatibilityQuizRepository();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final effectiveBadgeCounterCubit = badgeCounterCubit ?? BadgeCounterCubit();
    final effectiveSafetyCubit =
        safetyCubit ??
        SafetyCubit(
          preferences: preferences,
          chatRepository: chatRepo,
          discoveryRepository: repo,
        );
    final effectiveSubscriptionBloc =
        subscriptionBloc ??
        _TestSubscriptionBloc(
          const SubscriptionState(plan: SubscriptionPlan.free),
        );
    final effectiveChatBloc = ChatBloc(
      chatRepository: chatRepo,
      subscriptionRepository: _NoopSubscriptionRepository(),
      authRepository: authRepository,
    );
    final createdBadgeCubit = badgeCounterCubit == null;
    final createdSafetyCubit = safetyCubit == null;
    final createdSubscriptionBloc = subscriptionBloc == null;
    final profileBloc = ProfileBloc(
      profileRepository: profRepo,
      authRepository: authRepository,
    );
    final discoveryBloc = DiscoveryBloc(
      discoveryRepository: repo,
      subscriptionRepository: _NoopSubscriptionRepository(),
      authRepository: authRepository,
      profileRepository: profRepo,
    );
    final discoverySettingsCubit = DiscoverySettingsCubit(
      preferences: preferences,
    );
    final boostCubit = BoostCubit(
      boostRepository: boostRepository,
      authRepository: authRepository,
    );
    final dateIdeasCubit = DateIdeasCubit(
      authRepository: authRepository,
      dateIdeaRepository: dateIdeaRepository,
    );
    final compatibilityQuizCubit = CompatibilityQuizCubit(
      authRepository: authRepository,
      quizRepository: compatibilityQuizRepository,
    );
    final notificationSettingsCubit = NotificationSettingsCubit(
      preferences: preferences,
    );
    final privacySettingsCubit = PrivacySettingsCubit(preferences: preferences);
    final storageSettingsCubit = StorageSettingsCubit(preferences: preferences);
    final themeCubit = ThemeCubit(
      preferences: preferences,
      authRepository: authRepository,
      profileRepository: profRepo,
    );
    final localeCubit = LocaleCubit(preferences: preferences);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 16));
      drainRouterTestExceptions(tester);
      router.dispose();
      if (createdSubscriptionBloc) {
        await effectiveSubscriptionBloc.close();
      }
      if (createdSafetyCubit) {
        await effectiveSafetyCubit.close();
      }
      if (createdBadgeCubit) {
        await effectiveBadgeCounterCubit.close();
      }
      await localeCubit.close();
      await themeCubit.close();
      await storageSettingsCubit.close();
      await privacySettingsCubit.close();
      await notificationSettingsCubit.close();
      await compatibilityQuizCubit.close();
      await dateIdeasCubit.close();
      await boostCubit.close();
      await discoverySettingsCubit.close();
      await discoveryBloc.close();
      await effectiveChatBloc.close();
      await profileBloc.close();
      storyRepository.dispose();
      callManagerRepository.dispose();
      await authBloc.close();
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<DiscoveryRepository>.value(value: repo),
          RepositoryProvider<ProfileRepository>.value(value: profRepo),
          RepositoryProvider<ChatRepository>.value(value: chatRepo),
          RepositoryProvider<CallManagerRepository>.value(
            value: callManagerRepository,
          ),
          RepositoryProvider<StoryRepository>.value(value: storyRepository),
          RepositoryProvider<BoostRepository>.value(value: boostRepository),
          RepositoryProvider<DateIdeaRepository>.value(
            value: dateIdeaRepository,
          ),
          RepositoryProvider<CompatibilityQuizRepository>.value(
            value: compatibilityQuizRepository,
          ),
          RepositoryProvider<ProfileValidationRepository>.value(
            value: validationRepo,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<DiscoverySettingsCubit>.value(
              value: discoverySettingsCubit,
            ),
            BlocProvider<BoostCubit>.value(value: boostCubit),
            BlocProvider<DateIdeasCubit>.value(value: dateIdeasCubit),
            BlocProvider<CompatibilityQuizCubit>.value(
              value: compatibilityQuizCubit,
            ),
            BlocProvider<NotificationSettingsCubit>.value(
              value: notificationSettingsCubit,
            ),
            BlocProvider<PrivacySettingsCubit>.value(
              value: privacySettingsCubit,
            ),
            BlocProvider<StorageSettingsCubit>.value(
              value: storageSettingsCubit,
            ),
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<BadgeCounterCubit>.value(
              value: effectiveBadgeCounterCubit,
            ),
            BlocProvider<SafetyCubit>.value(value: effectiveSafetyCubit),
            BlocProvider<SubscriptionBloc>.value(
              value: effectiveSubscriptionBloc,
            ),
            BlocProvider<ChatBloc>.value(value: effectiveChatBloc),
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
          lightweight: true,
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
        lightweight: true,
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
        lightweight: true,
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
        lightweight: true,
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
        lightweight: true,
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
        lightweight: true,
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
        lightweight: true,
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
          lightweight: true,
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
      drainRouterTestExceptions(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
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
      drainRouterTestExceptions(tester);
      expect(find.byType(ChatScreen), findsOneWidget);
      await disposePumpedTree(tester);

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
      drainRouterTestExceptions(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await disposePumpedTree(tester);
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
      drainRouterTestExceptions(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await disposePumpedTree(tester);

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
      await disposePumpedTree(tester);

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
      drainRouterTestExceptions(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await disposePumpedTree(tester);

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
      await disposePumpedTree(tester);

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
      drainRouterTestExceptions(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await disposePumpedTree(tester);
    });

    testWidgets('main app route page-builder branches execute', (tester) async {
      final authRepository = _NoopAuthRepository();
      final initialAuthState = buildState(
        status: AuthStatus.authenticated,
        user: buildUser(),
      );

      Future<void> assertRouteWidget({
        required String route,
        Type? widgetType,
        Object? extra,
      }) async {
        final authBloc = _TestAuthBloc(initialAuthState);
        await pumpRouterApp(
          tester,
          authBloc: authBloc,
          authRepository: authRepository,
          initialRoute: route,
          routeExtra: extra,
          settle: false,
        );
        await tester.pump();
        drainRouterTestExceptions(tester);
        if (widgetType != null) {
          expect(find.byType(widgetType), findsOneWidget);
        }
        await disposePumpedTree(tester);
      }

      await assertRouteWidget(
        route: CrushRoutes.call,
        extra: const CallScreenArgs(
          matchId: 'route-match-1',
          isVideoCall: true,
          matchName: 'Route Match',
          matchPhotoUrl: 'https://example.com/match.jpg',
        ),
      );
      await assertRouteWidget(
        route: CrushRoutes.callHistory,
        widgetType: CallHistoryScreen,
      );
      await assertRouteWidget(route: CrushRoutes.notificationCenter);
      await assertRouteWidget(route: CrushRoutes.likesYou);
      await assertRouteWidget(route: CrushRoutes.weeklyPicks);
      await assertRouteWidget(
        route: CrushRoutes.compatibilityQuiz,
        extra: const <String, String>{'matchId': 'route-quiz-1'},
      );
      await assertRouteWidget(route: CrushRoutes.profileInsights);
      await assertRouteWidget(
        route: CrushRoutes.profile,
        widgetType: ProfileViewScreen,
      );
      await assertRouteWidget(
        route: CrushRoutes.profileEdit,
        widgetType: ProfileEditScreen,
      );
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
        final chatRepository = StubChatRepository();
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
        await disposePumpedTree(tester);
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
      expect(drainRouterTestExceptions(tester), isNull);
      await pumpRouterSettled(tester, maxPumps: 30);
      drainRouterTestExceptions(tester);
      await disposePumpedTree(tester);
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

class _NoopCallManagerRepository implements CallManagerRepository {
  static const _stateStream = Stream<CallUIState>.empty();
  static const _callStream = Stream<Call>.empty();

  @override
  Stream<Call> get callStream => _callStream;

  @override
  Stream<CallUIState> get callStateStream => _stateStream;

  @override
  Stream<Call> get missedCallStream => _callStream;

  @override
  Call? get activeCall => null;

  @override
  bool get hasActiveCall => false;

  @override
  bool get isMuted => false;

  @override
  bool get isSpeakerOn => false;

  @override
  bool get isVideoEnabled => true;

  @override
  bool get isFrontCamera => true;

  @override
  Future<Call> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType type,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  }) async {
    return Call(
      id: 'noop-call',
      callerId: callerId,
      receiverId: receiverId,
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime(2026, 1, 1),
      callerName: callerName,
      receiverName: receiverName,
      callerPhotoUrl: callerPhotoUrl,
      receiverPhotoUrl: receiverPhotoUrl,
    );
  }

  @override
  Future<void> acceptCall({CallType? asType}) async {}

  @override
  Future<void> declineCall() async {}

  @override
  Future<void> endCall() async {}

  @override
  void toggleMute() {}

  @override
  void toggleSpeaker() {}

  @override
  void toggleVideo() {}

  @override
  void switchCamera() {}

  @override
  void handleIncomingCall(Call incomingCall) {}

  @override
  Future<List<Call>> getCallHistory(
    String userId, {
    int limit = 20,
    DateTime? before,
  }) async => const [];

  @override
  void dispose() {}
}

class _NoopBoostRepository implements BoostRepository {
  @override
  Future<BoostStatus> getBoostStatus(String userId) async =>
      const BoostStatus(canBoost: false, nextBoostAvailableAt: null);

  @override
  Future<BoostSession> activateBoost(String userId) async => BoostSession(
    startedAt: DateTime(2026, 1, 1),
    endsAt: DateTime(2026, 1, 1, 0, 30),
    isActive: true,
  );

  @override
  Future<List<BoostSession>> getBoostHistory(String userId) async => const [];
}

class _NoopDateIdeaRepository implements DateIdeaRepository {
  @override
  Stream<List<DateIdea>> get ideasStream =>
      const Stream<List<DateIdea>>.empty();

  @override
  List<DateIdea> get savedIdeas => const [];

  @override
  List<DateIdea> get suggestedIdeas => const [];

  @override
  List<DateIdea> getAllIdeas() => const [];

  @override
  List<DateIdea> getIdeasByCategory(DateCategory category) => const [];

  @override
  List<DateIdea> getIdeasForDateType(DateType type) => const [];

  @override
  List<DateIdea> getIdeasByBudget(DateCostLevel maxCost) => const [];

  @override
  List<DateIdea> getRandomSuggestions(int count) => const [];

  @override
  Future<List<DateIdea>> getPersonalizedSuggestions({
    DateType? dateType,
    DateCostLevel? maxBudget,
    List<DateCategory>? preferredCategories,
    Season? currentSeason,
    int count = 5,
  }) async => const [];

  @override
  Future<void> saveIdea(DateIdea idea) async {}

  @override
  Future<void> removeSavedIdea(String ideaId) async {}

  @override
  bool isIdeaSaved(String ideaId) => false;

  @override
  Future<void> sendIdeaToMatch({
    required String matchId,
    required DateIdea idea,
    String? personalMessage,
  }) async {}

  @override
  Season getCurrentSeason() => Season.spring;

  @override
  List<DateIdea> searchIdeas(String query) => const [];

  @override
  void clearUserData() {}

  @override
  void dispose() {}
}

class _NoopCompatibilityQuizRepository implements CompatibilityQuizRepository {
  static const _emptyQuizStream = Stream<CompatibilityQuiz>.empty();
  static const _emptyResultStream = Stream<QuizResult>.empty();

  @override
  Stream<CompatibilityQuiz> get quizStream => _emptyQuizStream;

  @override
  Stream<QuizResult> get resultStream => _emptyResultStream;

  @override
  List<CompatibilityQuiz> getAllQuizzes() => const [];

  @override
  CompatibilityQuiz? getQuiz(String quizId) => null;

  @override
  Future<CompatibilityQuiz> startQuiz({
    required String quizId,
    required String matchId,
  }) async {
    return const CompatibilityQuiz(
      id: 'basic_compatibility',
      title: 'Compatibility Quiz',
      description: 'Quick compatibility check',
      questions: [
        QuizQuestion(
          id: 'q1',
          question: 'Pick one',
          options: [QuizOption(id: 'o1', text: 'Option 1')],
        ),
      ],
    );
  }

  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  }) async {}

  @override
  Future<QuizResult> completeQuiz({
    required String quizId,
    required String matchId,
    required String user1Id,
    required String user2Id,
    required Map<String, String> user1Answers,
    required Map<String, String> user2Answers,
  }) async {
    return QuizResult(
      quizId: quizId,
      user1Id: user1Id,
      user2Id: user2Id,
      user1Answers: user1Answers,
      user2Answers: user2Answers,
      completedAt: DateTime(2026, 1, 1),
      overallScore: 0,
    );
  }

  @override
  QuizResult? getResult(String matchId, String quizId) => null;

  @override
  List<QuizResult> getAllResultsForMatch(String matchId) => const [];

  @override
  Future<void> inviteToQuiz({
    required String matchId,
    required String quizId,
    String? message,
  }) async {}

  @override
  void clearUserData() {}

  @override
  void dispose() {}
}

class _NoopStoryRepository implements StoryRepository {
  @override
  Stream<StoryUpdate> get storyUpdates => const Stream<StoryUpdate>.empty();

  @override
  void initialize() {}

  @override
  void dispose() {}

  @override
  List<ProfileStory> getStoriesForUser(String userId) => const [];

  @override
  bool hasActiveStories(String userId) => false;

  @override
  int getActiveStoryCount(String userId) => 0;

  @override
  Future<ProfileStory> addStory({
    required String userId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? thumbnailUrl,
    Duration? customDuration,
  }) async {
    return ProfileStory(
      id: 'story',
      userId: userId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime(2026, 1, 1),
      thumbnailUrl: thumbnailUrl,
    );
  }

  @override
  Future<void> removeStory({
    required String userId,
    required String storyId,
  }) async {}

  @override
  Future<void> viewStory({
    required String storyId,
    required String viewerId,
  }) async {}

  @override
  List<String> getUsersWithActiveStories() => const [];

  @override
  void forceCleanup() {}

  @override
  void addMockStories() {}
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
  }) async => [_testProfile('deck-$userId')];

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

class _TestDiscoveryRepository extends _NoopDiscoveryRepository {
  _TestDiscoveryRepository({
    required this.fetchMatchesHandler,
    required this.fetchProfileByIdHandler,
  });

  final Future<List<CrushMatch>> Function(String userId) fetchMatchesHandler;
  final Future<Profile?> Function(String profileId) fetchProfileByIdHandler;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async => [_testProfile('deck-$userId')];

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) {
    return fetchMatchesHandler(userId);
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) {
    return fetchProfileByIdHandler(profileId);
  }
}
