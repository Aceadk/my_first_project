import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router_refresh_stream.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import '../presentation/screens/splash_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/otp_screen.dart';
import '../presentation/screens/home_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_auth_screen.dart';
import '../presentation/screens/email_protection_screen.dart';
import '../presentation/screens/change_email_screen.dart';
import '../presentation/screens/new_device_screen.dart';
import '../presentation/screens/basic_info_screen.dart';
import '../presentation/screens/id_verification_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/logout_screen.dart';
import '../presentation/screens/safety_screen.dart';
import '../presentation/screens/community_guidelines_screen.dart';
import '../presentation/screens/test/test_video_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_view_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/other_user_profile_screen.dart';
import '../presentation/screens/settings_screen.dart' as settings;
import '../presentation/screens/settings/privacy_settings_screen.dart';
import '../presentation/screens/settings/notifications_settings_screen.dart';
import '../presentation/screens/settings/language_region_settings_screen.dart';
import '../presentation/screens/settings/discovery_filters_settings_screen.dart';
import '../presentation/screens/settings/data_storage_settings_screen.dart';
import '../presentation/screens/settings/account_security_settings_screen.dart';
import '../presentation/screens/settings/account_actions_settings_screen.dart';

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
  static const emailProtection = '/email-protection';
  static const changeEmail = '/change-email';
  static const newDevice = '/new-device';
  static const basicInfo = '/basic-info';
  static const idVerification = '/id-verification';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const chat = '/chat';
  static const logout = '/logout';
  static const safety = '/safety';
  static const safetyGuidelines = '/safety-guidelines';
  static const testAgora = '/test-agora';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const userProfile = '/user-profile';
  static const settings = '/settings';
  static const privacySettings = '/settings/privacy';
  static const notificationsSettings = '/settings/notifications';
  static const languageSettings = '/settings/language';
  static const discoverySettings = '/settings/discovery';
  static const storageSettings = '/settings/storage';
  static const securitySettings = '/settings/security';
  static const accountSettings = '/settings/account';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: CrushRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final isLoggedIn = status == AuthStatus.authenticated;
      final isUnknown = status == AuthStatus.unknown;
      final path = state.uri.path;
      final isAuthRoute = path.startsWith(CrushRoutes.authGateway);
      final isSplash = path == CrushRoutes.splash;

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
        return isLoggedIn ? CrushRoutes.home : CrushRoutes.authGateway;
      }

      // Not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        return CrushRoutes.authGateway;
      }

      // Logged in and trying to access auth route
      if (isLoggedIn && isAuthRoute) {
        return CrushRoutes.home;
      }

      // Root path redirect
      if (path == CrushRoutes.root) {
        return isLoggedIn ? CrushRoutes.home : CrushRoutes.authGateway;
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
        path: CrushRoutes.idVerification,
        pageBuilder: (context, state) =>
            _buildPage(state, const IdVerificationScreen()),
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
        path: CrushRoutes.userProfile,
        pageBuilder: (context, state) {
          final args = state.extra;
          if (args is OtherUserProfileArgs) {
            return _buildPage(state, OtherUserProfileScreen(args: args));
          }
          return _buildPage(state, const HomeScreen());
        },
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
