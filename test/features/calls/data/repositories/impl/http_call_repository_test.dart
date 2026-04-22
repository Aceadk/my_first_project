import 'dart:convert';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/features/calls/data/repositories/impl/http_call_repository.dart';
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

  group('HttpCallRepository', () {
    test('startCall and endCall use the supported REST endpoints', () async {
      final seenRequests = <Map<String, dynamic>>[];
      final mockClient = MockClient((request) async {
        seenRequests.add(<String, dynamic>{
          'method': request.method,
          'path': request.url.path,
          'body': request.body.isEmpty
              ? const <String, dynamic>{}
              : jsonDecode(request.body) as Map<String, dynamic>,
        });

        switch (request.url.path) {
          case '/v1/calls/start':
            return http.Response(
              jsonEncode(<String, dynamic>{
                'call_id': 'call-123',
                'local_uid': 0,
              }),
              200,
            );
          case '/v1/calls/end':
            return http.Response(
              jsonEncode(<String, dynamic>{'success': true}),
              200,
            );
          default:
            return http.Response('not found', 404);
        }
      });

      final repository = HttpCallRepository(
        apiClient: ApiClient(config: apiConfig, httpClient: mockClient),
      );

      final session = await repository.startCall(
        matchId: 'match-1',
        isVideoCall: true,
      );
      await repository.endCall();

      expect(session.channelName, 'call-123');
      expect(session.localUid, 0);
      expect(
        seenRequests,
        equals(<Map<String, dynamic>>[
          <String, dynamic>{
            'method': 'POST',
            'path': '/v1/calls/start',
            'body': <String, dynamic>{'match_id': 'match-1', 'is_video': true},
          },
          <String, dynamic>{
            'method': 'POST',
            'path': '/v1/calls/end',
            'body': <String, dynamic>{'call_id': 'call-123'},
          },
        ]),
      );

      repository.dispose();
    });
  });
}
