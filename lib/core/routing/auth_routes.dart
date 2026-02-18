import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/screens/splash_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/otp_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/email_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/phone_protection_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/change_email_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/new_device_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/id_verification_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/logout_screen.dart';
import 'package:crushhour/features/profile/presentation/screens/profile_setup_screen.dart';
import 'crush_routes.dart';
import 'page_builder.dart';

/// Auth, onboarding, and account-verification routes.
List<RouteBase> authRoutes() => [
      GoRoute(
        path: CrushRoutes.root,
        redirect: (context, state) => CrushRoutes.splash,
      ),
      GoRoute(
        path: CrushRoutes.splash,
        pageBuilder: (context, state) =>
            buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: CrushRoutes.authGateway,
        pageBuilder: (context, state) =>
            buildPage(state, const AuthGatewayScreen()),
        routes: [
          GoRoute(
            path: 'login',
            pageBuilder: (context, state) =>
                buildPage(state, const LoginScreen()),
          ),
          GoRoute(
            path: 'signup',
            pageBuilder: (context, state) =>
                buildPage(state, const SignUpScreen()),
          ),
          GoRoute(
            path: 'forgot',
            pageBuilder: (context, state) =>
                buildPage(state, const ForgotPasswordScreen()),
          ),
          GoRoute(
            path: 'otp',
            pageBuilder: (context, state) {
              final phone = state.uri.queryParameters['phone'];
              if (phone == null || phone.isEmpty) {
                return buildPage(state, const AuthGatewayScreen());
              }
              return buildPage(state, OtpScreen(phoneNumber: phone));
            },
          ),
          GoRoute(
            path: 'reset',
            pageBuilder: (context, state) =>
                buildPage(state, const ForgotPasswordScreen()),
          ),
          GoRoute(
            path: 'phone',
            pageBuilder: (context, state) =>
                buildPage(state, const PhoneAuthScreen()),
          ),
          GoRoute(
            path: 'email',
            pageBuilder: (context, state) =>
                buildPage(state, const EmailAuthScreen()),
          ),
        ],
      ),
      GoRoute(
        path: CrushRoutes.emailVerification,
        pageBuilder: (context, state) =>
            buildPage(state, const EmailVerificationScreen()),
      ),
      GoRoute(
        path: CrushRoutes.emailProtection,
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          final redirectOnSuccess = redirect == '1' || redirect == 'true';
          return buildPage(
            state,
            EmailProtectionScreen(redirectOnSuccess: redirectOnSuccess),
          );
        },
      ),
      GoRoute(
        path: CrushRoutes.phoneProtection,
        pageBuilder: (context, state) =>
            buildPage(state, const PhoneProtectionScreen()),
      ),
      GoRoute(
        path: CrushRoutes.changeEmail,
        pageBuilder: (context, state) =>
            buildPage(state, const ChangeEmailScreen()),
      ),
      GoRoute(
        path: CrushRoutes.newDevice,
        pageBuilder: (context, state) =>
            buildPage(state, const NewDeviceScreen()),
      ),
      GoRoute(
        path: CrushRoutes.basicInfo,
        pageBuilder: (context, state) =>
            buildPage(state, const BasicInfoScreen()),
      ),
      GoRoute(
        path: CrushRoutes.termsConditions,
        pageBuilder: (context, state) =>
            buildPage(state, const TermsConditionsScreen()),
      ),
      GoRoute(
        path: CrushRoutes.idVerification,
        pageBuilder: (context, state) =>
            buildPage(state, const IdVerificationScreen()),
      ),
      GoRoute(
        path: CrushRoutes.idVerificationSettings,
        pageBuilder: (context, state) =>
            buildPage(state, const IdVerificationScreen(fromSettings: true)),
      ),
      GoRoute(
        path: CrushRoutes.profileSetup,
        pageBuilder: (context, state) =>
            buildPage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: CrushRoutes.logout,
        pageBuilder: (context, state) =>
            buildPage(state, const LogoutScreen()),
      ),
    ];
