import 'package:crushhour/core/services/crash_reporting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashReportingService hotspot baseline', () {
    test('public APIs are safe to call in test/debug mode', () async {
      final service = CrashReportingService.instance;

      expect(service.isCrashlyticsCollectionEnabled, isFalse);

      // In tests this may fail to initialize due plugin constants/channels.
      // The service is expected to handle that gracefully.
      await service.initialize();

      await service.recordError(
        Exception('non-fatal'),
        StackTrace.current,
        reason: 'unit-test',
        information: {'feature': 'crash_reporting'},
      );
      await service.recordFlutterError(
        FlutterErrorDetails(exception: Exception('flutter-error')),
      );
      await service.setUserId('user-123');
      await service.clearUserId();
      await service.setCustomKey('build', 'test');
      await service.setCustomKeys({'platform': 'test', 'channel': 'unit'});
      await service.log('hello');
      await service.logNavigation('home', 'settings');
      await service.logUserAction('tap_button', params: {'id': 'save'});
      await service.logApiCall('/v1/messages', statusCode: 200);
      await service.logApiCall('/v1/messages', error: 'timeout');
      await service.logApiCall('/v1/messages');

      service.testCrash();
      expect(kDebugMode, isTrue);
    });
  });
}
