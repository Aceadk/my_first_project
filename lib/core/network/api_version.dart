import 'package:crushhour/core/app_logger.dart';

/// API version management for backward compatibility.
///
/// Supports:
/// - Version-specific endpoints
/// - Version negotiation
/// - Graceful deprecation handling
/// - Feature availability by version
class ApiVersion implements Comparable<ApiVersion> {
  const ApiVersion(this.major, [this.minor = 0, this.patch = 0]);

  final int major;
  final int minor;
  final int patch;

  /// Current API version supported by this client.
  static const ApiVersion current = ApiVersion(1, 0, 0);

  /// Minimum API version required by this client.
  static const ApiVersion minimum = ApiVersion(1, 0, 0);

  /// Parse version from string (e.g., "1.0.0" or "v1.0.0").
  factory ApiVersion.parse(String version) {
    final cleaned = version.replaceFirst(RegExp(r'^v'), '');
    final parts = cleaned.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    return ApiVersion(
      parts.isNotEmpty ? parts[0] : 0,
      parts.length > 1 ? parts[1] : 0,
      parts.length > 2 ? parts[2] : 0,
    );
  }

  /// Check if this version is compatible with another.
  bool isCompatibleWith(ApiVersion other) {
    // Major version must match for compatibility
    return major == other.major;
  }

  /// Check if this version meets the minimum requirement.
  bool meetsMinimum(ApiVersion minimum) {
    return compareTo(minimum) >= 0;
  }

