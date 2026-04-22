import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/base_dto.dart';
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

    test('get retries on timeout', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (calls == 1) {
          throw TimeoutException('slow');
        }
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>('/timeout-read');

      expect(result.isSuccess, isTrue);
      expect(result.data?['ok'], isTrue);
      expect(calls, 2);
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

    test('post does not retry on network error', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        throw const SocketException('fail');
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.post<Map<String, dynamic>>(
        '/unsafe-write',
        body: <String, dynamic>{'key': 'value'},
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.isNetworkError, isTrue);
      expect(calls, 1);
    });

    test('post does not retry on timeout', () async {
      var calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        throw TimeoutException('slow');
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.post<Map<String, dynamic>>(
        '/unsafe-timeout',
        body: <String, dynamic>{'key': 'value'},
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.type, ApiErrorType.timeout);
      expect(calls, 1);
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

    test('patch sends body and returns success', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(jsonDecode(request.body), <String, dynamic>{'enabled': true});
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.patch<Map<String, dynamic>>(
        '/settings',
        body: <String, dynamic>{'enabled': true},
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?['ok'], isTrue);
    });

    test('query parameters are appended to request URI', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters, <String, String>{
          'q': 'flowers',
          'limit': '20',
        });
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>(
        '/search',
        queryParams: const <String, String>{'q': 'flowers', 'limit': '20'},
      );

      expect(result.isSuccess, isTrue);
    });

    test('post prefers dto serialization when dto is supplied', () async {
      final mockClient = MockClient((request) async {
        expect(jsonDecode(request.body), <String, dynamic>{'source': 'dto'});
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      await client.post<Map<String, dynamic>>(
        '/dto',
        body: <String, dynamic>{'source': 'body'},
        dto: const _DummyDto(<String, dynamic>{'source': 'dto'}),
      );
    });

    test('parser callback is applied to successful responses', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(<String, dynamic>{'count': 2}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<int>(
        '/count',
        parser: (json) => (json as Map<String, dynamic>)['count'] as int,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 2);
    });

    test('returns parse error when success response is invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not-json', 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get<Map<String, dynamic>>('/invalid-json');

      expect(result.isFailure, isTrue);
      expect(result.error?.type, ApiErrorType.parse);
    });

    test('maps error status codes and error codes correctly', () async {
      Future<ApiResult<dynamic>> run(int statusCode) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'error': 'status-$statusCode',
              'error_code': 'E$statusCode',
            }),
            statusCode,
          );
        });
        final client = ApiClient(config: config, httpClient: mockClient);
        return client.get('/status-$statusCode');
      }

      expect((await run(400)).error?.type, ApiErrorType.badRequest);
      expect((await run(403)).error?.type, ApiErrorType.forbidden);
      expect((await run(404)).error?.type, ApiErrorType.notFound);
      expect((await run(409)).error?.type, ApiErrorType.conflict);
      expect((await run(422)).error?.type, ApiErrorType.validation);
      expect((await run(429)).error?.type, ApiErrorType.rateLimited);
      expect((await run(500)).error?.type, ApiErrorType.server);
      expect((await run(418)).error?.type, ApiErrorType.unknown);
    });

    test('falls back to raw body message for malformed error JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('plain text error', 500);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      final result = await client.get('/malformed-error');

      expect(result.isFailure, isTrue);
      expect(result.error?.message, 'plain text error');
    });

    test('refreshes auth token on 401 and retries request', () async {
      var token = 'old-token';
      int calls = 0;
      final seenAuthHeaders = <String?>[];

      final mockClient = MockClient((request) async {
        calls++;
        seenAuthHeaders.add(request.headers['Authorization']);
        if (calls == 1) {
          return http.Response('{"error":"Unauthorized"}', 401);
        }
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(
        config: config,
        httpClient: mockClient,
        authTokenProvider: () async => token,
        tokenRefreshProvider: () async {
          token = 'new-token';
          return token;
        },
      );

      final result = await client.get<Map<String, dynamic>>('/refresh');

      expect(result.isSuccess, isTrue);
      expect(calls, 2);
      expect(seenAuthHeaders, <String?>[
        'Bearer old-token',
        'Bearer new-token',
      ]);
    });

    test('calls onAuthError when token refresh returns null', () async {
      var authErrorCalled = false;
      var refreshCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response('{"error":"Unauthorized"}', 401);
      });

      final client = ApiClient(
        config: config,
        httpClient: mockClient,
        authTokenProvider: () async => 'token',
        tokenRefreshProvider: () async {
          refreshCalled = true;
          return null;
        },
        onAuthError: () => authErrorCalled = true,
      );

      final result = await client.get('/auth-failure');

      expect(refreshCalled, isTrue);
      expect(result.isFailure, isTrue);
      expect(result.error?.type, ApiErrorType.unauthorized);
      expect(authErrorCalled, isTrue);
    });

    test(
      'version mismatch callback fires for incompatible server versions',
      () async {
        VersionNegotiationResult? mismatch;
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{'ok': true}),
            200,
            headers: <String, String>{
              ApiHeaders.serverMinVersion.toLowerCase(): '2.0',
              ApiHeaders.serverMaxVersion.toLowerCase(): '2.5',
              ApiHeaders.deprecationWarning.toLowerCase(): 'deprecated',
            },
          );
        });

        final client = ApiClient(
          config: config,
          httpClient: mockClient,
          onVersionMismatch: (result) => mismatch = result,
        );

        await client.get<Map<String, dynamic>>('/version');

        expect(mismatch, isNotNull);
        expect(mismatch?.isCompatible, isFalse);
      },
    );

    test('setAppInfo updates version/platform headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers[ApiHeaders.appVersion], '9.9.9');
        expect(request.headers[ApiHeaders.platform], 'web');
        return http.Response('{}', 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      client.setAppInfo(appVersion: '9.9.9', platform: 'web');
      await client.get('/headers');
    });

    test('response interceptors can transform response payload', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(<String, dynamic>{'value': 1}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      client.addResponseInterceptor(_TestResponseInterceptor());

      final result = await client.get<int>(
        '/response-interceptor',
        parser: (json) => (json as Map<String, dynamic>)['value'] as int,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 42);
    });

    test('remove request/response interceptors detaches them', () async {
      final requestInterceptor = TestInterceptor();
      final responseInterceptor = _PassThroughResponseInterceptor();

      final mockClient = MockClient((request) async {
        expect(request.headers.containsKey('X-Test'), isFalse);
        return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
      });

      final client = ApiClient(config: config, httpClient: mockClient);
      client.addRequestInterceptor(requestInterceptor);
      client.removeRequestInterceptor(requestInterceptor);
      client.addResponseInterceptor(responseInterceptor);
      client.removeResponseInterceptor(responseInterceptor);

      final result = await client.get<Map<String, dynamic>>(
        '/remove-interceptors',
      );
      expect(result.isSuccess, isTrue);
    });

    test('dispose closes underlying http client', () async {
      final mockClient = MockClient(
        (request) async => http.Response('{}', 200),
      );
      final client = ApiClient(config: config, httpClient: mockClient);
      expect(() => client.dispose(), returnsNormally);
    });
  });

  group('ApiResult', () {
    test('map transforms success and preserves failure', () {
      final success = ApiResult.success(2).map((v) => v * 3);
      expect(success.isSuccess, isTrue);
      expect(success.data, 6);

      final failure = ApiResult<int>.failure(
        ApiError.unknown('boom'),
      ).map((v) => v * 3);
      expect(failure.isFailure, isTrue);
      expect(failure.error?.message, 'boom');
    });

    test('getOrThrow and getOrElse cover success and failure paths', () {
      final success = ApiResult.success('ok');
      expect(success.getOrThrow(), 'ok');
      expect(success.getOrElse('fallback'), 'ok');

      final failure = ApiResult<String>.failure(ApiError.unknown('boom'));
      expect(failure.getOrElse('fallback'), 'fallback');
      expect(() => failure.getOrThrow(), throwsA(isA<ApiError>()));
    });

    test('onSuccess and onFailure callbacks run on matching state only', () {
      var successValue = '';
      var failureMessage = '';

      ApiResult.success('done')
          .onSuccess((value) => successValue = value)
          .onFailure((error) => failureMessage = error.message);
      expect(successValue, 'done');
      expect(failureMessage, isEmpty);

      ApiResult<String>.failure(ApiError.unknown('failed'))
          .onSuccess((value) => successValue = value)
          .onFailure((error) => failureMessage = error.message);
      expect(failureMessage, 'failed');
    });
  });

  group('ApiError', () {
    test('factory constructors set type, message and retryability', () {
      final network = ApiError.network('offline');
      final timeout = ApiError.timeout('slow');
      final unauthorized = ApiError.unauthorized('auth', '401');
      final server = ApiError.server('broken', '500');

      expect(network.isNetworkError, isTrue);
      expect(network.isRetryable, isTrue);
      expect(timeout.isRetryable, isTrue);
      expect(unauthorized.isAuthError, isTrue);
      expect(server.isServerError, isTrue);
      expect(server.isRetryable, isTrue);
      expect(unauthorized.toString(), contains('[401]'));
    });
  });

  group('ApiRequest/ApiResponse copyWith', () {
    test('copyWith updates provided fields and keeps others', () {
      const request = ApiRequest(
        method: HttpMethod.get,
        url: 'https://api.example.com/a',
        headers: <String, String>{'A': '1'},
      );
      final requestCopy = request.copyWith(
        method: HttpMethod.post,
        headers: <String, String>{'B': '2'},
        body: <String, dynamic>{'x': 1},
      );
      expect(requestCopy.method, HttpMethod.post);
      expect(requestCopy.url, request.url);
      expect(requestCopy.headers, <String, String>{'B': '2'});
      expect(requestCopy.body, <String, dynamic>{'x': 1});

      const response = ApiResponse(
        statusCode: 200,
        headers: <String, String>{'A': '1'},
        body: '{"ok":true}',
      );
      final responseCopy = response.copyWith(statusCode: 201, body: '{}');
      expect(responseCopy.statusCode, 201);
      expect(responseCopy.headers, response.headers);
      expect(responseCopy.body, '{}');
    });
  });

  group('LoggingInterceptor', () {
    test('onRequest and onResponse return original values', () async {
      final interceptor = LoggingInterceptor();
      const request = ApiRequest(
        method: HttpMethod.post,
        url: 'https://api.example.com/log',
        headers: <String, String>{'A': '1'},
        body: <String, dynamic>{'x': 1},
      );
      const response = ApiResponse(
        statusCode: 200,
        headers: <String, String>{},
        body: '{"ok":true}',
      );

      final processedRequest = await interceptor.onRequest(request);
      final processedResponse = await interceptor.onResponse(response);

      expect(processedRequest, same(request));
      expect(processedResponse, same(response));
    });
  });
}

class TestInterceptor extends RequestInterceptor {
  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    return request.copyWith(headers: {...request.headers, 'X-Test': 'true'});
  }
}

class _TestResponseInterceptor extends ResponseInterceptor {
  @override
  Future<ApiResponse> onResponse(ApiResponse response) async {
    return response.copyWith(body: jsonEncode(<String, dynamic>{'value': 42}));
  }
}

class _PassThroughResponseInterceptor extends ResponseInterceptor {
  @override
  Future<ApiResponse> onResponse(ApiResponse response) async => response;
}

class _DummyDto extends BaseDto {
  const _DummyDto(this.payload);

  final Map<String, dynamic> payload;

  @override
  Map<String, dynamic> toJson() => payload;
}
