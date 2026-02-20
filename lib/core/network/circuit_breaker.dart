import 'package:crushhour/core/app_logger.dart';

/// States of a circuit breaker.
enum CircuitState {
  /// Normal operation — requests pass through.
  closed,

  /// Too many failures — requests are immediately rejected.
  open,

  /// Cooling down — one probe request is allowed to test recovery.
  halfOpen,
}

/// Configuration for a [CircuitBreaker].
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.failureWindowMs = 60000,
    this.cooldownMs = 30000,
    this.successThresholdForClose = 1,
  });

  /// Number of failures within [failureWindowMs] to trip the breaker open.
  final int failureThreshold;

  /// Time window (ms) in which failures are counted.
  final int failureWindowMs;

  /// How long (ms) the breaker stays open before transitioning to half-open.
  final int cooldownMs;

  /// Number of consecutive successes in half-open needed to close the breaker.
  final int successThresholdForClose;
}

/// A per-group circuit breaker that tracks consecutive failures and
/// short-circuits requests when a backend group is unhealthy.
///
/// Usage:
/// ```dart
/// final breaker = CircuitBreaker('chat');
/// if (!breaker.allowRequest()) {
///   return Result.failure('Service temporarily unavailable');
/// }
/// try {
///   final result = await apiClient.get('/chat/messages');
///   breaker.recordSuccess();
///   return result;
/// } catch (e) {
///   breaker.recordFailure();
///   rethrow;
/// }
/// ```
class CircuitBreaker {
  CircuitBreaker(
    this.group, {
    CircuitBreakerConfig? config,
    DateTime Function()? clock,
  }) : _config = config ?? const CircuitBreakerConfig(),
       _clock = clock ?? DateTime.now;

  /// The endpoint group name (e.g., 'auth', 'chat', 'discovery', 'profile').
  final String group;

  final CircuitBreakerConfig _config;
  final DateTime Function() _clock;

  CircuitState _state = CircuitState.closed;
  final List<DateTime> _failureTimestamps = [];
  DateTime? _openedAt;
  int _halfOpenSuccesses = 0;

  /// Current state of the breaker.
  CircuitState get state => _currentState();

  /// Whether the breaker is currently allowing requests.
  bool get isOpen => state == CircuitState.open;

  /// Whether the breaker is in half-open state (probing).
  bool get isHalfOpen => state == CircuitState.halfOpen;

  /// Whether the breaker is closed (healthy).
  bool get isClosed => state == CircuitState.closed;

  /// Check whether a request should be allowed.
  ///
  /// Returns `true` if the request can proceed, `false` if the circuit
  /// is open and the request should be short-circuited.
  bool allowRequest() {
    final current = _currentState();

    switch (current) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        AppLogger.debug(
          'CircuitBreaker[$group]: Request blocked — circuit open',
        );
        return false;
      case CircuitState.halfOpen:
        // Allow a single probe request
        return true;
    }
  }

  /// Record a successful response. Moves the breaker toward closed.
  void recordSuccess() {
    final current = _currentState();

    if (current == CircuitState.halfOpen) {
      _halfOpenSuccesses++;
      if (_halfOpenSuccesses >= _config.successThresholdForClose) {
        _transitionTo(CircuitState.closed);
      }
    } else if (current == CircuitState.closed) {
      // Clear stale failures on success
      _pruneOldFailures();
    }
  }

  /// Record a failed response. Moves the breaker toward open.
  void recordFailure() {
    final now = _clock();
    final current = _currentState();

    if (current == CircuitState.halfOpen) {
      // Probe failed — go back to open
      _transitionTo(CircuitState.open);
      return;
    }

    // Add failure timestamp and prune old ones
    _failureTimestamps.add(now);
    _pruneOldFailures();

    if (_failureTimestamps.length >= _config.failureThreshold) {
      _transitionTo(CircuitState.open);
    }
  }

  /// Reset the breaker to closed state. Useful after manual intervention.
  void reset() {
    _state = CircuitState.closed;
    _failureTimestamps.clear();
    _openedAt = null;
    _halfOpenSuccesses = 0;
    AppLogger.debug('CircuitBreaker[$group]: Manually reset to closed');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  CircuitState _currentState() {
    if (_state == CircuitState.open) {
      final now = _clock();
      final elapsed = now.difference(_openedAt!).inMilliseconds;
      if (elapsed >= _config.cooldownMs) {
        // Cooldown expired — transition to half-open
        _state = CircuitState.halfOpen;
        _halfOpenSuccesses = 0;
        AppLogger.debug('CircuitBreaker[$group]: Cooldown expired → half-open');
      }
    }
    return _state;
  }

  void _transitionTo(CircuitState newState) {
    final oldState = _state;
    _state = newState;

    switch (newState) {
      case CircuitState.open:
        _openedAt = _clock();
        _halfOpenSuccesses = 0;
        AppLogger.debug(
          'CircuitBreaker[$group]: $oldState → open '
          '(${_failureTimestamps.length} failures in window)',
        );
      case CircuitState.closed:
        _failureTimestamps.clear();
        _openedAt = null;
        _halfOpenSuccesses = 0;
        AppLogger.debug(
          'CircuitBreaker[$group]: $oldState → closed (recovered)',
        );
      case CircuitState.halfOpen:
        _halfOpenSuccesses = 0;
        AppLogger.debug('CircuitBreaker[$group]: $oldState → half-open');
    }
  }

  void _pruneOldFailures() {
    final cutoff = _clock().subtract(
      Duration(milliseconds: _config.failureWindowMs),
    );
    _failureTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}

/// Registry of circuit breakers keyed by endpoint group.
///
/// Provides a singleton per group so all callers share the same state.
/// ```dart
/// final breaker = CircuitBreakerRegistry.instance.get('chat');
/// ```
class CircuitBreakerRegistry {
  CircuitBreakerRegistry._();

  static final CircuitBreakerRegistry instance = CircuitBreakerRegistry._();

  final Map<String, CircuitBreaker> _breakers = {};

  /// Default configuration used for all breakers unless overridden.
  CircuitBreakerConfig defaultConfig = const CircuitBreakerConfig();

  /// Get or create a [CircuitBreaker] for the given [group].
  CircuitBreaker get(String group, {CircuitBreakerConfig? config}) {
    return _breakers.putIfAbsent(
      group,
      () => CircuitBreaker(group, config: config ?? defaultConfig),
    );
  }

  /// Check whether the breaker for [group] is currently open.
  bool isOpen(String group) {
    return _breakers[group]?.isOpen ?? false;
  }

  /// Reset all breakers (e.g., on network reconnect).
  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }

  /// Remove all breakers (for testing).
  void clear() {
    _breakers.clear();
  }
}
