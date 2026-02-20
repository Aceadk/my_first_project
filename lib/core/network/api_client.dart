import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crushhour/core/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_version.dart';
import 'certificate_pinning.dart';
import 'dto/base_dto.dart';

/// HTTP methods supported by the API client.
enum HttpMethod { get, post, put, patch, delete }

/// API client with versioning, retry logic, and error handling.
///
/// Features:
/// - API version negotiation
/// - Automatic retry with exponential backoff
/// - Request/response interceptors
/// - Offline detection
/// - Comprehensive error handling
/// - Certificate pinning for MITM protection
class ApiClient {
  ApiClient({
    ApiConfig? config,
    this.authTokenProvider,
    this.tokenRefreshProvider,
    this.onAuthError,
    this.onVersionMismatch,
    this.enableCertificatePinning = true,
    http.Client? httpClient,
  }) : config = config ?? ApiConfig.production {
    // Initialize HTTP client with or without certificate pinning
    if (httpClient != null) {
      _httpClient = httpClient;
    } else {
      _httpClient = enableCertificatePinning
          ? CertificatePinning.createPinnedClient(
              connectionTimeout: this.config.timeout,
            )
          : http.Client();
    }
  }

  final ApiConfig config;

  /// Callback to get the current auth token.
  final Future<String?> Function()? authTokenProvider;

  /// Callback to refresh the auth token when a 401 is received.
  /// Returns the new token, or null if refresh failed.
  final Future<String?> Function()? tokenRefreshProvider;

  /// Callback when auth error occurs (401 after refresh attempt fails).
  final void Function()? onAuthError;

  /// Callback when API version mismatch is detected.
  final void Function(VersionNegotiationResult)? onVersionMismatch;

  /// Whether to enable certificate pinning (enabled by default in release mode).
  final bool enableCertificatePinning;

