import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendOtpRequestDto', () {
    test('validate enforces phone number length', () {
      const req = SendOtpRequestDto(phoneNumber: '123');
      expect(req.validate(), isNotNull);
    });

    test('toJson includes params', () {
      const req = SendOtpRequestDto(
        phoneNumber: '1234567890',
        countryCode: 'US',
      );
      final json = req.toJson();
      expect(json['phone_number'], '1234567890');
      expect(json['country_code'], 'US');
    });
  });

  group('VerifyOtpRequestDto', () {
    test('validate enforces otp length', () {
      const req = VerifyOtpRequestDto(phoneNumber: '1234567890', otp: '123');
      expect(req.validate(), isNotNull);
    });

    test('validate allows valid otp', () {
      const req = VerifyOtpRequestDto(phoneNumber: '1234567890', otp: '123456');
      expect(req.validate(), isNull);
    });
  });

  group('AuthTokensDto', () {
    test('expiresAt calculates correctly', () {
      const dto = AuthTokensDto(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 3600,
      );

      final expires = dto.expiresAt;
      expect(expires, isNotNull);
      expect(expires!.isAfter(DateTime.now()), true);
    });
  });

  group('UserDto', () {
    test('serverId returns id', () {
      const dto = UserDto(id: 'u1');
      expect(dto.serverId, 'u1');
    });

    test('fromJson handles nulls', () {
      final dto = UserDto.fromJson({'id': 'u1'});
      expect(dto.id, 'u1');
      expect(dto.displayName, isNull);
    });
  });
}
