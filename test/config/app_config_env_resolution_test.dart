import 'package:crushhour/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveFlavorForEnv', () {
    test('prefers FLAVOR when both FLAVOR and APP_ENV are provided', () {
      final flavor = resolveFlavorForEnv(
        flavor: 'production',
        legacyAppEnv: 'dev',
      );

      expect(flavor, 'production');
    });

    test('normalizes FLAVOR aliases', () {
      final devFlavor = resolveFlavorForEnv(flavor: 'dev', legacyAppEnv: '');
      final prodFlavor = resolveFlavorForEnv(flavor: 'prod', legacyAppEnv: '');

      expect(devFlavor, 'development');
      expect(prodFlavor, 'production');
    });

    test('falls back to legacy APP_ENV when FLAVOR is empty', () {
      final devFlavor = resolveFlavorForEnv(flavor: '', legacyAppEnv: 'dev');
      final stagingFlavor = resolveFlavorForEnv(
        flavor: '',
        legacyAppEnv: 'staging',
      );
      final prodFlavor = resolveFlavorForEnv(flavor: '', legacyAppEnv: 'prod');

      expect(devFlavor, 'development');
      expect(stagingFlavor, 'staging');
      expect(prodFlavor, 'production');
    });

    test('uses fallback when FLAVOR and APP_ENV are both unknown', () {
      final flavor = resolveFlavorForEnv(
        flavor: 'qa',
        legacyAppEnv: 'sandbox',
        fallback: 'production',
      );

      expect(flavor, 'production');
    });
  });
}
