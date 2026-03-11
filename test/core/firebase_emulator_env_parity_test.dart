import 'package:crushhour/core/firebase_emulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firebase emulator env parity', () {
    test('prefers modern emulator host override when provided', () {
      final host = resolveEmulatorHostOverrideForEnv(
        emulatorHostOverride: 'new-host',
        legacyEmulatorHost: 'legacy-host',
      );

      expect(host, 'new-host');
    });

    test('falls back to legacy emulator host when modern key is empty', () {
      final host = resolveEmulatorHostOverrideForEnv(
        emulatorHostOverride: '',
        legacyEmulatorHost: 'legacy-host',
      );

      expect(host, 'legacy-host');
    });
  });
}