  @override
  int compareTo(ApiVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(ApiVersion other) => compareTo(other) < 0;
  bool operator <=(ApiVersion other) => compareTo(other) <= 0;
  bool operator >(ApiVersion other) => compareTo(other) > 0;
  bool operator >=(ApiVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is ApiVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';

  /// Get URL path segment for this version.
  String get pathSegment => 'v$major';
}

// ═══════════════════════════════════════════════════════════════════════════
// API CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

/// API endpoint configuration.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.version = ApiVersion.current,
    this.timeout = const Duration(seconds: 30),
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  /// Base URL for API requests.
  final String baseUrl;

  /// API version to use.
  final ApiVersion version;

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts.
  final int retryCount;

  /// Delay between retries.
  final Duration retryDelay;

  /// Development configuration (Firebase Emulator).
  static const ApiConfig development = ApiConfig(
    baseUrl: 'http://127.0.0.1:5001/crush-265f7/us-central1/api',
    timeout: Duration(seconds: 60),
  );

  /// Staging configuration (Firebase Cloud Functions).
  static const ApiConfig staging = ApiConfig(
    baseUrl: 'https://us-central1-crush-265f7.cloudfunctions.net/api',
  );

  /// Production configuration (Firebase Cloud Functions).
  static const ApiConfig production = ApiConfig(
    baseUrl: 'https://us-central1-crush-265f7.cloudfunctions.net/api',
    retryCount: 3,
  );

  /// Get full URL for an endpoint.
  String getUrl(String endpoint) {
    final versionPath = version.pathSegment;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl/$versionPath$cleanEndpoint';
  }

  /// Create a copy with different values.
  ApiConfig copyWith({
    String? baseUrl,
    ApiVersion? version,
    Duration? timeout,
    int? retryCount,
    Duration? retryDelay,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      version: version ?? this.version,
      timeout: timeout ?? this.timeout,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// API ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════

/// Centralized API endpoint definitions.
class ApiEndpoints {
  ApiEndpoints._();

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────────────────────

  static const String authSendOtp = '/auth/otp/send';
  static const String authVerifyOtp = '/auth/otp/verify';
  static const String authRefreshToken = '/auth/token/refresh';
  static const String authLogout = '/auth/logout';
  static const String authOAuthApple = '/auth/oauth/apple';
  static const String authOAuthGoogle = '/auth/oauth/google';

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  static const String profileMe = '/profile/me';
  static const String profileUpdate = '/profile/me';
  static const String profilePhoto = '/profile/photo';
  static const String profilePhotos = '/profile/photos';
  static const String profilePreferences = '/profile/preferences';
  static String profileById(String id) => '/profile/$id';
  static String profilePhotoById(String photoId) => '/profile/photos/$photoId';

  // ─────────────────────────────────────────────────────────────────────────
  // DISCOVERY
  // ─────────────────────────────────────────────────────────────────────────

  static const String discoveryDeck = '/discovery/deck';
  static const String discoverySwipe = '/discovery/swipe';
  static const String discoverySettings = '/discovery/settings';
  static const String discoveryBoost = '/discovery/boost';
  // DISC-001: Previously hardcoded in HttpDiscoveryRepository
  static const String discoveryTopPicks = '/discovery/top-picks';
  static const String discoveryLikesYou = '/discovery/likes-you';
  static const String discoverySuperLike = '/discovery/super-like';
  static const String discoveryRewind = '/discovery/rewind';
  static String profiles(String profileId) =>
      '/profiles/${Uri.encodeComponent(profileId)}';

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT
  // ─────────────────────────────────────────────────────────────────────────

  static const String chatConversations = '/chat/conversations';
  static String chatMessages(String conversationId) =>
      '/chat/$conversationId/messages';
  static String chatSend(String conversationId) => '/chat/$conversationId/send';
  static String chatRead(String conversationId) => '/chat/$conversationId/read';

  // ─────────────────────────────────────────────────────────────────────────
  // MATCHES
  // ─────────────────────────────────────────────────────────────────────────

  static const String matches = '/matches';
  static String matchById(String id) => '/matches/$id';
  static String unmatch(String id) => '/matches/$id/unmatch';

  // ─────────────────────────────────────────────────────────────────────────
  // SUBSCRIPTION
  // ─────────────────────────────────────────────────────────────────────────

  static const String subscriptionStatus = '/subscription/status';
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptionPurchase = '/subscription/purchase';
  static const String subscriptionCancel = '/subscription/cancel';
  static const String subscriptionRestore = '/subscription/restore';

  // ─────────────────────────────────────────────────────────────────────────
  // REPORTING & SAFETY
  // ─────────────────────────────────────────────────────────────────────────

  static const String reportUser = '/safety/report';
  static const String blockUser = '/safety/block';
  static const String unblockUser = '/safety/unblock';
  static const String blockedUsers = '/safety/blocked';
}

// ═══════════════════════════════════════════════════════════════════════════
// FEATURE AVAILABILITY
// ═══════════════════════════════════════════════════════════════════════════

/// Track feature availability by API version.
class ApiFeatures {
  ApiFeatures._();

  /// Features introduced in each version.
  static const Map<String, ApiVersion> _featureVersions = {
    'video_calls': ApiVersion(1, 1, 0),
    'read_receipts': ApiVersion(1, 0, 0),
    'typing_indicators': ApiVersion(1, 0, 0),
    'super_likes': ApiVersion(1, 0, 0),
    'profile_boost': ApiVersion(1, 1, 0),
    'advanced_filters': ApiVersion(1, 2, 0),
    'voice_messages': ApiVersion(1, 2, 0),
    'reactions': ApiVersion(1, 1, 0),
  };

  /// Check if a feature is available in the current API version.
  static bool isAvailable(String feature, [ApiVersion? version]) {
    final current = version ?? ApiVersion.current;
    final required = _featureVersions[feature];
    if (required == null) {
      // Unknown feature - assume available
      AppLogger.debug('ApiFeatures: Unknown feature "$feature"');
      return true;
    }
    return current >= required;
  }

  /// Get the version that introduced a feature.
  static ApiVersion? getRequiredVersion(String feature) {
    return _featureVersions[feature];
  }

  /// Get all available features for a version.
  static List<String> getAvailableFeatures([ApiVersion? version]) {
    final current = version ?? ApiVersion.current;
    return _featureVersions.entries
        .where((e) => current >= e.value)
        .map((e) => e.key)
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VERSION NEGOTIATION
// ═══════════════════════════════════════════════════════════════════════════

/// Result of API version negotiation.
class VersionNegotiationResult {
  const VersionNegotiationResult({
    required this.clientVersion,
    required this.serverVersion,
    required this.negotiatedVersion,
    required this.isCompatible,
    this.deprecationWarning,
    this.upgradeRequired = false,
  });

  final ApiVersion clientVersion;
  final ApiVersion serverVersion;
  final ApiVersion negotiatedVersion;
  final bool isCompatible;
  final String? deprecationWarning;
  final bool upgradeRequired;

  /// Negotiate API version with server.
  static VersionNegotiationResult negotiate({
    required ApiVersion clientVersion,
    required ApiVersion serverMinVersion,
    required ApiVersion serverMaxVersion,
    ApiVersion? serverRecommendedVersion,
  }) {
    final isCompatible =
        clientVersion >= serverMinVersion &&
        clientVersion.isCompatibleWith(serverMaxVersion);

    final upgradeRequired = clientVersion < serverMinVersion;

    String? warning;
    if (serverRecommendedVersion != null &&
        clientVersion < serverRecommendedVersion) {
      warning =
          'A newer API version ($serverRecommendedVersion) is available. '
          'Please update for the best experience.';
    }

    // Use the highest compatible version
    final negotiated = clientVersion <= serverMaxVersion
        ? clientVersion
        : serverMaxVersion;

    return VersionNegotiationResult(
      clientVersion: clientVersion,
      serverVersion: serverMaxVersion,
      negotiatedVersion: negotiated,
      isCompatible: isCompatible,
      deprecationWarning: warning,
      upgradeRequired: upgradeRequired,
    );
  }
}

/// HTTP headers for API versioning.
class ApiHeaders {
  ApiHeaders._();

  /// Header for client API version.
  static const String clientVersion = 'X-API-Version';

  /// Header for minimum supported server version.
  static const String serverMinVersion = 'X-API-Min-Version';

  /// Header for maximum supported server version.
  static const String serverMaxVersion = 'X-API-Max-Version';

  /// Header for recommended server version.
  static const String serverRecommendedVersion = 'X-API-Recommended-Version';

  /// Header for deprecation warnings.
  static const String deprecationWarning = 'X-API-Deprecation-Warning';

  /// Header for feature flags.
  static const String featureFlags = 'X-Feature-Flags';

  /// Header for request ID (for tracing).
  static const String requestId = 'X-Request-ID';

  /// Header for client platform.
  static const String platform = 'X-Platform';

  /// Header for client app version.
  static const String appVersion = 'X-App-Version';

  /// Get default headers for requests.
  static Map<String, String> getDefaultHeaders({
    required String appVersion,
    required String platform,
    String? requestId,
  }) {
    final headers = <String, String>{
      clientVersion: ApiVersion.current.toString(),
      ApiHeaders.appVersion: appVersion,
      ApiHeaders.platform: platform,
    };
    if (requestId != null && requestId.isNotEmpty) {
      headers[ApiHeaders.requestId] = requestId;
    }
    return headers;
  }
}
