import 'package:crushhour/core/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseAnalyticsPlatform originalAnalyticsPlatform;

  setUpAll(() async {
    setupFirebaseAnalyticsMocks();
    await Firebase.initializeApp();
    originalAnalyticsPlatform = FirebaseAnalyticsPlatform.instance;
    FirebaseAnalyticsPlatform.instance = _FakeFirebaseAnalyticsPlatform();
  });

  tearDownAll(() {
    FirebaseAnalyticsPlatform.instance = originalAnalyticsPlatform;
  });

  tearDown(() {
    AnalyticsService.resetInstance();
  });

  group('AnalyticsService hotspot coverage', () {
    test(
      'setUserProperties covers age/completeness buckets and observer',
      () async {
        final service = AnalyticsService.instance;

        expect(service.observer, isA<FirebaseAnalyticsObserver>());

        await service.setUserId('user-123');
        await service.setUserId(null);

        for (final age in [18, 27, 33, 38, 45, 60]) {
          await service.setUserProperties(age: age);
        }

        for (final completion in [10, 30, 60, 95]) {
          await service.setUserProperties(profileCompleteness: completion);
        }

        await service.setUserProperties(
          subscriptionPlan: 'plus',
          gender: 'female',
          country: 'US',
          isVerified: true,
        );
      },
    );

    test(
      'event logging APIs are callable and handle null-aware params',
      () async {
        final service = AnalyticsService.instance;

        await service.logSignUp(method: 'email');
        await service.logLogin(method: 'password');
        await service.logLogout();
        await service.logPhoneVerificationStarted();
        await service.logPhoneVerificationCompleted(success: true);
        await service.logPhoneVerificationCompleted(success: false);
        await service.logEmailVerificationSent();

        await service.logOnboardingStep(
          step: 'photos',
          stepNumber: 2,
          totalSteps: 5,
        );
        await service.logOnboardingCompleted(durationSeconds: 85);
        await service.logOnboardingAbandoned(lastStep: 'about_you');

        await service.logDeckLoaded(cardCount: 12);
        await service.logCardViewed(
          targetUserId: 'target-1',
          position: 1,
          viewDurationMs: 900,
        );
        await service.logSwipeRight(
          targetUserId: 'target-1',
          withMessage: true,
        );
        await service.logSwipeLeft(targetUserId: 'target-2');
        await service.logMatch(matchId: 'match-1');
        await service.logDeckEmpty();
        await service.logSuperLike(targetUserId: 'target-3');
        await service.logRewind();
        await service.logBoostActivated();
        await service.logBoostExpired(profileViewsGained: null);
        await service.logBoostExpired(profileViewsGained: 18);
        await service.logTopPicksViewed(count: 7);
        await service.logLikesYouViewed(count: 4);

        await service.logConversationOpened(matchId: 'match-1');
        await service.logFirstMessageSent(matchId: 'match-1');
        await service.logMessageSent(matchId: 'match-1', messageType: 'text');
        await service.logMediaSent(matchId: 'match-1', mediaType: 'image');
        await service.logReactionAdded(emoji: '🔥');
        await service.logUnmatch(matchId: 'match-1');
        await service.logUserBlocked();
        await service.logUserReported(reason: 'spam');

        await service.logCallStarted(matchId: 'match-2', isVideo: true);
        await service.logCallEnded(durationSeconds: 240, isVideo: false);

        await service.logProfileViewed();
        await service.logProfileEditStarted();
        await service.logProfileUpdated(fieldsUpdated: ['bio', 'photos']);
        await service.logPhotoAdded(totalPhotos: 4);
        await service.logPhotoRemoved(totalPhotos: 3);
        await service.logBioUpdated(charCount: 120);
        await service.logOtherProfileViewed(source: 'discovery');

        await service.logPaywallViewed(source: 'discovery_limit');
        await service.logCheckoutStarted(tier: 'plus_monthly');
        await service.logSubscriptionPurchased(
          tier: 'plus_monthly',
          price: 19.99,
          currency: 'USD',
        );
        await service.logSubscriptionCancelled(tier: 'plus_monthly');
        await service.logPremiumFeatureUsed(feature: 'rewind');
        await service.logPremiumFeatureBlocked(feature: 'likes_you');

        await service.logSettingsChanged(setting: 'theme', value: 'dark');
        await service.logDiscoveryPreferencesUpdated();
        await service.logDiscoveryPreferencesUpdated(
          minAge: 24,
          maxAge: 36,
          maxDistance: 30,
          genders: ['female', 'male'],
        );
        await service.logNotificationSettingsChanged(
          type: 'push',
          enabled: true,
        );

        await service.logScreenView(
          screenName: 'chat',
          screenClass: 'ChatScreen',
        );
        await service.logError(
          errorType: 'network',
          errorMessage: 'x' * 140,
          screen: null,
        );
        await service.logError(
          errorType: 'validation',
          errorMessage: 'Bad input',
          screen: 'signup',
        );
      },
    );
  });
}

class _FakeFirebaseAnalyticsPlatform extends FirebaseAnalyticsPlatform {
  _FakeFirebaseAnalyticsPlatform({super.appInstance});

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) {
    return _FakeFirebaseAnalyticsPlatform(appInstance: app);
  }

  @override
  Future<String?> getAppInstanceId() async => 'test-app-instance-id';

  @override
  Future<int?> getSessionId() async => 1;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setConsent({
    bool? adStorageConsentGranted,
    bool? analyticsStorageConsentGranted,
    bool? adPersonalizationSignalsConsentGranted,
    bool? adUserDataConsentGranted,
    bool? functionalityStorageConsentGranted,
    bool? personalizationStorageConsentGranted,
    bool? securityStorageConsentGranted,
  }) async {}

  @override
  Future<void> setDefaultEventParameters(
    Map<String, Object?>? defaultParameters,
  ) async {}

  @override
  Future<void> setSessionTimeoutDuration(Duration timeout) async {}

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> initiateOnDeviceConversionMeasurement({
    String? emailAddress,
    String? phoneNumber,
    String? hashedEmailAddress,
    String? hashedPhoneNumber,
  }) async {}
}
