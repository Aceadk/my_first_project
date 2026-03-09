import 'dart:convert';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/circuit_breaker.dart';
import 'package:crushhour/features/profile/data/repositories/impl/http_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpProfileRepository.getCurrentUser', () {
    const apiConfig = ApiConfig(
      baseUrl: 'https://api.example.com',
      timeout: Duration(seconds: 1),
      retryCount: 0,
      retryDelay: Duration(milliseconds: 1),
    );

    setUp(() {
      CircuitBreakerRegistry.instance.clear();
    });

    test(
      'maps canonical username from API response and keeps display name separate',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.path, equals('/v1/profile/me'));
          return http.Response(
            jsonEncode(<String, dynamic>{
              'id': 'user-1',
              'username': 'ace_handle',
              'phone_number': '+15555550123',
              'email': 'user@example.com',
              'email_verified': true,
              'display_name': 'Ace Display',
              'bio': 'hello',
              'gender': 'female',
              'photos': const <dynamic>[],
              'interests': const <String>['music'],
            }),
            200,
          );
        });

        final repository = HttpProfileRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.username, equals('ace_handle'));
        expect(user.profile, isNotNull);
        expect(user.profile!.name, equals('Ace Display'));
      },
    );

    test(
      'falls back to display name when username is missing in legacy payload',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'id': 'user-1',
              'phone_number': '+15555550123',
              'email': 'user@example.com',
              'email_verified': true,
              'display_name': 'Legacy Display',
              'bio': 'hello',
              'gender': 'female',
              'photos': const <dynamic>[],
              'interests': const <String>['music'],
            }),
            200,
          );
        });

        final repository = HttpProfileRepository(
          apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
        );

        final user = await repository.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.username, equals('Legacy Display'));
        expect(user.profile!.name, equals('Legacy Display'));
      },
    );
  });
}
