import 'dart:convert';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/http_discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const apiConfig = ApiConfig(
    baseUrl: 'https://api.example.com',
    timeout: Duration(seconds: 1),
    retryCount: 0,
    retryDelay: Duration(milliseconds: 1),
  );

  group('HttpDiscoveryRepository', () {
    test(
      'fetchTopPicks reuses the live discovery deck route with verified filter',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/discovery/deck');
          expect(
            request.url.queryParameters,
            containsPair('requireVerified', 'true'),
          );
          expect(request.url.queryParameters, containsPair('limit', '10'));
          return http.Response(
            jsonEncode(<String, dynamic>{
              'candidates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'top-pick-1',
                  'display_name': 'Taylor',
                  'age': 29,
                  'bio': 'Runner and coffee snob',
                  'photos': const <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'photo_0',
                      'url': 'https://example.com/taylor.jpg',
                      'is_primary': true,
                    },
                  ],
                  'interests': const <String>['running'],
                  'is_verified': true,
                },
              ],
            }),
            200,
          );
        });

        final repository = HttpDiscoveryRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final profiles = await repository.fetchTopPicks('user-1');

        expect(profiles, hasLength(1));
        expect(profiles.first.id, 'top-pick-1');
        expect(profiles.first.isVerified, isTrue);
      },
    );

    test('fetchProfileById maps the real /profile/:id payload shape', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/profile/user%201');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'id': 'user 1',
            'display_name': 'Morgan',
            'age': 31,
            'bio': 'Designer',
            'city': 'Kathmandu',
            'photos': const <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'photo_0',
                'url': 'https://example.com/morgan.jpg',
                'is_primary': true,
              },
            ],
            'interests': const <String>['art'],
            'is_verified': true,
          }),
          200,
        );
      });

      final repository = HttpDiscoveryRepository(
        apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
      );

      final profile = await repository.fetchProfileById('user 1');

      expect(profile, isNotNull);
      expect(profile!.id, 'user 1');
      expect(profile.name, 'Morgan');
      expect(profile.photoUrls, ['https://example.com/morgan.jpg']);
      expect(profile.isVerified, isTrue);
    });

    test(
      'superLike uses discovery swipe and maps flat match payloads',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/discovery/swipe');
          expect(jsonDecode(request.body), <String, dynamic>{
            'target_user_id': 'target-7',
            'action': 'superLike',
          });
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'is_match': true,
              'match_id': 'match-77',
            }),
            200,
          );
        });

        final repository = HttpDiscoveryRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final match = await repository.superLike(
          userId: 'user-1',
          targetUserId: 'target-7',
        );

        expect(match, isNotNull);
        expect(match!.id, 'match-77');
        expect(match.otherUserId, 'target-7');
      },
    );

    test('fetchLikesYou uses the dedicated likes-you REST route', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/discovery/likes-you');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'profiles': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'liker-1',
                'display_name': 'Chris',
                'age': 27,
                'photos': const <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'photo_0',
                    'url': 'https://example.com/chris.jpg',
                    'is_primary': true,
                  },
                ],
              },
            ],
          }),
          200,
        );
      });

      final repository = HttpDiscoveryRepository(
        apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
      );

      final profiles = await repository.fetchLikesYou('user-1');

      expect(profiles, hasLength(1));
      expect(profiles.first.id, 'liker-1');
    });
  });
}
