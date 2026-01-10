import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages user session with inactivity timeout for security.
///
/// SECURITY FEATURES:
/// - Tracks user activity and logs out after inactivity period
/// - Persists last activity time in secure storage
/// - Configurable timeout duration
/// - Can be disabled for development if needed
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();

  SessionManager._();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _lastActivityKey = 'last_activity_timestamp';
  static const String _sessionEnabledKey = 'session_timeout_enabled';

  /// Session timeout duration. Default is 30 minutes.
  /// Set to a shorter duration for more sensitive apps.
  Duration timeoutDuration = const Duration(minutes: 30);

  /// Whether session timeout is enabled.
  /// Can be disabled for development.
  bool _enabled = true;
  bool get isEnabled => _enabled;

  Timer? _inactivityTimer;
  DateTime? _lastActivity;

  /// Callback invoked when session expires due to inactivity.
  VoidCallback? onSessionExpired;

  /// Initialize the session manager.
  /// Call this at app startup after authentication.
  Future<void> initialize({
    Duration? timeout,
    VoidCallback? onExpired,
    bool enabled = true,
  }) async {
    if (timeout != null) {
      timeoutDuration = timeout;
    }
    onSessionExpired = onExpired;
    _enabled = enabled;

    // Restore last activity from secure storage
    final storedTimestamp = await _secureStorage.read(key: _lastActivityKey);
    if (storedTimestamp != null) {
      _lastActivity = DateTime.tryParse(storedTimestamp);
    }

    // Check if session has expired while app was closed
    if (_enabled && _lastActivity != null) {
      final elapsed = DateTime.now().difference(_lastActivity!);
      if (elapsed > timeoutDuration) {
        // Session expired while app was closed
        onSessionExpired?.call();
        return;
      }
    }

    // Start fresh activity tracking
    recordActivity();
  }

  /// Record user activity to reset the inactivity timer.
  /// Call this on user interactions (taps, scrolls, etc).
  void recordActivity() {
    if (!_enabled) return;

    _lastActivity = DateTime.now();
    _saveLastActivity();
    _resetTimer();
  }

  /// Start or restart the inactivity timer.
  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeoutDuration, _onTimeout);
  }

  void _onTimeout() {
    if (!_enabled) return;

    // Verify timeout by checking actual elapsed time
    if (_lastActivity != null) {
      final elapsed = DateTime.now().difference(_lastActivity!);
      if (elapsed >= timeoutDuration) {
        onSessionExpired?.call();
      } else {
        // Activity happened recently, restart timer with remaining time
        final remaining = timeoutDuration - elapsed;
        _inactivityTimer = Timer(remaining, _onTimeout);
      }
    }
  }

  Future<void> _saveLastActivity() async {
    if (_lastActivity != null) {
      await _secureStorage.write(
        key: _lastActivityKey,
        value: _lastActivity!.toIso8601String(),
      );
    }
  }

  /// Check if the session is still valid.
  Future<bool> isSessionValid() async {
    if (!_enabled) return true;

    final storedTimestamp = await _secureStorage.read(key: _lastActivityKey);
    if (storedTimestamp == null) return true;

    final lastActivity = DateTime.tryParse(storedTimestamp);
    if (lastActivity == null) return true;

    final elapsed = DateTime.now().difference(lastActivity);
    return elapsed < timeoutDuration;
  }

  /// Get remaining session time.
  Duration? get remainingTime {
    if (!_enabled || _lastActivity == null) return null;

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = timeoutDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Pause session tracking (e.g., when app goes to background).
  void pause() {
    _inactivityTimer?.cancel();
  }

  /// Resume session tracking (e.g., when app comes to foreground).
  /// Checks if session expired while paused.
  void resume() {
    if (!_enabled || _lastActivity == null) {
      recordActivity();
      return;
    }

    final elapsed = DateTime.now().difference(_lastActivity!);
    if (elapsed >= timeoutDuration) {
      onSessionExpired?.call();
    } else {
      _resetTimer();
    }
  }

  /// Clear session data on logout.
  Future<void> clearSession() async {
    _inactivityTimer?.cancel();
    _lastActivity = null;
    await _secureStorage.delete(key: _lastActivityKey);
  }

  /// Enable or disable session timeout.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _secureStorage.write(
      key: _sessionEnabledKey,
      value: enabled.toString(),
    );

    if (enabled) {
      recordActivity();
    } else {
      _inactivityTimer?.cancel();
    }
  }

  /// Dispose of resources.
  void dispose() {
    _inactivityTimer?.cancel();
  }
}

/// Mixin to add activity tracking to widgets.
/// Use with StatefulWidget to automatically record activity on user interactions.
mixin ActivityTrackingMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SessionManager.instance.recordActivity();
  }

  /// Call this in gesture handlers to record activity.
  void recordUserActivity() {
    SessionManager.instance.recordActivity();
  }
}
