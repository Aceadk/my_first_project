import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/dev/widget_catalog/widget_catalog_screen.dart';
import 'router_refresh_stream.dart';
import 'performance/performance_observer.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/splash_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/otp_screen.dart';
import '../presentation/screens/home_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/change_email_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/new_device_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/id_verification_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/chat/presentation/screens/message_requests_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/features/calls/presentation/screens/video_call_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/logout_screen.dart';
import '../presentation/screens/safety_screen.dart';
import '../presentation/screens/community_guidelines_screen.dart';
import '../presentation/screens/test/test_video_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_media_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/settings_screen.dart' as settings;
import 'package:crushhour/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/language_region_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/discovery_filters_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/data_storage_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/account_security_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/account_actions_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/chat_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/chat_settings_cubit.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/discovery/presentation/screens/likes_you_screen.dart';
import 'package:crushhour/features/discovery/presentation/screens/weekly_picks_screen.dart';
import 'package:crushhour/features/discovery/presentation/screens/story_viewer_screen.dart';
import 'package:crushhour/features/social/presentation/screens/date_ideas_screen.dart';
import 'package:crushhour/features/social/presentation/screens/compatibility_quiz_screen.dart';
import 'package:crushhour/features/analytics/presentation/screens/profile_insights_screen.dart';
import '../presentation/screens/privacy_policy_screen.dart';
import '../presentation/screens/terms_of_service_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/terms_conditions_screen.dart';

class CrushRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const authGateway = '/auth';
  static const login = '/auth/login';
  static const signUp = '/auth/signup';
  static const forgotPassword = '/auth/forgot';
  static const otp = '/auth/otp';
  static const resetPassword = '/auth/reset';
  static const phoneAuth = '/auth/phone';
  static const emailAuth = '/auth/email';
  static const emailVerification = '/email-verification';
  static const emailProtection = '/email-protection';
  static const phoneProtection = '/phone-protection';
  static const changeEmail = '/change-email';
  static const newDevice = '/new-device';
  static const basicInfo = '/basic-info';
  static const idVerification = '/id-verification';
  static const idVerificationSettings = '/settings/id-verification';
  static const profileSetup = '/profile-setup';
  static const termsConditions = '/terms-conditions';
  static const home = '/home';
  static const chat = '/chat';
  static const messageRequests = '/message-requests';
  static const call = '/call';
  static const videoCall = '/video-call';
  static const logout = '/logout';
  static const safety = '/safety';
  static const safetyGuidelines = '/safety-guidelines';
  static const testAgora = '/test-agora';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileMedia = '/profile/media';
  static const storyViewer = '/story-viewer';
  static const userProfile = '/user-profile';
  static const settings = '/settings';
  static const privacySettings = '/settings/privacy';
  static const notificationsSettings = '/settings/notifications';
  static const languageSettings = '/settings/language';
  static const discoverySettings = '/settings/discovery';
  static const storageSettings = '/settings/storage';
  static const securitySettings = '/settings/security';
  static const accountSettings = '/settings/account';
  static const chatSettings = '/settings/chat';
  static const widgetCatalog = '/dev/widget-catalog';
  static const likesYou = '/likes-you';
  static const weeklyPicks = '/weekly-picks';
  static const dateIdeas = '/date-ideas';
  static const compatibilityQuiz = '/compatibility-quiz';
  static const profileInsights = '/profile-insights';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: CrushRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    observers: [
      PerformanceNavigatorObserver(
        nameExtractor: (route) => route?.settings.name ?? 'unknown',
      ),
    ],
    redirect: (context, state) {
      final status = authBloc.state.status;
      final user = authBloc.state.user;
      final isLoggedIn = status == AuthStatus.authenticated;
      final isUnknown = status == AuthStatus.unknown;
      final path = state.uri.path;
      final isAuthRoute = path.startsWith(CrushRoutes.authGateway);
      final isSplash = path == CrushRoutes.splash;
      final isEmailVerificationRoute = path == CrushRoutes.emailVerification;
      final isTermsRoute = path == CrushRoutes.termsConditions;
      final isProfileRoute =
          path == CrushRoutes.profile || path == CrushRoutes.profileMedia;
      final isProfileEditRoute = path == CrushRoutes.profileEdit;
      final isSettingsRoute = path.startsWith(CrushRoutes.settings);
      final isOnboardingRoute = path == CrushRoutes.basicInfo ||
          path == CrushRoutes.profileSetup ||
          path == CrushRoutes.idVerification ||
          path == CrushRoutes.termsConditions;

      // Legal/public routes that should always be accessible during onboarding
      final isPublicRoute = path == CrushRoutes.privacyPolicy ||
          path == CrushRoutes.termsOfService ||
          path == CrushRoutes.safetyGuidelines ||
          path == CrushRoutes.weeklyPicks ||
          path == CrushRoutes.safety ||
          path == CrushRoutes.logout;

      // Check if user needs account verification
      // Only require verification for users who have neither email nor phone verified
      // Users with phone verification can skip email verification
      final needsAccountVerification = isLoggedIn &&
          user != null &&
          !user.isAccountVerified;

      // Check if user needs to accept terms and conditions
      final needsTermsAcceptance = isLoggedIn &&
          user != null &&
          !user.hasAcceptedTerms;

      // Check if user needs to complete basic info (after T&C)
      final needsBasicInfo = isLoggedIn &&
          user != null &&
          user.hasAcceptedTerms &&
          !user.hasCompletedBasicInfo;

      // Check if user needs to complete profile setup (after basic info)
      final needsProfileSetup = isLoggedIn &&
          user != null &&
          user.hasAcceptedTerms &&
          user.hasCompletedBasicInfo &&
          !user.hasCompletedProfileSetup;

      // While auth status is unknown, stay on splash screen
      // Don't redirect - let the splash screen handle navigation via BlocListener
      if (isUnknown) {
        if (!isSplash) {
          return CrushRoutes.splash;
        }
        return null;
      }

      // Auth status is known - redirect away from splash
      if (isSplash) {
        if (isLoggedIn) {
          // Check onboarding steps in order
          if (needsTermsAcceptance) {
            return CrushRoutes.termsConditions;
          }
          if (needsBasicInfo) {
            return CrushRoutes.basicInfo;
          }
          if (needsProfileSetup) {
            return CrushRoutes.profileSetup;
          }
          // Check if email verification is needed
          if (needsAccountVerification) {
            return CrushRoutes.emailVerification;
          }
          return CrushRoutes.home;
        }
        return CrushRoutes.authGateway;
      }

      // Not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        return CrushRoutes.authGateway;
      }

      // Logged in but needs to accept terms
      if (needsTermsAcceptance) {
        // Allow staying on terms screen or accessing public routes
        if (isTermsRoute || isPublicRoute) {
          return null;
        }
        // Redirect to terms screen from any other protected route
        if (!isAuthRoute) {
          return CrushRoutes.termsConditions;
        }
      }

      // Logged in but needs to complete basic info
      if (needsBasicInfo) {
        // Allow staying on basic info, proceeding to next onboarding steps,
        // or accessing public/legal routes
        if (path == CrushRoutes.basicInfo ||
            path == CrushRoutes.idVerification ||
            path == CrushRoutes.profileSetup ||
            isProfileRoute ||
            isProfileEditRoute ||
            isSettingsRoute ||
            isPublicRoute) {
          return null;
        }
        // Redirect to basic info from any other protected route
        if (!isAuthRoute && !isTermsRoute) {
          return CrushRoutes.basicInfo;
        }
      }

      // Logged in but needs to complete profile setup
      if (needsProfileSetup) {
        // Allow staying on profile setup, ID verification,
        // or accessing public/legal routes
        if (path == CrushRoutes.profileSetup ||
            path == CrushRoutes.idVerification ||
            isProfileRoute ||
            isProfileEditRoute ||
            isSettingsRoute ||
            isPublicRoute) {
          return null;
        }
        // Redirect to profile setup from any other protected route (including earlier onboarding steps)
        if (!isAuthRoute) {
          return CrushRoutes.profileSetup;
        }
      }

      // Logged in but needs email verification (after completing onboarding)
      if (needsAccountVerification && !needsTermsAcceptance && !needsBasicInfo && !needsProfileSetup) {
        // Allow staying on verification screen, onboarding routes, settings,
        // or accessing public/legal routes
        if (isEmailVerificationRoute ||
            isOnboardingRoute ||
            isSettingsRoute ||
            isPublicRoute) {
          return null;
        }
        // Redirect to verification screen from any other protected route
        if (!isAuthRoute) {
          return CrushRoutes.emailVerification;
        }
      }

      // Logged in with completed onboarding - redirect away from auth/onboarding routes
      if (isLoggedIn && !needsTermsAcceptance && !needsBasicInfo && !needsProfileSetup && !needsAccountVerification) {
        if (isAuthRoute || isEmailVerificationRoute || isOnboardingRoute) {
          return CrushRoutes.home;
        }
      }

      // Root path redirect
      if (path == CrushRoutes.root) {
        if (isLoggedIn) {
          if (needsTermsAcceptance) {
            return CrushRoutes.termsConditions;
          }
          if (needsBasicInfo) {
            return CrushRoutes.basicInfo;
          }
          if (needsProfileSetup) {
            return CrushRoutes.profileSetup;
          }
          if (needsAccountVerification) {
            return CrushRoutes.emailVerification;
          }
          return CrushRoutes.home;
        }
        return CrushRoutes.authGateway;
      }

      return null;
    },
    errorPageBuilder: (context, state) {
      return _buildPage(state, const AuthGatewayScreen());
    },
    routes: [
      GoRoute(
        path: CrushRoutes.root,
        redirect: (context, state) => CrushRoutes.splash,
      ),
      GoRoute(
        path: CrushRoutes.splash,
        pageBuilder: (context, state) =>
            _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: CrushRoutes.authGateway,
        pageBuilder: (context, state) =>
            _buildPage(state, const AuthGatewayScreen()),
        routes: [
          GoRoute(
            path: 'login',
            pageBuilder: (context, state) =>
                _buildPage(state, const LoginScreen()),
          ),
          GoRoute(
            path: 'signup',
            pageBuilder: (context, state) =>
                _buildPage(state, const SignUpScreen()),
          ),
          GoRoute(
            path: 'forgot',
            pageBuilder: (context, state) =>
                _buildPage(state, const ForgotPasswordScreen()),
          ),
          GoRoute(
            path: 'otp',
            pageBuilder: (context, state) {
              final phone = state.uri.queryParameters['phone'];
              if (phone == null || phone.isEmpty) {
                return _buildPage(state, const AuthGatewayScreen());
              }
              return _buildPage(state, OtpScreen(phoneNumber: phone));
            },
          ),
          GoRoute(
            path: 'reset',
            pageBuilder: (context, state) =>
                _buildPage(state, const ForgotPasswordScreen()),
          ),
          GoRoute(
            path: 'phone',
            pageBuilder: (context, state) =>
                _buildPage(state, const PhoneAuthScreen()),
          ),
          GoRoute(
            path: 'email',
            pageBuilder: (context, state) =>
                _buildPage(state, const EmailAuthScreen()),
          ),
        ],
      ),
      GoRoute(
        path: CrushRoutes.emailVerification,
        pageBuilder: (context, state) =>
            _buildPage(state, const EmailVerificationScreen()),
      ),
      GoRoute(
        path: CrushRoutes.emailProtection,
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final redirectOnSuccess = redirect == '1' || redirect == 'true';
          return _buildPage(
            state,
            EmailProtectionScreen(redirectOnSuccess: redirectOnSuccess),
          );
        },
      ),
      GoRoute(
        path: CrushRoutes.phoneProtection,
        pageBuilder: (context, state) =>
            _buildPage(state, const PhoneProtectionScreen()),
      ),
      GoRoute(
        path: CrushRoutes.changeEmail,
        pageBuilder: (context, state) =>
            _buildPage(state, const ChangeEmailScreen()),
      ),
      GoRoute(
        path: CrushRoutes.newDevice,
        pageBuilder: (context, state) =>
            _buildPage(state, const NewDeviceScreen()),
      ),
      GoRoute(
        path: CrushRoutes.basicInfo,
        pageBuilder: (context, state) =>
            _buildPage(state, const BasicInfoScreen()),
      ),
      GoRoute(
        path: CrushRoutes.termsConditions,
        pageBuilder: (context, state) =>
            _buildPage(state, const TermsConditionsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.idVerification,
        pageBuilder: (context, state) =>
            _buildPage(state, const IdVerificationScreen()),
      ),
      GoRoute(
        path: CrushRoutes.idVerificationSettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const IdVerificationScreen(fromSettings: true)),
      ),
      GoRoute(
        path: CrushRoutes.profileSetup,
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: CrushRoutes.home,
        pageBuilder: (context, state) =>
            _buildPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '${CrushRoutes.chat}/:matchId',
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is ChatScreenArgs) {
            return _buildPage(state, ChatScreen(args: args));
          }
          // Fallback if no args provided - go back home
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.messageRequests,
        pageBuilder: (context, state) =>
            _buildPage(state, const MessageRequestsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.call,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is CallScreenArgs) {
            return _buildPage(
              state,
              CallScreen(
                matchId: args.matchId,
                isVideoCall: args.isVideoCall,
                matchName: args.matchName,
                matchPhotoUrl: args.matchPhotoUrl,
              ),
            );
          }
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.videoCall,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is VideoCallArgs) {
            return _buildPage(
              state,
              VideoCallScreen(
                currentUserId: args.currentUserId,
                otherUserId: args.otherUserId,
                otherName: args.otherName,
              ),
            );
          }
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.logout,
        pageBuilder: (context, state) =>
            _buildPage(state, const LogoutScreen()),
      ),
      GoRoute(
        path: CrushRoutes.safety,
        pageBuilder: (context, state) =>
            _buildPage(state, const SafetyScreen()),
      ),
      GoRoute(
        path: CrushRoutes.likesYou,
        pageBuilder: (context, state) =>
            _buildPage(state, const LikesYouScreen()),
      ),
      GoRoute(
        path: CrushRoutes.weeklyPicks,
        pageBuilder: (context, state) {
          final userId = authBloc.state.user?.id ?? '';
          return _buildPage(state, WeeklyPicksScreen(userId: userId));
        },
      ),
      GoRoute(
        path: CrushRoutes.dateIdeas,
        pageBuilder: (context, state) =>
            _buildPage(state, const DateIdeasScreen()),
      ),
      GoRoute(
        path: CrushRoutes.compatibilityQuiz,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, String>?;
          final matchId = args?['matchId'] ?? '';
          final userId = authBloc.state.user?.id ?? '';
          return _buildPage(state, CompatibilityQuizScreen(matchId: matchId, userId: userId));
        },
      ),
      GoRoute(
        path: CrushRoutes.profileInsights,
        pageBuilder: (context, state) {
          final userId = authBloc.state.user?.id ?? '';
          return _buildPage(state, ProfileInsightsScreen(userId: userId));
        },
      ),
      GoRoute(
        path: CrushRoutes.safetyGuidelines,
        pageBuilder: (context, state) =>
            _buildPage(state, const CommunityGuidelinesScreen()),
      ),
      GoRoute(
        path: CrushRoutes.testAgora,
        pageBuilder: (context, state) =>
            _buildPage(state, const TestVideoScreen()),
      ),
      GoRoute(
        path: CrushRoutes.profile,
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileViewScreen()),
      ),
      GoRoute(
        path: CrushRoutes.profileEdit,
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileEditScreen()),
      ),
      GoRoute(
        path: CrushRoutes.profileMedia,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is ProfileMediaArgs) {
            return _buildPage(
              state,
              ProfileMediaScreen(profile: args.profile),
            );
          }
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.settings,
        pageBuilder: (context, state) =>
            _buildPage(state, const settings.SettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.privacySettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const PrivacySettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.notificationsSettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const NotificationsSettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.languageSettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const LanguageRegionSettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.discoverySettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const DiscoveryFiltersSettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.storageSettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const DataStorageSettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.securitySettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const AccountSecuritySettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.accountSettings,
        pageBuilder: (context, state) =>
            _buildPage(state, const AccountActionsSettingsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.chatSettings,
        pageBuilder: (context, state) {
          // Get current chat settings from profile and subscription status
          final profileState = context.read<ProfileBloc>().state;
          final subState = context.read<SubscriptionBloc>().state;
          final chatSettings = profileState.profile?.chatSettings ?? const ChatSettings();
          final isPremium = subState.plan == SubscriptionPlan.plus;

          return _buildPage(
            state,
            BlocProvider(
              create: (_) => ChatSettingsCubit(
                initialSettings: chatSettings,
                isPremium: isPremium,
              ),
              child: const ChatSettingsScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: CrushRoutes.userProfile,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is OtherUserProfileArgs) {
            return _buildPage(state, OtherUserProfileScreen(args: args));
          }
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.storyViewer,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is StoryViewerArgs && args.stories.isNotEmpty) {
            return _buildPage(
              state,
              StoryViewerScreen(
                stories: args.stories,
                profile: args.profile,
                initialIndex: args.initialIndex,
              ),
            );
          }
          return _buildPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: CrushRoutes.privacyPolicy,
        pageBuilder: (context, state) =>
            _buildPage(state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: CrushRoutes.termsOfService,
        pageBuilder: (context, state) =>
            _buildPage(state, const TermsOfServiceScreen()),
      ),
      // Widget catalog - debug builds only
      if (kDebugMode)
        GoRoute(
          path: CrushRoutes.widgetCatalog,
          pageBuilder: (context, state) =>
              _buildPage(state, const WidgetCatalogScreen()),
        ),
    ],
  );
}

CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.02),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
