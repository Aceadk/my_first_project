import 'package:flutter_test/flutter_test.dart';

/// Placeholder integration tests for callable Functions.
/// These are skipped by default; configure Firebase emulators/credentials to run.
void main() {
  group('Functions integration (emulator/qa)', () {
    test('swipeRight and preMatch request', () async {
      // TODO: Wire to emulator with auth + sample users.
    }, skip: 'Requires Firebase emulator and seeded data.');

    test('checkout flow starts and returns url', () async {
      // TODO: Hit purchasePlusPlan callable in emulator and assert URL.
    }, skip: 'Requires Firebase emulator and billing config.');
  });
}
