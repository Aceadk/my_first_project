import '../app_env.dart';

class CrushConstants {
  static const int minAge = 18;
  static const int freeDailySwipeLimit = 30;
  static const int maxPreMatchMessageRequestsPerPair = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // DISTANCE LIMITS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default maximum distance for discovery (km).
  /// Users first see people within this radius.
  static const double defaultMaxDistanceKm = 220.0;

  /// Extended distance when local matches are exhausted (km).
  /// Free users can see beyond defaultMaxDistanceKm only when local deck is empty.
  static const double extendedMaxDistanceKm = 500.0;

  /// Maximum distance slider value (km).
  static const double maxDistanceSliderKm = 500.0;

  /// Plus users with Passport mode can see people globally (no limit).
  static const double globalDistanceKm = double.infinity;

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPER LIKES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Free users get 1 super like per day.
  static const int freeDailySuperLikes = 1;

  /// Plus users get 7 super likes per day.
  static const int premiumDailySuperLikes = 7;

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOST
  // ═══════════════════════════════════════════════════════════════════════════

  /// Free users get 30 minutes of boost.
  static const int freeBoostDurationMinutes = 30;

  /// Plus users get 60 minutes of boost.
  static const int premiumBoostDurationMinutes = 60;

  /// Free users must wait 72 hours (3 days) between boosts.
  static const int freeBoostCooldownHours = 72;

  /// Plus users must wait 24 hours between boosts.
  static const int premiumBoostCooldownHours = 24;

  // You will enforce these based on SubscriptionPlan.free / .plus

  // Set true in development to skip auth gating and go straight to home.
  static const bool _skipAuthGate =
      bool.fromEnvironment('SKIP_AUTH_GATE', defaultValue: false);
  static bool get skipAuthInDev => AppEnvConfig.isDev && _skipAuthGate;
}
