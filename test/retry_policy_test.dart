import 'package:crushhour/core/utils/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryPolicy', () {
    group('delayForAttempt', () {
      test('doubles delay each attempt without jitter', () {
        const policy = RetryPolicy(
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 30),
          jitter: false,
        );

        expect(policy.delayForAttempt(0), const Duration(seconds: 1));
        expect(policy.delayForAttempt(1), const Duration(seconds: 2));
        expect(policy.delayForAttempt(2), const Duration(seconds: 4));
        expect(policy.delayForAttempt(3), const Duration(seconds: 8));
        expect(policy.delayForAttempt(4), const Duration(seconds: 16));
      });

      test('clamps to maxDelay', () {
        const policy = RetryPolicy(
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 8),
          jitter: false,
        );

        expect(policy.delayForAttempt(3), const Duration(seconds: 8));
        expect(policy.delayForAttempt(4), const Duration(seconds: 8));
        expect(policy.delayForAttempt(10), const Duration(seconds: 8));
      });

      test('adds jitter within ±20%', () {
        const policy = RetryPolicy(
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 30),
          jitter: true,
        );

        // Run multiple times to verify jitter stays within bounds
        for (var i = 0; i < 50; i++) {
          final delay = policy.delayForAttempt(2); // base = 4000ms
          expect(delay.inMilliseconds, greaterThanOrEqualTo(3200)); // 4000 - 20%
          expect(delay.inMilliseconds, lessThanOrEqualTo(4800)); // 4000 + 20%
        }
      });
    });

    group('execute', () {
      test('returns result on first success', () async {
        const policy = RetryPolicy(maxRetries: 3, jitter: false);

        var callCount = 0;
        final result = await policy.execute(
          action: () async {
            callCount++;
            return 42;
          },
          label: 'test',
        );

        expect(result, 42);
        expect(callCount, 1);
      });

      test('retries on failure and succeeds', () async {
        const policy = RetryPolicy(
          maxRetries: 3,
          baseDelay: Duration(milliseconds: 10),
          jitter: false,
        );

        var callCount = 0;
        final result = await policy.execute(
          action: () async {
            callCount++;
            if (callCount < 3) throw Exception('fail');
            return 'success';
          },
          label: 'test',
        );

        expect(result, 'success');
        expect(callCount, 3);
      });

      test('throws after max retries exhausted', () async {
        const policy = RetryPolicy(
          maxRetries: 2,
          baseDelay: Duration(milliseconds: 10),
          jitter: false,
        );

        var callCount = 0;
        expect(
          () => policy.execute(
            action: () async {
              callCount++;
              throw Exception('always fails');
            },
            label: 'test',
          ),
          throwsA(isA<Exception>()),
        );

        // Wait for retries to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(callCount, 3); // 1 initial + 2 retries
      });

      test('skips retry when retryIf returns false', () async {
        const policy = RetryPolicy(
          maxRetries: 3,
          baseDelay: Duration(milliseconds: 10),
          jitter: false,
        );

        var callCount = 0;
        expect(
          () => policy.execute(
            action: () async {
              callCount++;
              throw ArgumentError('not retryable');
            },
            retryIf: (e) => e is! ArgumentError,
            label: 'test',
          ),
          throwsA(isA<ArgumentError>()),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(callCount, 1); // No retries — failed immediately
      });

      test('calls onRetry callback before each retry', () async {
        const policy = RetryPolicy(
          maxRetries: 2,
          baseDelay: Duration(milliseconds: 10),
          jitter: false,
        );

        final retryAttempts = <int>[];
        var callCount = 0;

        final result = await policy.execute(
          action: () async {
            callCount++;
            if (callCount < 3) throw Exception('fail');
            return 'ok';
          },
          onRetry: (attempt, delay) {
            retryAttempts.add(attempt);
          },
          label: 'test',
        );

        expect(result, 'ok');
        expect(retryAttempts, [1, 2]);
      });

      test('works with zero retries', () async {
        const policy = RetryPolicy(maxRetries: 0);

        var callCount = 0;
        expect(
          () => policy.execute(
            action: () async {
              callCount++;
              throw Exception('fail');
            },
          ),
          throwsA(isA<Exception>()),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(callCount, 1);
      });
    });

    group('presets', () {
      test('bloc preset has expected values', () {
        expect(RetryPolicy.bloc.maxRetries, 2);
        expect(RetryPolicy.bloc.baseDelay, const Duration(seconds: 1));
        expect(RetryPolicy.bloc.maxDelay, const Duration(seconds: 8));
      });

      test('background preset has expected values', () {
        expect(RetryPolicy.background.maxRetries, 5);
        expect(RetryPolicy.background.maxDelay, const Duration(seconds: 30));
      });

      test('quick preset has expected values', () {
        expect(RetryPolicy.quick.maxRetries, 1);
        expect(RetryPolicy.quick.jitter, false);
      });
    });
  });
}
