import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:crushhour/core/network/mappers/auth_mapper.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthMapper', () {
    const userDto = UserDto(
      id: 'u1',
      phoneNumber: '+1234567890',
      email: 'test@example.com',
      displayName: 'Tester',
      isVerified: true,
      isPremium: true,
    );

    test('userFromDto maps correctly', () {
      final user = AuthMapper.userFromDto(userDto);

      expect(user.id, 'u1');
      expect(user.phoneNumber, '+1234567890');
      expect(user.email, 'test@example.com');
      expect(user.username, 'Tester');
      expect(user.isIdVerified, true);
      expect(user.plan, SubscriptionPlan.plus);
      expect(user.isEmailVerified, true);
    });

    test('userFromDto handles explicit plan override', () {
      final user = AuthMapper.userFromDto(userDto, plan: SubscriptionPlan.free);
      expect(user.plan, SubscriptionPlan.free);
    });

    test('userToDto maps correctly', () {
      final user = AuthMapper.userFromDto(userDto);
      final mappedDto = AuthMapper.userToDto(user);

      expect(mappedDto.id, 'u1');
      expect(mappedDto.displayName, 'Tester');
      expect(mappedDto.isPremium, true);
    });

    test('userFromVerifyOtpResponse throws if user missing', () {
      const response = VerifyOtpResponseDto(success: true);
      expect(
        () => AuthMapper.userFromVerifyOtpResponse(response),
        throwsException,
      );
    });

    test('userFromVerifyOtpResponse returns user', () {
      const response = VerifyOtpResponseDto(success: true, user: userDto);
      final user = AuthMapper.userFromVerifyOtpResponse(response);
      expect(user.id, 'u1');
    });
  });
}