  late final http.Client _httpClient;
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];

  String? _cachedAppVersion;
  String? _cachedPlatform;

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERCEPTORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add a request interceptor.
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Add a response interceptor.
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Remove a request interceptor.
  void removeRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.remove(interceptor);
  }

  /// Remove a response interceptor.
  void removeResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.remove(interceptor);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Make a GET request.
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParams: queryParams,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// Make a POST request.
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    BaseDto? dto,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: dto?.toJson() ?? body,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// Make a PUT request.
  Future<ApiResult<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    BaseDto? dto,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: dto?.toJson() ?? body,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// Make a PATCH request.
  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    BaseDto? dto,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      method: HttpMethod.patch,
      endpoint: endpoint,
      body: dto?.toJson() ?? body,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  /// Make a DELETE request.
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      method: HttpMethod.delete,
      endpoint: endpoint,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTIPART FILE UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload a file using multipart form data.
  ///
  /// Returns the parsed response or throws on failure.
  /// The [file] should be a File object from dart:io.
  /// The [fieldName] is the form field name (defaults to 'file').
  /// Additional [fields] can be included in the multipart request.
  Future<ApiResult<T>> uploadFile<T>({
    required String endpoint,
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
    void Function(int sent, int total)? onProgress,
  }) async {
    final requestId = _generateRequestId();

    try {
      final uri = Uri.parse(config.getUrl(endpoint));
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _buildHeaders(requiresAuth, requestId);
      // Remove Content-Type as it will be set automatically for multipart
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add file
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: mimeType != null ? _parseMediaType(mimeType) : null,
      );
      request.files.add(multipartFile);

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send request with progress tracking
      final streamedResponse = await _sendWithProgress(
        request,
        file.lengthSync(),
        onProgress,
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );

      return _handleResponse<T>(apiResponse, parser);
    } on SocketException {
      return ApiResult.failure(ApiError.network('No internet connection'));
    } on TimeoutException {
      return ApiResult.failure(ApiError.timeout('Upload timed out'));
    } catch (e, stackTrace) {
      AppLogger.error('ApiClient: Upload failed - $e\n$stackTrace');
      return ApiResult.failure(ApiError.unknown(e.toString()));
    }
  }

  /// Upload multiple files using multipart form data.
  Future<ApiResult<T>> uploadFiles<T>({
    required String endpoint,
    required List<File> files,
    String fieldName = 'files',
    Map<String, String>? fields,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
    void Function(int sent, int total)? onProgress,
  }) async {
    final requestId = _generateRequestId();

    try {
      final uri = Uri.parse(config.getUrl(endpoint));
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _buildHeaders(requiresAuth, requestId);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add files
      int totalSize = 0;
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        final mimeType = _getMimeType(fileName);

        final multipartFile = await http.MultipartFile.fromPath(
          '$fieldName[$i]',
          file.path,
          contentType: mimeType != null ? _parseMediaType(mimeType) : null,
        );
        request.files.add(multipartFile);
        totalSize += file.lengthSync();
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send request
      final streamedResponse = await _sendWithProgress(
        request,
        totalSize,
        onProgress,
      );

      final response = await http.Response.fromStream(streamedResponse);

      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );

      return _handleResponse<T>(apiResponse, parser);
    } on SocketException {
      return ApiResult.failure(ApiError.network('No internet connection'));
    } on TimeoutException {
      return ApiResult.failure(ApiError.timeout('Upload timed out'));
    } catch (e, stackTrace) {
      AppLogger.error('ApiClient: Multi-file upload failed - $e\n$stackTrace');
      return ApiResult.failure(ApiError.unknown(e.toString()));
    }
  }

  Future<http.StreamedResponse> _sendWithProgress(
    http.MultipartRequest request,
    int totalSize,
    void Function(int sent, int total)? onProgress,
  ) async {
    if (onProgress == null) {
      return await _httpClient
          .send(request)
          .timeout(
            Duration(
              seconds: config.timeout.inSeconds * 3,
            ), // Longer timeout for uploads
          );
    }

    // For progress tracking, we need to intercept the stream
    final originalStream = request.finalize();
    int sent = 0;

    final progressStream = originalStream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sent += data.length;
          onProgress(sent, totalSize);
          sink.add(data);
        },
      ),
    );

    final streamedRequest = http.StreamedRequest(request.method, request.url);
    streamedRequest.headers.addAll(request.headers);
    streamedRequest.contentLength = request.contentLength;

    progressStream.listen(
      streamedRequest.sink.add,
      onDone: streamedRequest.sink.close,
      onError: streamedRequest.sink.addError,
    );

    return await _httpClient
        .send(streamedRequest)
        .timeout(Duration(seconds: config.timeout.inSeconds * 3));
  }

  String? _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return null;
    }
  }

  http.MediaType? _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return http.MediaType(parts[0], parts[1]);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE REQUEST LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<ApiResult<T>> _request<T>({
    required HttpMethod method,
    required String endpoint,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    final requestId = _generateRequestId();
    int attempt = 0;
    bool hasAttemptedTokenRefresh = false;

    while (attempt <= config.retryCount) {
      try {
        // Build request
        var request = ApiRequest(
          method: method,
          url: config.getUrl(endpoint),
          queryParams: queryParams,
          body: body,
          headers: await _buildHeaders(requiresAuth, requestId),
        );

        // Apply request interceptors
        for (final interceptor in _requestInterceptors) {
          request = await interceptor.onRequest(request);
        }

        // Make HTTP request
        final response = await _executeRequest(request);

        // Apply response interceptors
        var apiResponse = ApiResponse(
          statusCode: response.statusCode,
          headers: response.headers,
          body: response.body,
        );

        for (final interceptor in _responseInterceptors) {
          apiResponse = await interceptor.onResponse(apiResponse);
        }

        // On 401, attempt token refresh before calling onAuthError
        if (apiResponse.statusCode == 401 &&
            requiresAuth &&
            tokenRefreshProvider != null &&
            !hasAttemptedTokenRefresh) {
          hasAttemptedTokenRefresh = true;
          try {
            final newToken = await tokenRefreshProvider!();
            if (newToken != null) {
              // Retry the request with the refreshed token
              continue;
            }
          } catch (e) {
            AppLogger.error('ApiClient: Token refresh failed - $e');
          }
          // Refresh failed or returned null — fall through to normal 401 handling
        }

        // Handle response
        return _handleResponse<T>(apiResponse, parser);
      } on SocketException {
        // Network error - retry if allowed
        if (attempt < config.retryCount) {
          attempt++;
          await _delay(attempt);
          continue;
        }
        return ApiResult.failure(ApiError.network('No internet connection'));
      } on TimeoutException {
        // Timeout - retry if allowed
        if (attempt < config.retryCount) {
          attempt++;
          await _delay(attempt);
          continue;
        }
        return ApiResult.failure(ApiError.timeout('Request timed out'));
      } catch (e, stackTrace) {
        AppLogger.error('ApiClient: Request failed - $e\n$stackTrace');
        return ApiResult.failure(ApiError.unknown(e.toString()));
      }
    }

    return ApiResult.failure(ApiError.unknown('Max retries exceeded'));
  }

  Future<http.Response> _executeRequest(ApiRequest request) async {
    final uri = Uri.parse(
      request.url,
    ).replace(queryParameters: request.queryParams);

    final httpRequest = http.Request(request.method.name.toUpperCase(), uri);
    httpRequest.headers.addAll(request.headers);

    if (request.body != null) {
      httpRequest.body = jsonEncode(request.body);
    }

    final streamedResponse = await _httpClient
        .send(httpRequest)
        .timeout(config.timeout);
    return http.Response.fromStream(streamedResponse);
  }

  Future<Map<String, String>> _buildHeaders(
    bool requiresAuth,
    String requestId,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...ApiHeaders.getDefaultHeaders(
        appVersion: _cachedAppVersion ?? '1.0.0',
        platform: _cachedPlatform ?? (Platform.isIOS ? 'ios' : 'android'),
        requestId: requestId,
      ),
    };

    if (requiresAuth && authTokenProvider != null) {
      final token = await authTokenProvider!();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  ApiResult<T> _handleResponse<T>(
    ApiResponse response,
    T Function(dynamic)? parser,
  ) {
    // Check for version mismatch
    _checkVersionHeaders(response.headers);

    // Handle status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      try {
        if (response.body.isEmpty) {
          return ApiResult.success(null as T);
        }

        final json = jsonDecode(response.body);

        if (parser != null) {
          return ApiResult.success(parser(json));
        }

        return ApiResult.success(json as T);
      } catch (e) {
        return ApiResult.failure(
          ApiError.parse('Failed to parse response: $e'),
        );
      }
    }

    // Handle errors
    return _handleErrorResponse(response);
  }

  ApiResult<T> _handleErrorResponse<T>(ApiResponse response) {
    String? message;
    String? errorCode;

    try {
      final json = jsonDecode(response.body);
      message = json['error'] as String? ?? json['message'] as String?;
      errorCode = json['error_code'] as String?;
    } catch (e) {
      AppLogger.error('ApiClient: Error parsing error response body: $e');
      message = response.body;
    }

    switch (response.statusCode) {
      case 400:
        return ApiResult.failure(
          ApiError.badRequest(message ?? 'Bad request', errorCode),
        );
      case 401:
        onAuthError?.call();
        return ApiResult.failure(
          ApiError.unauthorized(message ?? 'Unauthorized', errorCode),
        );
      case 403:
        return ApiResult.failure(
          ApiError.forbidden(message ?? 'Forbidden', errorCode),
        );
      case 404:
        return ApiResult.failure(
          ApiError.notFound(message ?? 'Not found', errorCode),
        );
      case 409:
        return ApiResult.failure(
          ApiError.conflict(message ?? 'Conflict', errorCode),
        );
      case 422:
        return ApiResult.failure(
          ApiError.validation(message ?? 'Validation failed', errorCode),
        );
      case 429:
        return ApiResult.failure(
          ApiError.rateLimited(message ?? 'Too many requests', errorCode),
        );
      case >= 500:
        return ApiResult.failure(
          ApiError.server(message ?? 'Server error', errorCode),
        );
      default:
        return ApiResult.failure(ApiError.unknown(message ?? 'Unknown error'));
    }
  }

  void _checkVersionHeaders(Map<String, String> headers) {
    final serverMinVersion = headers[ApiHeaders.serverMinVersion.toLowerCase()];
    final serverMaxVersion = headers[ApiHeaders.serverMaxVersion.toLowerCase()];
    final deprecationWarning =
        headers[ApiHeaders.deprecationWarning.toLowerCase()];

    if (deprecationWarning != null) {
      AppLogger.debug('API Deprecation Warning: $deprecationWarning');
    }

    if (serverMinVersion != null && serverMaxVersion != null) {
      final result = VersionNegotiationResult.negotiate(
        clientVersion: ApiVersion.current,
        serverMinVersion: ApiVersion.parse(serverMinVersion),
        serverMaxVersion: ApiVersion.parse(serverMaxVersion),
      );

      if (!result.isCompatible || result.upgradeRequired) {
        onVersionMismatch?.call(result);
      }
    }
  }

  Future<void> _delay(int attempt) {
    final delay = config.retryDelay * (1 << (attempt - 1));
    return Future.delayed(delay);
  }

  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Set cached app info (call during initialization).
  void setAppInfo({required String appVersion, required String platform}) {
    _cachedAppVersion = appVersion;
    _cachedPlatform = platform;
  }

  /// Dispose the client.
  void dispose() {
    _httpClient.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// API RESULT
// ═══════════════════════════════════════════════════════════════════════════

/// Result of an API call.
class ApiResult<T> {
  const ApiResult._({this.data, this.error, required this.isSuccess});

  final T? data;
  final ApiError? error;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  factory ApiResult.success(T data) {
    return ApiResult._(data: data, isSuccess: true);
  }

  factory ApiResult.failure(ApiError error) {
    return ApiResult._(error: error, isSuccess: false);
  }

  /// Map success value.
  ApiResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      return ApiResult.success(mapper(data as T));
    }
    return ApiResult.failure(error!);
  }

  /// Get data or throw error.
  T getOrThrow() {
    if (isSuccess) return data as T;
    throw error!;
  }

  /// Get data or default value.
  T getOrElse(T defaultValue) {
    if (isSuccess && data != null) return data as T;
    return defaultValue;
  }

  /// Execute callback on success.
  ApiResult<T> onSuccess(void Function(T) callback) {
    if (isSuccess && data != null) callback(data as T);
    return this;
  }

  /// Execute callback on failure.
  ApiResult<T> onFailure(void Function(ApiError) callback) {
    if (isFailure && error != null) callback(error!);
    return this;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// API ERROR
// ═══════════════════════════════════════════════════════════════════════════

/// API error types.
enum ApiErrorType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  parse,
  unknown,
}

