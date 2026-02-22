import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendOtpRequestDto', () {
    test('fromJson parses all supported fields', () {
      final dto = SendOtpRequestDto.fromJson(<String, dynamic>{
        'phone_number': '+15551234567',
        'country_code': 'US',
        'recaptcha_token': 'token-1',
      });

      expect(dto.phoneNumber, '+15551234567');
      expect(dto.countryCode, 'US');
      expect(dto.recaptchaToken, 'token-1');
    });

    test('toJson includes optional fields only when present', () {
      const withOptionals = SendOtpRequestDto(
        phoneNumber: '+15551234567',
        countryCode: 'US',
        recaptchaToken: 'token-1',
      );
      expect(withOptionals.toJson(), <String, dynamic>{
        'phone_number': '+15551234567',
        'country_code': 'US',
        'recaptcha_token': 'token-1',
      });

      const minimal = SendOtpRequestDto(phoneNumber: '+15551234567');
      expect(minimal.toJson(), <String, dynamic>{
        'phone_number': '+15551234567',
      });
    });

    test('validate enforces non-empty and minimum length phone number', () {
      const empty = SendOtpRequestDto(phoneNumber: '');
      const short = SendOtpRequestDto(phoneNumber: '12345');
      const valid = SendOtpRequestDto(phoneNumber: '1234567890');

      expect(empty.validate(), isNotNull);
      expect(short.validate(), isNotNull);
      expect(valid.validate(), isNull);
    });
  });

  group('VerifyOtpRequestDto', () {
    test('fromJson parses payload values', () {
      final dto = VerifyOtpRequestDto.fromJson(<String, dynamic>{
        'phone_number': '+15551234567',
        'otp': '123456',
        'verification_id': 'ver-1',
      });

      expect(dto.phoneNumber, '+15551234567');
      expect(dto.otp, '123456');
      expect(dto.verificationId, 'ver-1');
    });

    test('toJson includes verification id when provided', () {
      const withId = VerifyOtpRequestDto(
        phoneNumber: '+15551234567',
        otp: '123456',
        verificationId: 'ver-1',
      );
      expect(withId.toJson(), <String, dynamic>{
        'phone_number': '+15551234567',
        'otp': '123456',
        'verification_id': 'ver-1',
      });

      const withoutId = VerifyOtpRequestDto(
        phoneNumber: '+15551234567',
        otp: '123456',
      );
      expect(withoutId.toJson(), <String, dynamic>{
        'phone_number': '+15551234567',
        'otp': '123456',
      });
    });

    test('validate enforces phone presence and 6-digit OTP', () {
      const missingPhone = VerifyOtpRequestDto(phoneNumber: '', otp: '123456');
      const missingOtp = VerifyOtpRequestDto(
        phoneNumber: '1234567890',
        otp: '',
      );
      const shortOtp = VerifyOtpRequestDto(
        phoneNumber: '1234567890',
        otp: '123',
      );
      const valid = VerifyOtpRequestDto(
        phoneNumber: '1234567890',
        otp: '123456',
      );

      expect(missingPhone.validate(), isNotNull);
      expect(missingOtp.validate(), isNotNull);
      expect(shortOtp.validate(), isNotNull);
      expect(valid.validate(), isNull);
    });
  });

  group('RefreshTokenRequestDto', () {
    test('fromJson/toJson/validate cover happy and error paths', () {
      final parsed = RefreshTokenRequestDto.fromJson(<String, dynamic>{
        'refresh_token': 'r-123',
      });
      expect(parsed.refreshToken, 'r-123');
      expect(parsed.toJson(), <String, dynamic>{'refresh_token': 'r-123'});
      expect(parsed.validate(), isNull);

      const invalid = RefreshTokenRequestDto(refreshToken: '');
      expect(invalid.validate(), isNotNull);
    });
  });

  group('SendOtpResponseDto', () {
    test('fromJson parses optional payload and toJson serializes it', () {
      final dto = SendOtpResponseDto.fromJson(<String, dynamic>{
        'success': true,
        'verification_id': 'ver-1',
        'expires_at': '2026-02-21T12:00:00.000Z',
        'message': 'sent',
      });

      expect(dto.success, isTrue);
      expect(dto.verificationId, 'ver-1');
      expect(dto.expiresAt, isNotNull);
      expect(dto.message, 'sent');

      final json = dto.toJson();
      expect(json['success'], isTrue);
      expect(json['verification_id'], 'ver-1');
      expect(json['expires_at'], isNotNull);
      expect(json['message'], 'sent');
    });
  });

  group('VerifyOtpResponseDto', () {
    test('fromJson parses nested user and token DTOs', () {
      final dto = VerifyOtpResponseDto.fromJson(<String, dynamic>{
        'success': true,
        'user': <String, dynamic>{
          'id': 'u1',
          'phone_number': '+15551234567',
          'email': 'user@example.com',
        },
        'tokens': <String, dynamic>{
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 3600,
          'token_type': 'Bearer',
        },
        'is_new_user': false,
        'message': 'ok',
      });

      expect(dto.success, isTrue);
      expect(dto.user?.id, 'u1');
      expect(dto.tokens?.accessToken, 'a');
      expect(dto.isNewUser, isFalse);
      expect(dto.message, 'ok');
    });

    test('toJson serializes nested fields and optionals correctly', () {
      const dto = VerifyOtpResponseDto(
        success: true,
        user: UserDto(id: 'u1', email: 'user@example.com'),
        tokens: AuthTokensDto(
          accessToken: 'a',
          refreshToken: 'r',
          expiresIn: 10,
        ),
        isNewUser: true,
        message: 'welcome',
      );

      final json = dto.toJson();
      expect(json['success'], isTrue);
      expect(json['user'], isA<Map<String, dynamic>>());
      expect(json['tokens'], isA<Map<String, dynamic>>());
      expect(json['is_new_user'], isTrue);
      expect(json['message'], 'welcome');
    });
  });

  group('AuthTokensDto', () {
    test(
      'fromJson uses defaults for missing token_type and toJson maps fields',
      () {
        final dto = AuthTokensDto.fromJson(<String, dynamic>{
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 3600,
        });

        expect(dto.accessToken, 'a');
        expect(dto.refreshToken, 'r');
        expect(dto.expiresIn, 3600);
        expect(dto.tokenType, 'Bearer');

        expect(dto.toJson(), <String, dynamic>{
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 3600,
          'token_type': 'Bearer',
        });
      },
    );

    test('expiresAt handles null and non-null durations', () {
      const noExpiry = AuthTokensDto(accessToken: 'a', refreshToken: 'r');
      expect(noExpiry.expiresAt, isNull);

      const withExpiry = AuthTokensDto(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 60,
      );
      expect(withExpiry.expiresAt, isNotNull);
      expect(withExpiry.expiresAt!.isAfter(DateTime.now()), isTrue);
    });
  });

  group('UserDto', () {
    test('serverId returns id', () {
      const dto = UserDto(id: 'u-1');
      expect(dto.serverId, 'u-1');
    });

    test('fromJson parses full payload and toJson omits null optionals', () {
      final dto = UserDto.fromJson(<String, dynamic>{
        'id': 'u-1',
        'phone_number': '+15551234567',
        'email': 'user@example.com',
        'display_name': 'Test User',
        'photo_url': 'https://example.com/photo.jpg',
        'is_verified': true,
        'is_premium': false,
        'created_at': '2026-02-21T12:00:00.000Z',
        'updated_at': '2026-02-22T12:00:00.000Z',
      });

      expect(dto.id, 'u-1');
      expect(dto.phoneNumber, '+15551234567');
      expect(dto.email, 'user@example.com');
      expect(dto.displayName, 'Test User');
      expect(dto.photoUrl, 'https://example.com/photo.jpg');
      expect(dto.isVerified, isTrue);
      expect(dto.isPremium, isFalse);
      expect(dto.createdAt, isNotNull);
      expect(dto.updatedAt, isNotNull);

      final json = dto.toJson();
      expect(json['id'], 'u-1');
      expect(json['phone_number'], '+15551234567');
      expect(json['email'], 'user@example.com');
      expect(json['display_name'], 'Test User');
      expect(json['photo_url'], 'https://example.com/photo.jpg');
      expect(json['is_verified'], isTrue);
      expect(json['is_premium'], isFalse);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('fromJson handles sparse payload without crashing', () {
      final dto = UserDto.fromJson(<String, dynamic>{'id': 'u-2'});
      expect(dto.id, 'u-2');
      expect(dto.displayName, isNull);
      expect(dto.toJson(), <String, dynamic>{'id': 'u-2'});
    });
  });
}
