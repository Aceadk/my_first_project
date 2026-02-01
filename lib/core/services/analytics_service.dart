import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics service for tracking user behavior and product insights.
///
/// Key metrics tracked:
/// - User acquisition & retention (sign-ups, logins, session duration)
/// - Discovery engagement (swipes, matches, match rate)
/// - Chat engagement (messages sent, response rates)
/// - Monetization (paywall views, conversions, subscription events)
/// - Profile completion & quality
class AnalyticsService {
  static AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  /// For testing: replace the singleton instance with a mock/stub.
  /// Call [resetInstance] after tests to restore the real instance.
  @visibleForTesting
  static void setInstance(AnalyticsService instance) {
    _instance = instance;
  }

  /// For testing: reset to the real instance after tests.
  @visibleForTesting
  static void resetInstance() {
    _instance = AnalyticsService._();
  }

  AnalyticsService._();

  /// Protected constructor for creating test stubs.
  @visibleForTesting
  AnalyticsService.forTesting();

  late final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ═══════════════════════════════════════════════════════════════════════════
  // USER PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    String? subscriptionPlan,
    String? gender,
    int? age,
    String? country,
    bool? isVerified,
    int? profileCompleteness,
  }) async {
    if (subscriptionPlan != null) {
      await _analytics.setUserProperty(
        name: 'subscription_plan',
        value: subscriptionPlan,
      );
    }
    if (gender != null) {
      await _analytics.setUserProperty(name: 'gender', value: gender);
    }
    if (age != null) {
      await _analytics.setUserProperty(
          name: 'age_group', value: _ageGroup(age));
    }
    if (country != null) {
      await _analytics.setUserProperty(name: 'country', value: country);
    }
    if (isVerified != null) {
      await _analytics.setUserProperty(
        name: 'is_verified',
        value: isVerified.toString(),
      );
    }
    if (profileCompleteness != null) {
      await _analytics.setUserProperty(
        name: 'profile_completeness',
        value: _completenessGroup(profileCompleteness),
      );
    }
  }

  String _ageGroup(int age) {
    if (age < 25) return '18-24';
    if (age < 30) return '25-29';
    if (age < 35) return '30-34';
    if (age < 40) return '35-39';
    if (age < 50) return '40-49';
    return '50+';
  }

  String _completenessGroup(int percentage) {
    if (percentage < 25) return 'low';
    if (percentage < 50) return 'medium';
    if (percentage < 75) return 'high';
    return 'complete';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track user sign up
  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    _log('sign_up', {'method': method});
  }

  /// Track user login
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    _log('login', {'method': method});
  }

  /// Track user logout
  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    _log('logout');
  }

  /// Track phone verification started
  Future<void> logPhoneVerificationStarted() async {
    await _analytics.logEvent(name: 'phone_verification_started');
    _log('phone_verification_started');
  }

  /// Track phone verification completed
  Future<void> logPhoneVerificationCompleted({required bool success}) async {
    await _analytics.logEvent(
      name: 'phone_verification_completed',
      parameters: {'success': success ? 1 : 0},
    );
    _log('phone_verification_completed', {'success': success});
  }

  /// Track email verification
  Future<void> logEmailVerificationSent() async {
    await _analytics.logEvent(name: 'email_verification_sent');
    _log('email_verification_sent');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track onboarding step completion
  Future<void> logOnboardingStep({
    required String step,
    required int stepNumber,
    required int totalSteps,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {
        'step': step,
        'step_number': stepNumber,
        'total_steps': totalSteps,
        'progress': (stepNumber / totalSteps * 100).round(),
      },
    );
    _log('onboarding_step', {'step': step, 'step_number': stepNumber});
  }

  /// Track onboarding completion
  Future<void> logOnboardingCompleted({required int durationSeconds}) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'duration_seconds': durationSeconds},
    );
    _log('onboarding_completed', {'duration_seconds': durationSeconds});
  }

  /// Track onboarding abandonment
  Future<void> logOnboardingAbandoned({required String lastStep}) async {
    await _analytics.logEvent(
      name: 'onboarding_abandoned',
      parameters: {'last_step': lastStep},
    );
    _log('onboarding_abandoned', {'last_step': lastStep});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track when discovery deck is loaded
  Future<void> logDeckLoaded({required int cardCount}) async {
    await _analytics.logEvent(
      name: 'deck_loaded',
      parameters: {'card_count': cardCount},
    );
    _log('deck_loaded', {'card_count': cardCount});
  }

  /// Track card view (impression)
  Future<void> logCardViewed({
    required String targetUserId,
    required int position,
    required int viewDurationMs,
  }) async {
    await _analytics.logEvent(
      name: 'card_viewed',
      parameters: {
        'position': position,
        'view_duration_ms': viewDurationMs,
      },
    );
    _log('card_viewed', {'position': position, 'duration': viewDurationMs});
  }

  /// Track swipe right (like)
  Future<void> logSwipeRight({
    required String targetUserId,
    bool withMessage = false,
  }) async {
    await _analytics.logEvent(
      name: 'swipe_right',
      parameters: {'with_message': withMessage ? 1 : 0},
    );
    _log('swipe_right', {'with_message': withMessage});
  }

  /// Track swipe left (pass)
  Future<void> logSwipeLeft({required String targetUserId}) async {
    await _analytics.logEvent(name: 'swipe_left');
    _log('swipe_left');
  }

  /// Track match created
  Future<void> logMatch({required String matchId}) async {
    await _analytics.logEvent(name: 'match_created');
    _log('match_created');
  }

  /// Track when user runs out of cards
  Future<void> logDeckEmpty() async {
    await _analytics.logEvent(name: 'deck_empty');
    _log('deck_empty');
  }

  /// Track super like
  Future<void> logSuperLike({required String targetUserId}) async {
    await _analytics.logEvent(name: 'super_like');
    _log('super_like');
  }

  /// Track rewind (undo swipe)
  Future<void> logRewind() async {
    await _analytics.logEvent(name: 'rewind');
    _log('rewind');
  }

  /// Track boost activation
  Future<void> logBoostActivated() async {
    await _analytics.logEvent(name: 'boost_activated');
    _log('boost_activated');
  }

  /// Track boost expiration
  Future<void> logBoostExpired({int? profileViewsGained}) async {
    await _analytics.logEvent(
      name: 'boost_expired',
      parameters: {
        'profile_views': ?profileViewsGained,
      },
    );
    _log('boost_expired', {'profile_views': profileViewsGained});
  }

  /// Track top picks viewed
  Future<void> logTopPicksViewed({required int count}) async {
    await _analytics.logEvent(
      name: 'top_picks_viewed',
      parameters: {'count': count},
    );
    _log('top_picks_viewed', {'count': count});
  }

  /// Track "likes you" section viewed
  Future<void> logLikesYouViewed({required int count}) async {
    await _analytics.logEvent(
      name: 'likes_you_viewed',
      parameters: {'count': count},
    );
    _log('likes_you_viewed', {'count': count});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track conversation opened
  Future<void> logConversationOpened({required String matchId}) async {
    await _analytics.logEvent(name: 'conversation_opened');
    _log('conversation_opened');
  }

  /// Track first message sent in a match
  Future<void> logFirstMessageSent({required String matchId}) async {
    await _analytics.logEvent(name: 'first_message_sent');
    _log('first_message_sent');
  }

  /// Track message sent
  Future<void> logMessageSent({
    required String matchId,
    required String messageType,
  }) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {'message_type': messageType},
    );
    _log('message_sent', {'type': messageType});
  }

  /// Track media sent
  Future<void> logMediaSent({
    required String matchId,
    required String mediaType,
  }) async {
    await _analytics.logEvent(
      name: 'media_sent',
      parameters: {'media_type': mediaType},
    );
    _log('media_sent', {'type': mediaType});
  }

  /// Track reaction added
  Future<void> logReactionAdded({required String emoji}) async {
    await _analytics.logEvent(
      name: 'reaction_added',
      parameters: {'emoji': emoji},
    );
    _log('reaction_added', {'emoji': emoji});
  }

  /// Track unmatch
  Future<void> logUnmatch({required String matchId}) async {
    await _analytics.logEvent(name: 'unmatch');
    _log('unmatch');
  }

  /// Track user blocked
  Future<void> logUserBlocked() async {
    await _analytics.logEvent(name: 'user_blocked');
    _log('user_blocked');
  }

  /// Track user reported
  Future<void> logUserReported({required String reason}) async {
    await _analytics.logEvent(
      name: 'user_reported',
      parameters: {'reason': reason},
    );
    _log('user_reported', {'reason': reason});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALL EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track call started
  Future<void> logCallStarted({
    required String matchId,
    required bool isVideo,
  }) async {
    await _analytics.logEvent(
      name: 'call_started',
      parameters: {'is_video': isVideo ? 1 : 0},
    );
    _log('call_started', {'is_video': isVideo});
  }

  /// Track call ended
  Future<void> logCallEnded({
    required int durationSeconds,
    required bool isVideo,
  }) async {
    await _analytics.logEvent(
      name: 'call_ended',
      parameters: {
        'duration_seconds': durationSeconds,
        'is_video': isVideo ? 1 : 0,
      },
    );
    _log('call_ended', {'duration': durationSeconds, 'is_video': isVideo});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track profile viewed (own profile)
  Future<void> logProfileViewed() async {
    await _analytics.logEvent(name: 'profile_viewed');
    _log('profile_viewed');
  }

  /// Track profile edit started
  Future<void> logProfileEditStarted() async {
    await _analytics.logEvent(name: 'profile_edit_started');
    _log('profile_edit_started');
  }

  /// Track profile updated
  Future<void> logProfileUpdated({required List<String> fieldsUpdated}) async {
    await _analytics.logEvent(
      name: 'profile_updated',
      parameters: {
        'fields_count': fieldsUpdated.length,
        'fields': fieldsUpdated.take(10).join(','),
      },
    );
    _log('profile_updated', {'fields': fieldsUpdated});
  }

  /// Track photo added
  Future<void> logPhotoAdded({required int totalPhotos}) async {
    await _analytics.logEvent(
      name: 'photo_added',
      parameters: {'total_photos': totalPhotos},
    );
    _log('photo_added', {'total': totalPhotos});
  }

  /// Track photo removed
  Future<void> logPhotoRemoved({required int totalPhotos}) async {
    await _analytics.logEvent(
      name: 'photo_removed',
      parameters: {'total_photos': totalPhotos},
    );
    _log('photo_removed', {'total': totalPhotos});
  }

  /// Track bio updated
  Future<void> logBioUpdated({required int charCount}) async {
    await _analytics.logEvent(
      name: 'bio_updated',
      parameters: {'char_count': charCount},
    );
    _log('bio_updated', {'length': charCount});
  }

  /// Track other user profile viewed
  Future<void> logOtherProfileViewed({required String source}) async {
    await _analytics.logEvent(
      name: 'other_profile_viewed',
      parameters: {'source': source},
    );
    _log('other_profile_viewed', {'source': source});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track paywall viewed
  Future<void> logPaywallViewed({required String source}) async {
    await _analytics.logEvent(
      name: 'paywall_viewed',
      parameters: {'source': source},
    );
    _log('paywall_viewed', {'source': source});
  }

  /// Track checkout started
  Future<void> logCheckoutStarted({required String plan}) async {
    await _analytics.logBeginCheckout(currency: 'USD');
    await _analytics.logEvent(
      name: 'checkout_started',
      parameters: {'plan': plan},
    );
    _log('checkout_started', {'plan': plan});
  }

  /// Track subscription purchased
  Future<void> logSubscriptionPurchased({
    required String plan,
    required double price,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: price,
    );
    await _analytics.logEvent(
      name: 'subscription_purchased',
      parameters: {
        'plan': plan,
        'price': price,
        'currency': currency,
      },
    );
    _log('subscription_purchased', {'plan': plan, 'price': price});
  }

  /// Track subscription cancelled
  Future<void> logSubscriptionCancelled({required String plan}) async {
    await _analytics.logEvent(
      name: 'subscription_cancelled',
      parameters: {'plan': plan},
    );
    _log('subscription_cancelled', {'plan': plan});
  }

  /// Track premium feature used
  Future<void> logPremiumFeatureUsed({required String feature}) async {
    await _analytics.logEvent(
      name: 'premium_feature_used',
      parameters: {'feature': feature},
    );
    _log('premium_feature_used', {'feature': feature});
  }

  /// Track premium feature blocked (shown upsell)
  Future<void> logPremiumFeatureBlocked({required String feature}) async {
    await _analytics.logEvent(
      name: 'premium_feature_blocked',
      parameters: {'feature': feature},
    );
    _log('premium_feature_blocked', {'feature': feature});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track settings changed
  Future<void> logSettingsChanged({
    required String setting,
    required String value,
  }) async {
    await _analytics.logEvent(
      name: 'settings_changed',
      parameters: {'setting': setting, 'value': value},
    );
    _log('settings_changed', {'setting': setting, 'value': value});
  }

  /// Track discovery preferences updated
  Future<void> logDiscoveryPreferencesUpdated({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? genders,
  }) async {
    await _analytics.logEvent(
      name: 'discovery_preferences_updated',
      parameters: {
        'min_age': ?minAge,
        'max_age': ?maxAge,
        'max_distance': ?maxDistance,
        if (genders != null) 'genders': genders.join(','),
      },
    );
    _log('discovery_preferences_updated');
  }

  /// Track notification settings changed
  Future<void> logNotificationSettingsChanged({
    required String type,
    required bool enabled,
  }) async {
    await _analytics.logEvent(
      name: 'notification_settings_changed',
      parameters: {'type': type, 'enabled': enabled ? 1 : 0},
    );
    _log('notification_settings_changed', {'type': type, 'enabled': enabled});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log error event
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.take(100),
        'screen': ?screen,
      },
    );
    _log('app_error', {'type': errorType, 'message': errorMessage});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  void _log(String event, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      debugPrint('📊 Analytics: $event ${params ?? ''}');
    }
  }
}

extension _StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