/// API error with type and message.
class ApiError implements Exception {
  const ApiError({required this.type, required this.message, this.code});

  final ApiErrorType type;
  final String message;
  final String? code;

  factory ApiError.network(String message) =>
      ApiError(type: ApiErrorType.network, message: message);

  factory ApiError.timeout(String message) =>
      ApiError(type: ApiErrorType.timeout, message: message);

  factory ApiError.badRequest(String message, [String? code]) =>
      ApiError(type: ApiErrorType.badRequest, message: message, code: code);

  factory ApiError.unauthorized(String message, [String? code]) =>
      ApiError(type: ApiErrorType.unauthorized, message: message, code: code);

  factory ApiError.forbidden(String message, [String? code]) =>
      ApiError(type: ApiErrorType.forbidden, message: message, code: code);

  factory ApiError.notFound(String message, [String? code]) =>
      ApiError(type: ApiErrorType.notFound, message: message, code: code);

  factory ApiError.conflict(String message, [String? code]) =>
      ApiError(type: ApiErrorType.conflict, message: message, code: code);

  factory ApiError.validation(String message, [String? code]) =>
      ApiError(type: ApiErrorType.validation, message: message, code: code);

  factory ApiError.rateLimited(String message, [String? code]) =>
      ApiError(type: ApiErrorType.rateLimited, message: message, code: code);

