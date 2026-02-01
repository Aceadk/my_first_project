/// Main integration test file that runs all critical flow tests.
///
/// Run with:
/// ```
/// flutter test integration_test/app_test.dart
/// ```
///
/// Or run individual test files:
/// ```
/// flutter test integration_test/auth_flow_test.dart
/// flutter test integration_test/discovery_flow_test.dart
/// flutter test integration_test/chat_flow_test.dart
/// ```
///
/// For device testing:
/// ```
/// flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'auth_flow_test.dart' as auth_tests;
import 'discovery_flow_test.dart' as discovery_tests;
import 'chat_flow_test.dart' as chat_tests;
import 'e2e_onboarding_to_chat_test.dart' as e2e_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CrushHour Integration Tests', () {
    auth_tests.main();
    discovery_tests.main();
    chat_tests.main();
    e2e_tests.main();
  });
}
