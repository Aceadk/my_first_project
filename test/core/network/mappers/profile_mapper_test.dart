import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/core/network/mappers/profile_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMapper', () {
    const profileId = 'user-123';
    final birthDate = DateTime(1995, 5, 20);

    final dto = ProfileDto(
      id: profileId,
      displayName: 'Alice',
      birthDate: birthDate,
      gender: 'woman',
      photos: [
        const ProfilePhotoDto(id: 'p1', url: 'url1.jpg', isPrimary: true),
        const ProfilePhotoDto(id: 'p2', url: 'url2.jpg', isPrimary: false),
      ],
      location: const LocationDto(
        latitude: 37.7749,
        longitude: -122.4194,
        city: 'San Francisco',
        country: 'USA',
      ),
      height: 170,
      jobTitle: 'Developer',
      company: 'Tech Corp',
    );

    test('profileFromDto maps correctly', () {
      final profile = ProfileMapper.profileFromDto(dto);

      expect(profile.id, profileId);
      expect(profile.name, 'Alice');
      expect(profile.gender, 'woman');
      expect(profile.photoUrls.length, 2);
      expect(profile.primaryPhotoIndex, 0);
      expect(profile.city, 'San Francisco');
      expect(profile.heightCm, 170);
      expect(profile.jobTitle, 'Developer');
      expect(profile.company, 'Tech Corp');
    });

    test('profileToDto maps correctly', () {
      final profile = ProfileMapper.profileFromDto(dto);
      final mappedDto = ProfileMapper.profileToDto(profile);

      expect(mappedDto.id, profileId);
      expect(mappedDto.displayName, 'Alice');
      expect(mappedDto.gender, 'woman');
      expect(mappedDto.photos?.length, 2);
      expect(mappedDto.location?.city, 'San Francisco');
    });

    test('profileToUpdateRequest maps correctly', () {
      final profile = ProfileMapper.profileFromDto(dto);
      final request = ProfileMapper.profileToUpdateRequest(profile);

      expect(request.displayName, 'Alice');
      expect(request.jobTitle, 'Developer');
      expect(request.height, 170);
      expect(request.bio, isEmpty);
    });

    test('calculateAge works correctly', () {
      // Indirectly tested via profileFromDto, but let's be explicit if method was public.
      // Since it's private, we rely on the public method.
      final profile = ProfileMapper.profileFromDto(dto);
      final now = DateTime.now();
      final expectedAge =
          now.year -
          birthDate.year -
          (now.month < birthDate.month ||
                  (now.month == birthDate.month && now.day < birthDate.day)
              ? 1
              : 0);
      expect(profile.age, expectedAge);
    });

    test('findPrimaryPhotoIndex handles null/empty', () {
      const emptyDto = ProfileDto(id: '1', photos: []);
      final profile = ProfileMapper.profileFromDto(emptyDto);
      expect(profile.primaryPhotoIndex, 0);
    });
  });
}