  factory ApiError.server(String message, [String? code]) =>
      ApiError(type: ApiErrorType.server, message: message, code: code);

  factory ApiError.parse(String message) =>
      ApiError(type: ApiErrorType.parse, message: message);

  factory ApiError.unknown(String message) =>
      ApiError(type: ApiErrorType.unknown, message: message);

  bool get isNetworkError => type == ApiErrorType.network;
  bool get isAuthError => type == ApiErrorType.unauthorized;
  bool get isServerError => type == ApiErrorType.server;
  bool get isRetryable =>
      type == ApiErrorType.network ||
      type == ApiErrorType.timeout ||
      type == ApiErrorType.server;

  @override
  String toString() =>
      'ApiError($type): $message${code != null ? ' [$code]' : ''}';
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERCEPTORS
// ═══════════════════════════════════════════════════════════════════════════

/// Request data container.
class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.url,
    required this.headers,
    this.queryParams,
    this.body,
  });

  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String>? queryParams;
  final Map<String, dynamic>? body;

  ApiRequest copyWith({
    HttpMethod? method,
    String? url,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) {
    return ApiRequest(
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
    );
  }
}

/// Response data container.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;

  ApiResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    String? body,
  }) {
    return ApiResponse(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      body: body ?? this.body,
    );
  }
}

/// Request interceptor interface.
abstract class RequestInterceptor {
  Future<ApiRequest> onRequest(ApiRequest request);
}

/// Response interceptor interface.
abstract class ResponseInterceptor {
  Future<ApiResponse> onResponse(ApiResponse response);
}

/// Logging interceptor for debugging.
class LoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  @override
  Future<ApiRequest> onRequest(ApiRequest request) async {
    if (kDebugMode) {
      AppLogger.debug('→ ${request.method.name.toUpperCase()} ${request.url}');
      if (request.body != null) {
        AppLogger.debug('  Body: ${jsonEncode(request.body)}');
      }
    }
    return request;
  }

  @override
  Future<ApiResponse> onResponse(ApiResponse response) async {
    if (kDebugMode) {
      AppLogger.debug('← ${response.statusCode}');
      if (response.body.isNotEmpty && response.body.length < 1000) {
        AppLogger.debug('  Body: ${response.body}');
      }
    }
    return response;
  }
}
