import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/network/dto/discovery_dto.dart';

void main() {
  group('DiscoveryDeckDto', () {
    test('fromJson reads candidates key and optional metadata', () {
      final dto = DiscoveryDeckDto.fromJson({
        'candidates': [
          {
            'id': 'p1',
            'display_name': 'Alex',
            'photos': [
              {'id': 'photo-1', 'url': 'https://example.com/1.jpg'},
            ],
          },
        ],
        'remaining_swipes': 9,
        'next_refresh_at': '2026-02-21T10:00:00.000Z',
        'boost_active': true,
        'boost_expires_at': '2026-02-21T11:00:00.000Z',
      });

      expect(dto.profiles, hasLength(1));
      expect(dto.profiles.first.id, 'p1');
      expect(dto.remainingSwipes, 9);
      expect(dto.nextRefreshAt, DateTime.parse('2026-02-21T10:00:00.000Z'));
      expect(dto.boostActive, isTrue);
      expect(dto.boostExpiresAt, DateTime.parse('2026-02-21T11:00:00.000Z'));
    });

    test('fromJson falls back to legacy profiles key', () {
      final dto = DiscoveryDeckDto.fromJson({
        'profiles': [
          {'id': 'legacy', 'display_name': 'Legacy Name'},
        ],
      });

      expect(dto.profiles, hasLength(1));
      expect(dto.profiles.first.id, 'legacy');
      expect(dto.profiles.first.displayName, 'Legacy Name');
    });

    test('toJson serializes optional values when present', () {
      final dto = DiscoveryDeckDto(
        profiles: const [DiscoveryProfileDto(id: 'p2', displayName: 'Taylor')],
        remainingSwipes: 5,
        nextRefreshAt: DateTime.parse('2026-02-21T12:00:00.000Z'),
        boostActive: false,
        boostExpiresAt: DateTime.parse('2026-02-21T13:00:00.000Z'),
      );

      final json = dto.toJson();
      expect(json['profiles'], isA<List<dynamic>>());
      expect(json['remaining_swipes'], 5);
      expect(json['boost_active'], isFalse);
      expect(json['next_refresh_at'], '2026-02-21T12:00:00.000Z');
      expect(json['boost_expires_at'], '2026-02-21T13:00:00.000Z');
    });
  });

  group('DiscoveryProfileDto', () {
    test('primaryPhotoUrl prefers primary flag and falls back to first', () {
      final withPrimary = DiscoveryProfileDto.fromJson({
        'id': 'p3',
        'display_name': 'Jordan',
        'photos': [
          {'id': 'photo-a', 'url': 'https://example.com/a.jpg'},
          {
            'id': 'photo-b',
            'url': 'https://example.com/b.jpg',
            'is_primary': true,
          },
        ],
      });
      expect(withPrimary.primaryPhotoUrl, 'https://example.com/b.jpg');

      final withoutPrimary = DiscoveryProfileDto.fromJson({
        'id': 'p4',
        'display_name': 'Casey',
        'photos': [
          {'id': 'photo-c', 'url': 'https://example.com/c.jpg'},
        ],
      });
      expect(withoutPrimary.primaryPhotoUrl, 'https://example.com/c.jpg');

      const noPhotos = DiscoveryProfileDto(id: 'p5', displayName: 'No Photo');
      expect(noPhotos.primaryPhotoUrl, isNull);
    });

    test('distanceDisplay handles null, less-than-one and rounded values', () {
      const noDistance = DiscoveryProfileDto(id: 'p6', displayName: 'None');
      expect(noDistance.distanceDisplay, isNull);

      const near = DiscoveryProfileDto(
        id: 'p7',
        displayName: 'Near',
        distance: 0.4,
      );
      expect(near.distanceDisplay, 'Less than 1 km away');

      const miles = DiscoveryProfileDto(
        id: 'p8',
        displayName: 'Miles',
        distance: 3.7,
        distanceUnit: 'mi',
      );
      expect(miles.distanceDisplay, '4 mi away');
    });

    test(
      'fromJson parses all optional properties and toJson mirrors shape',
      () {
        final dto = DiscoveryProfileDto.fromJson({
          'id': 'p9',
          'display_name': 'Morgan',
          'age': 29,
          'bio': 'Bio text',
          'distance': 2.2,
          'distance_unit': 'km',
          'location': 'Berlin',
          'job_title': 'Engineer',
          'company': 'Crush Inc',
          'education': 'University',
          'height': 175,
          'interests': ['music', 'travel'],
          'is_verified': true,
          'is_premium': false,
          'last_active': '2026-02-21T08:00:00.000Z',
          'common_interests': ['music'],
          'common_connections': 2,
        });

        expect(dto.id, 'p9');
        expect(dto.displayName, 'Morgan');
        expect(dto.age, 29);
        expect(dto.interests, ['music', 'travel']);
        expect(dto.lastActive, DateTime.parse('2026-02-21T08:00:00.000Z'));
        expect(dto.commonConnections, 2);

        final json = dto.toJson();
        expect(json['id'], 'p9');
        expect(json['display_name'], 'Morgan');
        expect(json['common_connections'], 2);
        expect(json['last_active'], '2026-02-21T08:00:00.000Z');
      },
    );
  });

  group('SwipeAction', () {
    test('fromJson returns matching value and defaults to pass', () {
      expect(SwipeAction.fromJson('like'), SwipeAction.like);
      expect(SwipeAction.fromJson('superLike'), SwipeAction.superLike);
      expect(SwipeAction.fromJson('unknown'), SwipeAction.pass);
    });
  });

  group('SwipeRequestDto', () {
    test('toJson and validate cover happy and error paths', () {
      const valid = SwipeRequestDto(
        targetUserId: 'target-1',
        action: SwipeAction.superLike,
        superLikeMessage: 'Hello there',
      );

      expect(valid.validate(), isNull);
      expect(valid.toJson(), {
        'target_user_id': 'target-1',
        'action': 'superLike',
        'super_like_message': 'Hello there',
      });

      const invalid = SwipeRequestDto(
        targetUserId: '',
        action: SwipeAction.pass,
      );
      expect(invalid.validate(), isNotNull);
    });
  });

  group('SwipeResponseDto and Match DTOs', () {
    test('fromJson parses nested match and toJson preserves fields', () {
      final dto = SwipeResponseDto.fromJson({
        'success': true,
        'is_match': true,
        'match': {
          'id': 'm1',
          'user_id': 'u1',
          'matched_user_id': 'u2',
          'conversation_id': 'c1',
          'is_super_like': true,
          'super_like_message': 'Nice profile',
          'created_at': '2026-02-21T09:00:00.000Z',
          'updated_at': '2026-02-21T09:05:00.000Z',
          'matched_user': {'id': 'u2', 'display_name': 'Pat'},
        },
        'remaining_swipes': 7,
        'remaining_super_likes': 1,
        'message': 'Matched!',
      });

      expect(dto.success, isTrue);
      expect(dto.isMatch, isTrue);
      expect(dto.match, isNotNull);
      expect(dto.match!.serverId, 'm1');
      expect(dto.match!.matchedUser?.displayName, 'Pat');
      expect(dto.remainingSwipes, 7);

      final json = dto.toJson();
      expect(json['success'], isTrue);
      expect(json['is_match'], isTrue);
      expect((json['match'] as Map<String, dynamic>)['id'], 'm1');
    });

    test('fromJson defaults to safe values when fields are absent', () {
      final dto = SwipeResponseDto.fromJson(const {});
      expect(dto.success, isFalse);
      expect(dto.isMatch, isNull);
      expect(dto.match, isNull);
    });

    test('MatchesResponseDto handles empty and populated lists', () {
      final empty = MatchesResponseDto.fromJson(const {});
      expect(empty.matches, isEmpty);

      final populated = MatchesResponseDto.fromJson({
        'matches': [
          {'id': 'm2', 'user_id': 'u1', 'matched_user_id': 'u3'},
        ],
        'total_count': 1,
        'new_match_count': 1,
        'has_more': true,
        'next_cursor': '2026-03-08T01:00:00.000Z',
      });

      expect(populated.matches, hasLength(1));
      expect(populated.matches.first.id, 'm2');
      expect(populated.totalCount, 1);
      expect(populated.newMatchCount, 1);
      expect(populated.hasMore, isTrue);
      expect(populated.nextCursor, '2026-03-08T01:00:00.000Z');
      expect(populated.toJson()['matches'], isA<List<dynamic>>());
      expect(populated.toJson()['has_more'], isTrue);
      expect(populated.toJson()['next_cursor'], '2026-03-08T01:00:00.000Z');
    });
  });
}
