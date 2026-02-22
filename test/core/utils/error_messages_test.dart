import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/utils/error_messages.dart';

void main() {
  group('ErrorMessages helpers', () {
    test('couldNot formats retry guidance consistently', () {
      expect(
        ErrorMessages.couldNot('load profile'),
        'Could not load profile. Please try again.',
      );
    });

    test('plusFeature formats upgrade copy consistently', () {
      expect(
        ErrorMessages.plusFeature('Rewind'),
        'Rewind is a Plus feature. Upgrade to unlock!',
      );
    });
  });
}
