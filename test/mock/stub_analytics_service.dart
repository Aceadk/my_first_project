import 'package:crushhour/core/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Stub implementation of AnalyticsService for testing.
/// All methods are no-ops that complete immediately.
class StubAnalyticsService extends AnalyticsService {
  StubAnalyticsService() : super.forTesting();

  // Track calls for verification in tests
  final List<String> loggedEvents = [];

  void _trackEvent(String event) {
    loggedEvents.add(event);
  }

  @override
  FirebaseAnalyticsObserver get observer =>
      throw UnimplementedError('Observer not available in tests');

  @override
  Future<void> setUserId(String? userId) async {
    _trackEvent('setUserId:$userId');
  }

  @override
  Future<void> setUserProperties({
    String? subscriptionPlan,
    String? gender,
    int? age,
    String? country,
    bool? isVerified,
    int? profileCompleteness,
  }) async {
    _trackEvent('setUserProperties');
  }

  @override
  Future<void> logSignUp({required String method}) async {
    _trackEvent('logSignUp:$method');
  }

  @override
  Future<void> logLogin({required String method}) async {
    _trackEvent('logLogin:$method');
  }

  @override
  Future<void> logLogout() async {
    _trackEvent('logLogout');
  }

  @override
  Future<void> logPhoneVerificationStarted() async {
    _trackEvent('logPhoneVerificationStarted');
  }

  @override
  Future<void> logPhoneVerificationCompleted({required bool success}) async {
    _trackEvent('logPhoneVerificationCompleted:$success');
  }

  @override
  Future<void> logEmailVerificationSent() async {
    _trackEvent('logEmailVerificationSent');
  }

  @override
  Future<void> logOnboardingStep({
    required String step,
    required int stepNumber,
    required int totalSteps,
  }) async {
    _trackEvent('logOnboardingStep:$step');
  }

  @override
  Future<void> logOnboardingCompleted({required int durationSeconds}) async {
    _trackEvent('logOnboardingCompleted:$durationSeconds');
  }

  @override
  Future<void> logOnboardingAbandoned({required String lastStep}) async {
    _trackEvent('logOnboardingAbandoned:$lastStep');
  }

  @override
  Future<void> logDeckLoaded({required int cardCount}) async {
    _trackEvent('logDeckLoaded:$cardCount');
  }

  @override
  Future<void> logCardViewed({
    required String targetUserId,
    required int position,
    required int viewDurationMs,
  }) async {
    _trackEvent('logCardViewed:$targetUserId');
  }

  @override
  Future<void> logSwipeRight({
    required String targetUserId,
    bool withMessage = false,
  }) async {
    _trackEvent('logSwipeRight:$targetUserId');
  }

  @override
  Future<void> logSwipeLeft({required String targetUserId}) async {
    _trackEvent('logSwipeLeft:$targetUserId');
  }

  @override
  Future<void> logMatch({required String matchId}) async {
    _trackEvent('logMatch:$matchId');
  }

  @override
  Future<void> logDeckEmpty() async {
    _trackEvent('logDeckEmpty');
  }

  @override
  Future<void> logSuperLike({required String targetUserId}) async {
    _trackEvent('logSuperLike:$targetUserId');
  }

  @override
  Future<void> logRewind() async {
    _trackEvent('logRewind');
  }

  @override
  Future<void> logBoostActivated() async {
    _trackEvent('logBoostActivated');
  }

  @override
  Future<void> logBoostExpired({int? profileViewsGained}) async {
    _trackEvent('logBoostExpired:$profileViewsGained');
  }

  @override
  Future<void> logTopPicksViewed({required int count}) async {
    _trackEvent('logTopPicksViewed:$count');
  }

  @override
  Future<void> logLikesYouViewed({required int count}) async {
    _trackEvent('logLikesYouViewed:$count');
  }

  @override
  Future<void> logConversationOpened({required String matchId}) async {
    _trackEvent('logConversationOpened:$matchId');
  }

