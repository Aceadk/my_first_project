import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'subscription.dart';

class CrushUser extends Equatable {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? username;
  final DateTime? lastUsernameChangeAt;
  final bool isEmailVerified;
  final Profile? profile;
  final bool isPhoneVerified;
  final bool isIdVerified;
  final SubscriptionPlan plan;
  final String? themePreference;
  final bool hasAcceptedTerms;

  /// Flag indicating user skipped basic info (can still complete later in settings)
  final bool hasSkippedBasicInfo;

  /// Flag indicating user skipped profile setup (can still complete later in settings)
  final bool hasSkippedProfileSetup;

  /// Check if user can change their username (once every 28 days)
  bool get canChangeUsername {
    if (lastUsernameChangeAt == null) return true;
    final daysSinceLastChange =
        DateTime.now().difference(lastUsernameChangeAt!).inDays;
    return daysSinceLastChange >= 28;
  }

  /// Days remaining until username can be changed again
  int get daysUntilUsernameChange {
    if (lastUsernameChangeAt == null) return 0;
    final daysSinceLastChange =
        DateTime.now().difference(lastUsernameChangeAt!).inDays;
    return (28 - daysSinceLastChange).clamp(0, 28);
  }

  const CrushUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.username,
    this.lastUsernameChangeAt,
    required this.isEmailVerified,
    this.profile,
    required this.isPhoneVerified,
    required this.isIdVerified,
    required this.plan,
    this.themePreference,
    this.hasAcceptedTerms = false,
    this.hasSkippedBasicInfo = false,
    this.hasSkippedProfileSetup = false,
  });

  /// User can swipe if EITHER email OR phone is verified (not both required)
  bool get isAccountVerified => isEmailVerified || isPhoneVerified;

  bool get canChat => isIdVerified;

  /// Check if user has completed basic info (name, age, gender) OR skipped it
  bool get hasCompletedBasicInfo {
    if (hasSkippedBasicInfo) return true;
    if (profile == null) return false;
    return profile!.age > 0 && profile!.gender.isNotEmpty;
  }

  /// Check if user has completed profile setup (at least one photo) OR skipped it
  bool get hasCompletedProfileSetup {
    if (hasSkippedProfileSetup) return true;
    if (profile == null) return false;
    return profile!.photoUrls.isNotEmpty || profile!.videoUrls.isNotEmpty;
  }

  /// Check if all onboarding steps are complete
  bool get isOnboardingComplete {
    return hasAcceptedTerms &&
        hasCompletedBasicInfo &&
        hasCompletedProfileSetup;
  }

  /// Sentinel object for copyWith null handling
  static const _unset = Object();

  CrushUser copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? username,
    Object? lastUsernameChangeAt = _unset,
    bool? isEmailVerified,
    Profile? profile,
    bool? isPhoneVerified,
    bool? isIdVerified,
    SubscriptionPlan? plan,
    String? themePreference,
    bool? hasAcceptedTerms,
    bool? hasSkippedBasicInfo,
    bool? hasSkippedProfileSetup,
  }) {
    return CrushUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      username: username ?? this.username,
      lastUsernameChangeAt: identical(lastUsernameChangeAt, _unset)
          ? this.lastUsernameChangeAt
          : lastUsernameChangeAt as DateTime?,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profile: profile ?? this.profile,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      plan: plan ?? this.plan,
      themePreference: themePreference ?? this.themePreference,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      hasSkippedBasicInfo: hasSkippedBasicInfo ?? this.hasSkippedBasicInfo,
      hasSkippedProfileSetup:
          hasSkippedProfileSetup ?? this.hasSkippedProfileSetup,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        email,
        username,
        lastUsernameChangeAt,
        isEmailVerified,
        profile,
        isPhoneVerified,
        isIdVerified,
        plan,
        themePreference,
        hasAcceptedTerms,
        hasSkippedBasicInfo,
        hasSkippedProfileSetup,
      ];
}
