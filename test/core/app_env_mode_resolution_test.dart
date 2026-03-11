import 'package:crushhour/core/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppEnvForFlavor', () {
    test('returns dev only for development aliases', () {
      expect(resolveAppEnvForFlavor('development'), AppEnv.dev);
      expect(resolveAppEnvForFlavor('dev'), AppEnv.dev);
    });

    test('returns prod for staging, production, and unknown values', () {
      expect(resolveAppEnvForFlavor('staging'), AppEnv.prod);
      expect(resolveAppEnvForFlavor('production'), AppEnv.prod);
      expect(resolveAppEnvForFlavor('anything-else'), AppEnv.prod);
    });
  });
}