  @override
  Future<void> logFirstMessageSent({required String matchId}) async {
    _trackEvent('logFirstMessageSent:$matchId');
  }

  @override
  Future<void> logMessageSent({
    required String matchId,
    required String messageType,
  }) async {
    _trackEvent('logMessageSent:$messageType');
  }

  @override
  Future<void> logMediaSent({
    required String matchId,
    required String mediaType,
  }) async {
    _trackEvent('logMediaSent:$mediaType');
  }

  @override
  Future<void> logReactionAdded({required String emoji}) async {
    _trackEvent('logReactionAdded:$emoji');
  }

  @override
  Future<void> logUnmatch({required String matchId}) async {
    _trackEvent('logUnmatch:$matchId');
  }

  @override
  Future<void> logUserBlocked() async {
    _trackEvent('logUserBlocked');
  }

  @override
  Future<void> logUserReported({required String reason}) async {
    _trackEvent('logUserReported:$reason');
  }

  @override
  Future<void> logCallStarted({
    required String matchId,
    required bool isVideo,
  }) async {
    _trackEvent('logCallStarted:$matchId:$isVideo');
  }

  @override
  Future<void> logCallEnded({
    required int durationSeconds,
    required bool isVideo,
  }) async {
    _trackEvent('logCallEnded:$durationSeconds:$isVideo');
  }

  @override
  Future<void> logProfileViewed() async {
    _trackEvent('logProfileViewed');
  }

  @override
  Future<void> logProfileEditStarted() async {
    _trackEvent('logProfileEditStarted');
  }

  @override
  Future<void> logProfileUpdated({required List<String> fieldsUpdated}) async {
    _trackEvent('logProfileUpdated:${fieldsUpdated.join(",")}');
  }

  @override
  Future<void> logPhotoAdded({required int totalPhotos}) async {
    _trackEvent('logPhotoAdded:$totalPhotos');
  }

  @override
  Future<void> logPhotoRemoved({required int totalPhotos}) async {
    _trackEvent('logPhotoRemoved:$totalPhotos');
  }

  @override
  Future<void> logBioUpdated({required int charCount}) async {
    _trackEvent('logBioUpdated:$charCount');
  }

  @override
  Future<void> logOtherProfileViewed({required String source}) async {
    _trackEvent('logOtherProfileViewed:$source');
  }

  @override
  Future<void> logPaywallViewed({required String source}) async {
    _trackEvent('logPaywallViewed:$source');
  }

  @override
  Future<void> logCheckoutStarted({required String plan}) async {
    _trackEvent('logCheckoutStarted:$plan');
  }

  @override
  Future<void> logSubscriptionPurchased({
    required String plan,
    required double price,
    required String currency,
  }) async {
    _trackEvent('logSubscriptionPurchased:$plan:$price:$currency');
  }

  @override
  Future<void> logSubscriptionCancelled({required String plan}) async {
    _trackEvent('logSubscriptionCancelled:$plan');
  }

  @override
  Future<void> logPremiumFeatureUsed({required String feature}) async {
    _trackEvent('logPremiumFeatureUsed:$feature');
  }

  @override
  Future<void> logPremiumFeatureBlocked({required String feature}) async {
    _trackEvent('logPremiumFeatureBlocked:$feature');
  }

  @override
  Future<void> logSettingsChanged({
    required String setting,
    required String value,
  }) async {
    _trackEvent('logSettingsChanged:$setting:$value');
  }

  @override
  Future<void> logDiscoveryPreferencesUpdated({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? genders,
  }) async {
    _trackEvent('logDiscoveryPreferencesUpdated');
  }

  @override
  Future<void> logNotificationSettingsChanged({
    required String type,
    required bool enabled,
  }) async {
    _trackEvent('logNotificationSettingsChanged:$type:$enabled');
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    _trackEvent('logScreenView:$screenName');
  }

  @override
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    _trackEvent('logError:$errorType');
  }
}
