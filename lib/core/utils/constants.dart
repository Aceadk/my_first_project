import '../app_env.dart';

class CrushConstants {
  static const int minAge = 18;
  static const int freeDailySwipeLimit = 30;
  static const int maxPreMatchMessageRequestsPerPair = 3;

  // You will enforce these based on SubscriptionPlan.free / .plus

  // Set true in development to skip auth gating and go straight to home.
  static const bool _skipAuthGate =
      bool.fromEnvironment('SKIP_AUTH_GATE', defaultValue: false);
  static bool get skipAuthInDev => AppEnvConfig.isDev && _skipAuthGate;
}
