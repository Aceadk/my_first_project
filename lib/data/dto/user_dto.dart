import '../models/subscription.dart';
import '../models/user.dart';
import 'profile_dto.dart';

/// Data Transfer Object for User.
/// Separates wire format (API JSON) from domain model.
///
/// Wire format example:
/// ```json
/// {
///   "id": "user_123",
///   "phone_number": "+1234567890",
///   "email": "user@example.com",
///   "username": "johndoe",
///   "is_email_verified": true,
///   "is_phone_verified": true,
///   "is_id_verified": false,
///   "subscription_plan": "free",
///   "profile": { ... }
/// }
/// ```
class UserDto {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? username;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isIdVerified;
  final String subscriptionPlan;
  final String? themePreference;
  final ProfileDto? profile;

  const UserDto({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.username,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isIdVerified,
    required this.subscriptionPlan,
    this.themePreference,
    this.profile,
  });

  /// Create from JSON (API response).
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      phoneNumber:
          json['phone_number'] as String? ??
          json['phoneNumber'] as String? ??
          '',
      email: json['email'] as String?,
      username: json['username'] as String?,
      isEmailVerified:
          json['is_email_verified'] as bool? ??
          json['isEmailVerified'] as bool? ??
          json['email_verified'] as bool? ??
          false,
      isPhoneVerified:
          json['is_phone_verified'] as bool? ??
          json['isPhoneVerified'] as bool? ??
          json['phone_verified'] as bool? ??
          false,
      isIdVerified:
          json['is_id_verified'] as bool? ??
          json['isIdVerified'] as bool? ??
          json['id_verified'] as bool? ??
          false,
      subscriptionPlan:
          json['subscription_plan'] as String? ??
          json['subscriptionPlan'] as String? ??
          json['plan'] as String? ??
          'free',
      themePreference:
          json['theme_preference'] as String? ??
          json['themePreference'] as String? ??
          json['theme'] as String?,
      profile: json['profile'] != null
          ? ProfileDto.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON (API request).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_id_verified': isIdVerified,
      'subscription_plan': subscriptionPlan,
      if (themePreference != null) 'theme_preference': themePreference,
      if (profile != null) 'profile': profile!.toJson(),
    };
  }

  /// Convert to domain model.
  CrushUser toDomain() {
    return CrushUser(
      id: id,
      phoneNumber: phoneNumber,
      email: email,
      username: username,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      isIdVerified: isIdVerified,
      tier: _parsePlan(subscriptionPlan),
      themePreference: themePreference,
      profile: profile?.toDomain(),
    );
  }

  /// Create from domain model.
  factory UserDto.fromDomain(CrushUser user) {
    return UserDto(
      id: user.id,
      phoneNumber: user.phoneNumber,
      email: user.email,
      username: user.username,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      isIdVerified: user.isIdVerified,
      subscriptionPlan: _planToString(user.tier),
      themePreference: user.themePreference,
      profile: user.profile != null
          ? ProfileDto.fromDomain(user.profile!)
          : null,
    );
  }

  static SubscriptionTier _parsePlan(String tier) {
    switch (tier.toLowerCase()) {
      case 'plus':
      case 'premium':
      case 'pro':
        return SubscriptionTier.plus;
      case 'platinum':
        return SubscriptionTier.platinum;
      default:
        return SubscriptionTier.free;
    }
  }

  static String _planToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.platinum:
        return 'platinum';
      case SubscriptionTier.plus:
        return 'plus';
      case SubscriptionTier.free:
        return 'free';
    }
  }
}
