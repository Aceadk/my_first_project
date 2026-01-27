/// Network-related constants for consistent API behavior.
///
/// Centralizes timeouts and retry configurations to ensure
/// consistent network behavior across the app.
class NetworkConstants {
  NetworkConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUEST TIMEOUTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default timeout for API requests.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Short timeout for quick operations (e.g., auth checks).
  static const Duration shortTimeout = Duration(seconds: 10);

  /// Medium timeout for standard operations (e.g., fetching lists).
  static const Duration mediumTimeout = Duration(seconds: 15);

  /// Long timeout for uploads and heavy operations.
  static const Duration longTimeout = Duration(seconds: 60);

  /// Extra long timeout for very heavy operations (e.g., video uploads).
  static const Duration uploadTimeout = Duration(seconds: 120);

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION TIMEOUTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Timeout for establishing a connection.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Timeout for receiving data after connection is established.
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════════════════
  // RETRY CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum number of retry attempts for failed requests.
  static const int maxRetryAttempts = 3;

  /// Initial delay before first retry (doubles with each attempt).
  static const Duration retryDelay = Duration(seconds: 1);

  /// Maximum delay between retries.
  static const Duration maxRetryDelay = Duration(seconds: 8);

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME / WEBSOCKET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heartbeat interval for realtime connections.
  static const Duration heartbeatInterval = Duration(seconds: 30);

  /// Timeout before considering realtime connection dead.
  static const Duration realtimeTimeout = Duration(seconds: 60);

  /// Delay before attempting to reconnect after disconnect.
  static const Duration reconnectDelay = Duration(seconds: 2);

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Timeout for getting current location.
  static const Duration locationTimeout = Duration(seconds: 10);

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Timeout for loading images from network.
  static const Duration imageLoadTimeout = Duration(seconds: 30);

  /// Fade-in duration for loaded images.
  static const Duration imageFadeInDuration = Duration(milliseconds: 200);
}
