import 'base_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUTH REQUEST DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Request to send OTP to phone number.
class SendOtpRequestDto extends BaseDto {
  const SendOtpRequestDto({
    required this.phoneNumber,
    this.countryCode,
    this.recaptchaToken,
  });

  final String phoneNumber;
  final String? countryCode;
  final String? recaptchaToken;

  factory SendOtpRequestDto.fromJson(Map<String, dynamic> json) {
    return SendOtpRequestDto(
      phoneNumber: json.getString('phone_number') ?? '',
      countryCode: json.getString('country_code'),
      recaptchaToken: json.getString('recaptcha_token'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        if (countryCode != null) 'country_code': countryCode,
        if (recaptchaToken != null) 'recaptcha_token': recaptchaToken,
      };

  @override
  String? validate() {
    return DtoValidator()
        .requireNotEmpty(phoneNumber, 'phone_number')
        .requireMinLength(phoneNumber, 10, 'phone_number')
        .build()
        .firstError;
  }
}

/// Request to verify OTP.
class VerifyOtpRequestDto extends BaseDto {
  const VerifyOtpRequestDto({
    required this.phoneNumber,
    required this.otp,
    this.verificationId,
  });

  final String phoneNumber;
  final String otp;
  final String? verificationId;

  factory VerifyOtpRequestDto.fromJson(Map<String, dynamic> json) {
    return VerifyOtpRequestDto(
      phoneNumber: json.getString('phone_number') ?? '',
      otp: json.getString('otp') ?? '',
      verificationId: json.getString('verification_id'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'otp': otp,
        if (verificationId != null) 'verification_id': verificationId,
      };

  @override
  String? validate() {
    return DtoValidator()
        .requireNotEmpty(phoneNumber, 'phone_number')
        .requireNotEmpty(otp, 'otp')
        .require(otp.length == 6, 'otp', 'OTP must be 6 digits')
        .build()
        .firstError;
  }
}

/// Request to refresh auth token.
class RefreshTokenRequestDto extends BaseDto {
  const RefreshTokenRequestDto({
    required this.refreshToken,
  });

  final String refreshToken;

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequestDto(
      refreshToken: json.getString('refresh_token') ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };

  @override
  String? validate() {
    return DtoValidator()
        .requireNotEmpty(refreshToken, 'refresh_token')
        .build()
        .firstError;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH RESPONSE DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Response from sending OTP.
class SendOtpResponseDto extends BaseDto {
  const SendOtpResponseDto({
    required this.success,
    this.verificationId,
    this.expiresAt,
    this.message,
  });

  final bool success;
  final String? verificationId;
  final DateTime? expiresAt;
  final String? message;

  factory SendOtpResponseDto.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseDto(
      success: json.getBool('success') ?? false,
      verificationId: json.getString('verification_id'),
      expiresAt: json.getDateTime('expires_at'),
      message: json.getString('message'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'success': success,
        if (verificationId != null) 'verification_id': verificationId,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (message != null) 'message': message,
      };
}

/// Response from verifying OTP.
class VerifyOtpResponseDto extends BaseDto {
  const VerifyOtpResponseDto({
    required this.success,
    this.user,
    this.tokens,
    this.isNewUser,
    this.message,
  });

  final bool success;
  final UserDto? user;
  final AuthTokensDto? tokens;
  final bool? isNewUser;
  final String? message;

  factory VerifyOtpResponseDto.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseDto(
      success: json.getBool('success') ?? false,
      user: json.getMap('user') != null
          ? UserDto.fromJson(json.getMap('user')!)
          : null,
      tokens: json.getMap('tokens') != null
          ? AuthTokensDto.fromJson(json.getMap('tokens')!)
          : null,
      isNewUser: json.getBool('is_new_user'),
      message: json.getString('message'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'success': success,
        if (user != null) 'user': user!.toJson(),
        if (tokens != null) 'tokens': tokens!.toJson(),
        if (isNewUser != null) 'is_new_user': isNewUser,
        if (message != null) 'message': message,
      };
}

/// Auth tokens response.
class AuthTokensDto extends BaseDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
  final String tokenType;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    return AuthTokensDto(
      accessToken: json.getString('access_token') ?? '',
      refreshToken: json.getString('refresh_token') ?? '',
      expiresIn: json.getInt('expires_in'),
      tokenType: json.getString('token_type') ?? 'Bearer',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (expiresIn != null) 'expires_in': expiresIn,
        'token_type': tokenType,
      };

  /// Get expiration DateTime.
  DateTime? get expiresAt {
    if (expiresIn == null) return null;
    return DateTime.now().add(Duration(seconds: expiresIn!));
  }
}

/// Basic user DTO returned with auth.
class UserDto extends BaseDto with DtoMetadata {
  const UserDto({
    required this.id,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isVerified,
    this.isPremium,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool? isVerified;
  final bool? isPremium;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String? get serverId => id;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json.getString('id') ?? '',
      phoneNumber: json.getString('phone_number'),
      email: json.getString('email'),
      displayName: json.getString('display_name'),
      photoUrl: json.getString('photo_url'),
      isVerified: json.getBool('is_verified'),
      isPremium: json.getBool('is_premium'),
      createdAt: json.getDateTime('created_at'),
      updatedAt: json.getDateTime('updated_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
        if (displayName != null) 'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (isVerified != null) 'is_verified': isVerified,
        if (isPremium != null) 'is_premium': isPremium,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}
