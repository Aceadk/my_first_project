import 'package:flutter/material.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/phone_auth_screen.dart';
import '../presentation/screens/email_auth_screen.dart';
import '../presentation/screens/otp_screen.dart';
import '../presentation/screens/basic_info_screen.dart';
import '../presentation/screens/id_verification_screen.dart';
import '../presentation/screens/profile_setup_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/test/test_video_screen.dart';
import '../presentation/screens/logout_screen.dart';
import '../presentation/screens/safety_screen.dart';
import '../presentation/screens/community_guidelines_screen.dart';
import '../presentation/screens/email_protection_screen.dart';
import '../presentation/screens/change_email_screen.dart';
import '../presentation/screens/forgot_password_screen.dart';
import '../presentation/screens/new_device_screen.dart';
import '../presentation/screens/auth_gateway_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/sign_up_screen.dart';

class CrushRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const authGateway = '/auth-gateway';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const phoneAuth = '/phone-auth';
  static const emailAuth = '/email-auth';
  static const emailProtection = '/email-protection';
  static const changeEmail = '/change-email';
  static const forgotPassword = '/forgot-password';
  static const newDevice = '/new-device';
  static const otp = '/otp';
  static const basicInfo = '/basic-info';
  static const idVerification = '/id-verification';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const chat = '/chat';
  static const logout = '/logout';
  static const safety = '/safety';
  static const safetyGuidelines = '/safety-guidelines';
  static const testAgora = '/test-agora';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const AuthGatewayScreen());
      case authGateway:
        return MaterialPageRoute(builder: (_) => const AuthGatewayScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case phoneAuth:
        return MaterialPageRoute(builder: (_) => const PhoneAuthScreen());
      case emailAuth:
        return MaterialPageRoute(builder: (_) => const EmailAuthScreen());
      case emailProtection:
        final redirect =
            settings.arguments is bool ? settings.arguments as bool : false;
        return MaterialPageRoute(
          builder: (_) => EmailProtectionScreen(
            redirectOnSuccess: redirect,
          ),
        );
      case changeEmail:
        return MaterialPageRoute(
          builder: (_) => const ChangeEmailScreen(),
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );
      case newDevice:
        return MaterialPageRoute(
          builder: (_) => const NewDeviceScreen(),
        );
      case otp:
        final phone = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: phone),
        );
      case basicInfo:
        return MaterialPageRoute(builder: (_) => const BasicInfoScreen());
      case idVerification:
        return MaterialPageRoute(builder: (_) => const IdVerificationScreen());
      case profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case chat:
        final args = settings.arguments as ChatScreenArgs;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(args: args),
        );
      case safety:
        return MaterialPageRoute(builder: (_) => const SafetyScreen());
      case safetyGuidelines:
        return MaterialPageRoute(
          builder: (_) => const CommunityGuidelinesScreen(),
        );
      case logout:
        return MaterialPageRoute(builder: (_) => const LogoutScreen());
      case testAgora:
        return MaterialPageRoute(builder: (_) => const TestVideoScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
