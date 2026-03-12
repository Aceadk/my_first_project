import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mock/firebase_mock.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  group('AnalyticsService', () {
    late AnalyticsService service;

    setUp(() {
      service = AnalyticsService.instance;
    });

    test('logSignUp logs event', () async {
      await service.logSignUp(method: 'email');
    });

    test('logLogin logs event', () async {
      await service.logLogin(method: 'phone');
    });

    test('logLogout logs event', () async {
      await service.logLogout();
    });

    test('user properties setting', () async {
      await service.setUserId('u123');
      await service.setUserProperties(
        subscriptionPlan: 'plus',
        gender: 'male',
        age: 25,
        country: 'US',
        isVerified: true,
        profileCompleteness: 80,
      );
    });

    test('onboarding events', () async {
      await service.logOnboardingStep(
        step: 'bio',
        stepNumber: 1,
        totalSteps: 5,
      );
      await service.logOnboardingCompleted(durationSeconds: 100);
      await service.logOnboardingAbandoned(lastStep: 'photos');
    });

    test('discovery events', () async {
      await service.logDeckLoaded(cardCount: 10);
      await service.logCardViewed(
        targetUserId: 't1',
        position: 1,
        viewDurationMs: 500,
      );
      await service.logSwipeRight(targetUserId: 't1', withMessage: true);
      await service.logSwipeLeft(targetUserId: 't2');
      await service.logMatch(matchId: 'm1');
      await service.logDeckEmpty();
      await service.logSuperLike(targetUserId: 't3');
      await service.logRewind();
      await service.logBoostActivated();
      await service.logBoostExpired(profileViewsGained: 50);
      await service.logTopPicksViewed(count: 5);
      await service.logLikesYouViewed(count: 3);
    });

    test('chat events', () async {
      await service.logConversationOpened(matchId: 'm1');
      await service.logFirstMessageSent(matchId: 'm1');
      await service.logMessageSent(matchId: 'm1', messageType: 'text');
      await service.logMediaSent(matchId: 'm1', mediaType: 'image');
      await service.logReactionAdded(emoji: '👍');
      await service.logUnmatch(matchId: 'm1');
      await service.logUserBlocked();
      await service.logUserReported(reason: 'spam');
    });

    test('call events', () async {
      await service.logCallStarted(matchId: 'm1', isVideo: true);
      await service.logCallEnded(durationSeconds: 60, isVideo: false);
    });

    test('profile events', () async {
      await service.logProfileViewed();
      await service.logProfileEditStarted();
      await service.logProfileUpdated(fieldsUpdated: ['bio', 'photos']);
      await service.logPhotoAdded(totalPhotos: 3);
      await service.logPhotoRemoved(totalPhotos: 2);
      await service.logBioUpdated(charCount: 50);
      await service.logOtherProfileViewed(source: 'discovery');
    });

    test('subscription events', () async {
      await service.logPaywallViewed(source: 'profile');
      await service.logCheckoutStarted(tier: 'plus');
      await service.logSubscriptionPurchased(
        tier: 'plus',
        price: 9.99,
        currency: 'USD',
      );
      await service.logSubscriptionCancelled(tier: 'plus');
      await service.logPremiumFeatureUsed(feature: 'passport');
      await service.logPremiumFeatureBlocked(feature: 'rewind');
    });

    test('settings events', () async {
      await service.logSettingsChanged(setting: 'theme', value: 'dark');
      await service.logDiscoveryPreferencesUpdated(
        minAge: 18,
        maxAge: 30,
        maxDistance: 50,
        genders: ['female'],
      );
      await service.logNotificationSettingsChanged(type: 'push', enabled: true);
    });

    test('screen view and error', () async {
      await service.logScreenView(screenName: 'Home');
      await service.logError(
        errorType: 'api',
        errorMessage: '500',
        screen: 'Login',
      );
    });
  });
}
