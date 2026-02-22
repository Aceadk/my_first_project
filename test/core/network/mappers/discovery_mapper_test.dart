import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/core/network/mappers/discovery_mapper.dart';
import 'package:crushhour/data/models/match.dart';

void main() {
  group('DiscoveryMapper.profileFromDiscoveryDto', () {
    test('maps populated dto fields to profile model', () {
      const dto = DiscoveryProfileDto(
        id: 'profile-1',
        displayName: 'Riley',
        age: 27,
        bio: 'About me',
        photos: [
          ProfilePhotoDto(
            id: 'photo-1',
            url: 'https://example.com/1.jpg',
            isPrimary: false,
          ),
          ProfilePhotoDto(
            id: 'photo-2',
            url: 'https://example.com/2.jpg',
            isPrimary: true,
          ),
        ],
        distance: 4.2,
        distanceUnit: 'km',
        location: 'Paris',
        jobTitle: 'Designer',
        company: 'Crush',
        education: 'Academy',
        height: 170,
        interests: ['music', 'hiking'],
        isVerified: true,
      );

      final profile = DiscoveryMapper.profileFromDiscoveryDto(dto);

      expect(profile.id, 'profile-1');
      expect(profile.name, 'Riley');
      expect(profile.age, 27);
      expect(profile.bio, 'About me');
      expect(profile.photoUrls, [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
      expect(profile.primaryPhotoIndex, 1);
      expect(profile.distance, 4.2);
      expect(profile.distanceUnit, 'km');
      expect(profile.city, 'Paris');
      expect(profile.jobTitle, 'Designer');
      expect(profile.company, 'Crush');
      expect(profile.school, 'Academy');
      expect(profile.interests, ['music', 'hiking']);
      expect(profile.isVerified, isTrue);
      expect(profile.verificationBadge, 'verified');
    });

    test('applies defaults when optional fields are absent', () {
      const dto = DiscoveryProfileDto(id: 'profile-2', displayName: 'Jordan');
      final profile = DiscoveryMapper.profileFromDiscoveryDto(dto);

      expect(profile.age, 18);
      expect(profile.bio, isEmpty);
      expect(profile.photoUrls, isEmpty);
      expect(profile.primaryPhotoIndex, 0);
      expect(profile.city, isEmpty);
      expect(profile.isVerified, isFalse);
      expect(profile.verificationBadge, isNull);
    });
  });

  group('DiscoveryMapper.match conversions', () {
    test('matchFromDto maps match dto and current user id', () {
      const dto = MatchDto(
        id: 'match-1',
        userId: 'user-in-dto',
        matchedUserId: 'other-1',
        matchedUser: DiscoveryProfileDto(
          id: 'other-1',
          displayName: 'Casey',
          photos: [
            ProfilePhotoDto(
              id: 'photo-main',
              url: 'https://example.com/main.jpg',
              isPrimary: true,
            ),
          ],
        ),
      );

      final match = DiscoveryMapper.matchFromDto(dto, currentUserId: 'me-1');

      expect(match.id, 'match-1');
      expect(match.userId, 'me-1');
      expect(match.otherUserId, 'other-1');
      expect(match.status, MatchStatus.mutual);
      expect(match.otherUserName, 'Casey');
      expect(match.otherUserPhotoUrl, 'https://example.com/main.jpg');
    });

    test('matchToDto creates matched user payload when name is present', () {
      const match = CrushMatch(
        id: 'match-2',
        userId: 'me-2',
        otherUserId: 'other-2',
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount: 0,
        pinnedForUser: false,
        otherUserName: 'Taylor',
        otherUserPhotoUrl: 'https://example.com/other.jpg',
      );

      final dto = DiscoveryMapper.matchToDto(match);
      expect(dto.id, 'match-2');
      expect(dto.userId, 'me-2');
      expect(dto.matchedUserId, 'other-2');
      expect(dto.matchedUser, isNotNull);
      expect(dto.matchedUser!.displayName, 'Taylor');
      expect(dto.matchedUser!.photos, hasLength(1));
      expect(dto.matchedUser!.photos!.first.isPrimary, isTrue);
      expect(dto.isSuperLike, isFalse);
    });

    test('matchToDto omits matched user payload when display name missing', () {
      const match = CrushMatch(
        id: 'match-3',
        userId: 'me-3',
        otherUserId: 'other-3',
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount: 0,
        pinnedForUser: false,
      );

      final dto = DiscoveryMapper.matchToDto(match);
      expect(dto.matchedUser, isNull);
    });
  });

  group('DiscoveryMapper.swipeActionToDto', () {
    test('returns super like when explicitly requested', () {
      expect(
        DiscoveryMapper.swipeActionToDto(false, isSuperLike: true),
        SwipeAction.superLike,
      );
    });

    test('returns like or pass for normal actions', () {
      expect(DiscoveryMapper.swipeActionToDto(true), SwipeAction.like);
      expect(DiscoveryMapper.swipeActionToDto(false), SwipeAction.pass);
    });
  });
}
