import 'dart:async';
import 'dart:math';

import 'package:crushhour/core/app_logger.dart';

/// Configuration for retry behavior with exponential backoff.
///
/// Used by BLoCs and services to standardize retry logic across the app.
///
/// ```dart
/// final policy = RetryPolicy();
/// final result = await policy.execute(
///   action: () => api.fetchProfile(userId),
///   retryIf: (e) => e is! AuthException,
///   label: 'ProfileBloc.load',
/// );
/// ```
class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = true,
  });

  /// Preset: conservative retry for user-facing BLoC actions.
  static const bloc = RetryPolicy(
    maxRetries: 2,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 8),
  );

  /// Preset: aggressive retry for background/infrastructure tasks.
  static const background = RetryPolicy(
    maxRetries: 5,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 30),
  );

  /// Preset: single retry for quick checks.
  static const quick = RetryPolicy(
    maxRetries: 1,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 2),
    jitter: false,
  );

  /// Maximum number of retry attempts (0 = no retries, just the initial call).
  final int maxRetries;

  /// Base delay between retries (doubles each attempt).
  final Duration baseDelay;

  /// Maximum delay cap.
  final Duration maxDelay;

  /// Whether to add random jitter (±20%) to the delay.
  final bool jitter;

  /// Calculate the delay for a given [attempt] (0-indexed).
  Duration delayForAttempt(int attempt) {
    final exponential = baseDelay.inMilliseconds * (1 << attempt);
    final clamped = exponential.clamp(0, maxDelay.inMilliseconds);

    if (!jitter) return Duration(milliseconds: clamped);

    // Add ±20% jitter to prevent thundering herd
    final jitterRange = (clamped * 0.2).round();
    final jitterOffset = jitterRange > 0
        ? Random().nextInt(jitterRange * 2) - jitterRange
        : 0;
    final withJitter = (clamped + jitterOffset).clamp(
      0,
      maxDelay.inMilliseconds,
    );

    return Duration(milliseconds: withJitter);
  }

  /// Execute [action] with retries according to this policy.
  ///
  /// - [retryIf]: Optional predicate. If it returns `false`, the error is
  ///   rethrown immediately without further retries. Defaults to retrying all.
  /// - [label]: Optional label for logging.
  /// - [onRetry]: Optional callback invoked before each retry with the
  ///   attempt number and delay.
  Future<T> execute<T>({
    required Future<T> Function() action,
    bool Function(Object error)? retryIf,
    String? label,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await action();
      } catch (error, stackTrace) {
        final isLastAttempt = attempt >= maxRetries;
        final shouldRetry = retryIf?.call(error) ?? true;

        if (isLastAttempt || !shouldRetry) {
          if (label != null) {
            AppLogger.error(
              'RetryPolicy[$label]: Failed after ${attempt + 1} attempt(s)',
              error: error,
              stackTrace: stackTrace,
            );
          }
          rethrow;
        }

        final delay = delayForAttempt(attempt);

        if (label != null) {
          AppLogger.debug(
            'RetryPolicy[$label]: Attempt ${attempt + 1} failed, '
            'retrying in ${delay.inMilliseconds}ms',
          );
        }

        onRetry?.call(attempt + 1, delay);
        await Future<void>.delayed(delay);
      }
    }

    // Unreachable, but satisfies the type system
    throw StateError('RetryPolicy: unexpected state');
  }
}
