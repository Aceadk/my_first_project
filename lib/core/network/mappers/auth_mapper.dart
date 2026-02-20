import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/subscription.dart';

/// Mapper for auth-related DTOs to domain models.
class AuthMapper {
  AuthMapper._();

  /// Convert UserDto to CrushUser domain model.
  static CrushUser userFromDto(UserDto dto, {SubscriptionPlan? plan}) {
    return CrushUser(
      id: dto.id,
      phoneNumber: dto.phoneNumber ?? '',
      email: dto.email,
      username: dto.displayName,
      isEmailVerified: dto.email != null,
      isPhoneVerified: dto.phoneNumber != null,
      isIdVerified: dto.isVerified ?? false,
      plan:
          plan ??
          (dto.isPremium == true
              ? SubscriptionPlan.plus
              : SubscriptionPlan.free),
      profile: null, // Profile loaded separately
    );
  }

  /// Convert CrushUser to UserDto for API requests.
  static UserDto userToDto(CrushUser user) {
    return UserDto(
      id: user.id,
      phoneNumber: user.phoneNumber,
      email: user.email,
      displayName: user.username,
      isVerified: user.isIdVerified,
      isPremium: user.plan.isPlus,
    );
  }

  /// Create CrushUser from verify OTP response.
  static CrushUser userFromVerifyOtpResponse(VerifyOtpResponseDto response) {
    if (response.user == null) {
      throw Exception('User data missing from verify OTP response');
    }
    return userFromDto(response.user!);
  }
}
