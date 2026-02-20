import 'package:crushhour/core/network/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircuitBreaker', () {
    late DateTime now;
    late CircuitBreaker breaker;

    setUp(() {
      now = DateTime(2026, 2, 19, 12, 0, 0);
      breaker = CircuitBreaker(
        'test',
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          failureWindowMs: 10000,
          cooldownMs: 5000,
        ),
        clock: () => now,
      );
    });

    test('starts in closed state', () {
      expect(breaker.state, CircuitState.closed);
      expect(breaker.isClosed, true);
      expect(breaker.isOpen, false);
      expect(breaker.allowRequest(), true);
    });

    test('stays closed when failures are below threshold', () {
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest(), true);
    });

    test('opens after reaching failure threshold', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, CircuitState.open);
      expect(breaker.isOpen, true);
      expect(breaker.allowRequest(), false);
    });

    test('blocks requests when open', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.allowRequest(), false);
      expect(breaker.allowRequest(), false);
    });

    test('transitions to half-open after cooldown', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, CircuitState.open);

      // Advance time past cooldown
      now = now.add(const Duration(milliseconds: 5001));
      expect(breaker.state, CircuitState.halfOpen);
      expect(breaker.isHalfOpen, true);
      expect(breaker.allowRequest(), true);
    });

    test('closes from half-open after success', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }

      // Advance past cooldown
      now = now.add(const Duration(milliseconds: 5001));
      expect(breaker.state, CircuitState.halfOpen);

      // Record success
      breaker.recordSuccess();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.isClosed, true);
      expect(breaker.allowRequest(), true);
    });

    test('re-opens from half-open after failure', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }

      // Advance past cooldown
      now = now.add(const Duration(milliseconds: 5001));
      expect(breaker.state, CircuitState.halfOpen);

      // Failure during probe
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);
    });

    test('prunes failures outside the window', () {
      breaker.recordFailure();
      breaker.recordFailure();

      // Advance time so the first 2 failures are outside the window
      now = now.add(const Duration(milliseconds: 11000));

      // This should not trip the breaker (old failures pruned)
      breaker.recordFailure();
      expect(breaker.state, CircuitState.closed);
    });

    test('reset returns to closed state', () {
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, CircuitState.open);

      breaker.reset();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest(), true);
    });

    test('success clears stale failures in closed state', () {
      breaker.recordFailure();
      breaker.recordFailure();

      // Advance past window
      now = now.add(const Duration(milliseconds: 11000));
      breaker.recordSuccess();

      // Failures should have been pruned, so adding 2 more shouldn't trip
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.closed);
    });
  });

  group('CircuitBreakerRegistry', () {
    late CircuitBreakerRegistry registry;

    setUp(() {
      registry = CircuitBreakerRegistry.instance;
      registry.clear();
    });

    test('returns same breaker for same group', () {
      final a = registry.get('chat');
      final b = registry.get('chat');
      expect(identical(a, b), true);
    });

    test('returns different breakers for different groups', () {
      final chat = registry.get('chat');
      final auth = registry.get('auth');
      expect(identical(chat, auth), false);
    });

    test('isOpen returns false for unknown group', () {
      expect(registry.isOpen('nonexistent'), false);
    });

    test('resetAll resets all breakers', () {
      final chat = registry.get(
        'chat',
        config: const CircuitBreakerConfig(failureThreshold: 1),
      );
      final auth = registry.get(
        'auth',
        config: const CircuitBreakerConfig(failureThreshold: 1),
      );

      chat.recordFailure();
      auth.recordFailure();

      expect(chat.isOpen, true);
      expect(auth.isOpen, true);

      registry.resetAll();

      expect(chat.isClosed, true);
      expect(auth.isClosed, true);
    });
  });
}
