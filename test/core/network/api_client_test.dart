import 'dart:convert';
import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    const baseUrl = 'https://api.example.com';
    const config = ApiConfig(
      baseUrl: baseUrl,
      timeout: Duration(seconds: 1),
      retryCount: 1, // 1 retry allowed
      retryDelay: Duration(milliseconds: 1),
    );

    test('get returns success on 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': 'success'}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>('/test');

      expect(result.isSuccess, true);
      expect(result.data?['data'], 'success');
    });

    test('get retries on network error', () async {
      int calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (calls == 1) throw const SocketException('fail');
        return http.Response(jsonEncode({'data': 'success'}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>('/test');

      expect(result.isSuccess, true);
      expect(calls, 2);
    });

    test('get fails after max retries', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('fail');
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>('/test');

      expect(result.isFailure, true);
      expect(result.error?.isNetworkError, true);
    });

    test('post sends body correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body)['key'], 'value');
        return http.Response('{}', 201);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      await client.post('/test', body: {'key': 'value'});
    });

    test('handles 401 unauthorized', () async {
      bool authErrorCalled = false;
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final client = ApiClient(
        config: config,
        httpClient: mockClient,
        onAuthError: () => authErrorCalled = true,
      );

      final result = await client.get('/test');

      expect(result.isFailure, true);
      expect(result.error?.isAuthError, true);
      expect(authErrorCalled, true);
    });

    test('attaches auth token when provided', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token123');
        return http.Response('{}', 200);
      });

      final client = ApiClient(
        config: config,
        httpClient: mockClient,
        authTokenProvider: () async => 'token123',
      );

      await client.get('/test');
    });

    test('interceptors validation', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Test'], 'true');
        return http.Response('{}', 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);

      client.addRequestInterceptor(TestInterceptor());

      await client.get('/test');
    });

    test('put returns success on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        return http.Response(jsonEncode({'data': 'updated'}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.put<Map<String, dynamic>>(
        '/test',
        body: {'key': 'val'},
      );

      expect(result.isSuccess, true);
    });

    test('delete returns success on 204', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.delete<void>('/test');

      expect(result.isSuccess, true);
    });

    test('uploadFile sends multipart request', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        // Check if it's multipart
        expect(
          request.headers['content-type']?.contains('multipart/form-data'),
          true,
        );
        return http.Response(
          jsonEncode({'url': 'http://example.com/img.jpg'}),
          200,
        );
      });

      final client = ApiClient(config: config, httpClient: mockClient);

      // Create a dummy file
      final file = File('test_image.jpg');
      await file.writeAsString('dummy content');

      try {
        final result = await client.uploadFile<Map<String, dynamic>>(
          endpoint: '/upload',
          file: file,
        );
        expect(result.isSuccess, true);
      } finally {
        if (await file.exists()) {
          await file.delete();
        }
      }
    });
  });
}

class TestInterceptor extends RequestInterceptor {
  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    return request.copyWith(headers: {...request.headers, 'X-Test': 'true'});
  }
}
