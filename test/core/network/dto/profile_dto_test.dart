import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileDto', () {
    const profileId = 'user-123';
    final birthDate = DateTime(1995, 5, 20);

    final validProfileJson = {
      'id': profileId,
      'display_name': 'Alice',
      'birth_date': birthDate.toIso8601String(),
      'gender': 'woman',
      'photos': [
        {'id': 'p1', 'url': 'url1.jpg', 'is_primary': true},
        {'id': 'p2', 'url': 'url2.jpg', 'is_primary': false},
      ],
      'location': {
        'latitude': 37.7749,
        'longitude': -122.4194,
        'city': 'San Francisco',
        'country': 'USA',
      },
    };

    test('fromJson creates correct instance', () {
      final dto = ProfileDto.fromJson(validProfileJson);

      expect(dto.id, profileId);
      expect(dto.displayName, 'Alice');
      expect(dto.birthDate, birthDate);
      expect(dto.gender, 'woman');
      expect(dto.photos?.length, 2);
      expect(dto.photos?.first.url, 'url1.jpg');
      expect(dto.location?.city, 'San Francisco');
    });

    test('toJson returns correct map', () {
      final dto = ProfileDto.fromJson(validProfileJson);
      final json = dto.toJson();

      expect(json['id'], profileId);
      expect(json['display_name'], 'Alice');
      expect(json['gender'], 'woman');
      expect(json['photos'], isNotEmpty);
      expect(json['location'], isNotEmpty);
    });

    test('age calculation is correct', () {
      final now = DateTime.now();
      final dto = ProfileDto(
        id: '1',
        birthDate: DateTime(now.year - 25, now.month, now.day),
      );
      expect(dto.age, 25);
    });

    test('primaryPhotoUrl returns correct url', () {
      final dto = ProfileDto.fromJson(validProfileJson);
      expect(dto.primaryPhotoUrl, 'url1.jpg');
    });

    test('copyWith updates fields correctly', () {
      final dto = ProfileDto.fromJson(validProfileJson);
      final updated = dto.copyWith(displayName: 'Bob');

      expect(updated.displayName, 'Bob');
      expect(updated.id, dto.id);
      expect(updated.gender, dto.gender);
    });
  });

  group('UpdateProfileRequestDto', () {
    test('toJson excludes null fields', () {
      const request = UpdateProfileRequestDto(displayName: 'New Name');
      final json = request.toJson();

      expect(json.keys.length, 1);
      expect(json['display_name'], 'New Name');
      expect(json.containsKey('bio'), false);
    });

    test('validate returns error for short display name', () {
      const request = UpdateProfileRequestDto(displayName: 'A');
      expect(request.validate(), isNotNull);
    });

    test('validate returns null for valid name', () {
      const request = UpdateProfileRequestDto(displayName: 'Alice');
      expect(request.validate(), isNull);
    });
  });
}
