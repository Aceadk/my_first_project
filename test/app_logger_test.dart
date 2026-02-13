import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    test('debug, info, and warning accept structured payloads', () {
      expect(() {
        AppLogger.debug('debug message', data: {'flow': 'onboarding'});
        AppLogger.info('info message', data: {'userId': 'u_1'});
        AppLogger.warning(
          'warning message',
          error: StateError('soft warning'),
          data: {'retry': 1},
        );
      }, returnsNormally);
    });

    test('error accepts error and stack trace in debug mode', () {
      final stack = StackTrace.current;

      expect(
        () => AppLogger.error(
          'error message',
          error: Exception('boom'),
          stackTrace: stack,
          data: {'screen': 'chat'},
          reportToCrashlytics: false,
        ),
        returnsNormally,
      );
    });

    test('network, lifecycle, and performance helpers are callable', () {
      expect(() {
        AppLogger.network(
          'GET',
          '/api/v1/matches',
          statusCode: 200,
          duration: const Duration(milliseconds: 123),
        );
        AppLogger.network(
          'POST',
          '/api/v1/chat',
          error: StateError('socket unavailable'),
        );
        AppLogger.lifecycle('resume', context: 'chat_screen');
        AppLogger.performance(
          'chat_open',
          const Duration(milliseconds: 16),
          data: {'frameBudget': 'ok'},
        );
      }, returnsNormally);
    });
  });
}
