import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrushUser hotspot branches', () {
    test('username cooldown helpers compute correctly and clamp values', () {
      final neverChanged = _buildUser(lastUsernameChangeAt: null);
      expect(neverChanged.canChangeUsername, isTrue);
      expect(neverChanged.daysUntilUsernameChange, 0);

      final recentlyChanged = _buildUser(
        lastUsernameChangeAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(recentlyChanged.canChangeUsername, isFalse);
      expect(recentlyChanged.daysUntilUsernameChange, 23);

      final changedLongAgo = _buildUser(
        lastUsernameChangeAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      expect(changedLongAgo.canChangeUsername, isTrue);
      expect(changedLongAgo.daysUntilUsernameChange, 0);
    });

    test(
      'account verification and onboarding derived flags respect profile and skips',
      () {
        final phoneVerifiedOnly = _buildUser(
          isEmailVerified: false,
          isPhoneVerified: true,
          profile: _buildProfile(photoUrls: const <String>[]),
        );
        expect(phoneVerifiedOnly.isAccountVerified, isTrue);
        expect(phoneVerifiedOnly.hasCompletedBasicInfo, isTrue);
        expect(phoneVerifiedOnly.hasCompletedProfileSetup, isFalse);
        expect(phoneVerifiedOnly.isOnboardingComplete, isFalse);

        final unverifiedNoProfile = _buildUser(
          isEmailVerified: false,
          isPhoneVerified: false,
          includeProfile: false,
        );
        expect(unverifiedNoProfile.isAccountVerified, isFalse);
        expect(unverifiedNoProfile.hasCompletedBasicInfo, isFalse);
        expect(unverifiedNoProfile.hasCompletedProfileSetup, isFalse);

        final skippedFlow = _buildUser(
          hasAcceptedTerms: true,
          includeProfile: false,
          hasSkippedBasicInfo: true,
          hasSkippedProfileSetup: true,
        );
        expect(skippedFlow.hasCompletedBasicInfo, isTrue);
        expect(skippedFlow.hasCompletedProfileSetup, isTrue);
        expect(skippedFlow.isOnboardingComplete, isTrue);
      },
    );

    test(
      'copyWith preserves fields by default and can explicitly clear nullable values',
      () {
        final original = _buildUser(
          username: 'original_user',
          lastUsernameChangeAt: DateTime(2026, 2, 1),
          hasAcceptedTerms: false,
        );

        final preserved = original.copyWith();
        expect(preserved.lastUsernameChangeAt, original.lastUsernameChangeAt);
        expect(preserved.username, 'original_user');

        final changed = original.copyWith(
          username: 'new_user',
          hasAcceptedTerms: true,
        );
        expect(changed.username, 'new_user');
        expect(changed.hasAcceptedTerms, isTrue);
        expect(changed.lastUsernameChangeAt, original.lastUsernameChangeAt);

        final clearedTimestamp = original.copyWith(lastUsernameChangeAt: null);
        expect(clearedTimestamp.lastUsernameChangeAt, isNull);
        expect(clearedTimestamp.username, original.username);
      },
    );
  });
}

CrushUser _buildUser({
  String? username = 'test_user',
  DateTime? lastUsernameChangeAt,
  bool isEmailVerified = true,
  bool isPhoneVerified = false,
  bool hasAcceptedTerms = false,
  bool hasSkippedBasicInfo = false,
  bool hasSkippedProfileSetup = false,
  bool includeProfile = true,
  Profile? profile,
}) {
  return CrushUser(
    id: 'user_1',
    phoneNumber: '+15550000000',
    email: 'user_1@example.com',
    username: username,
    lastUsernameChangeAt: lastUsernameChangeAt,
    isEmailVerified: isEmailVerified,
    profile: includeProfile ? (profile ?? _buildProfile()) : null,
    isPhoneVerified: isPhoneVerified,
    isIdVerified: false,
    tier: SubscriptionTier.free,
    hasAcceptedTerms: hasAcceptedTerms,
    hasSkippedBasicInfo: hasSkippedBasicInfo,
    hasSkippedProfileSetup: hasSkippedProfileSetup,
  );
}

Profile _buildProfile({
  int age = 27,
  String gender = 'female',
  List<String> photoUrls = const <String>['https://cdn.example.com/photo.jpg'],
  List<String> videoUrls = const <String>[],
}) {
  return Profile(
    id: 'profile_1',
    username: 'test_user',
    name: 'Test',
    age: age,
    gender: gender,
    bio: 'Test bio',
    photoUrls: photoUrls,
    videoUrls: videoUrls,
    interests: const <String>['music'],
    country: 'US',
    city: 'Austin',
    isVerified: false,
    preferences: const DiscoveryPreferences(
      minAge: 18,
      maxAge: 40,
      maxDistanceKm: 100,
      showMeGenders: <String>['male', 'female'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: '',
      city: '',
    ),
  );
}
