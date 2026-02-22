import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/discovery/domain/models/filter_options.dart';

void main() {
  group('DiscoveryFilterOptions', () {
    test('getLabelForId returns matching label when option exists', () {
      final label = DiscoveryFilterOptions.getLabelForId(
        'masters',
        DiscoveryFilterOptions.educationLevels,
      );

      expect(label, 'Master\'s');
    });

    test('getLabelForId returns null when option does not exist', () {
      final label = DiscoveryFilterOptions.getLabelForId(
        'unknown_id',
        DiscoveryFilterOptions.educationLevels,
      );

      expect(label, isNull);
    });

    test('core option lists expose stable expected counts', () {
      expect(DiscoveryFilterOptions.educationLevels.length, 8);
      expect(DiscoveryFilterOptions.relationshipGoals.length, 6);
      expect(DiscoveryFilterOptions.smokingOptions.length, 4);
      expect(DiscoveryFilterOptions.drinkingOptions.length, 4);
      expect(DiscoveryFilterOptions.exerciseOptions.length, 4);
      expect(DiscoveryFilterOptions.petsOptions.length, 10);
      expect(DiscoveryFilterOptions.familyPlansOptions.length, 6);
      expect(DiscoveryFilterOptions.zodiacSigns.length, 12);
      expect(DiscoveryFilterOptions.religionOptions.length, 11);
      expect(DiscoveryFilterOptions.languages.length, 20);
    });
  });

  group('HeightUtils', () {
    test('cmToFeetInches converts known values', () {
      expect(HeightUtils.cmToFeetInches(180), '5\'11"');
      expect(HeightUtils.cmToFeetInches(152), '4\'12"');
    });

    test('feetInchesToCm converts known values', () {
      expect(HeightUtils.feetInchesToCm(5, 11), 180);
      expect(HeightUtils.feetInchesToCm(6, 0), 183);
    });

    test('getDisplayHeight includes both metric and imperial values', () {
      final display = HeightUtils.getDisplayHeight(180);

      expect(display, startsWith('180 cm'));
      expect(display, contains('('));
      expect(display, contains('5\'11"'));
      expect(display, endsWith(')'));
    });

    test('min and max slider bounds are stable', () {
      expect(HeightUtils.minHeight, 120);
      expect(HeightUtils.maxHeight, 220);
      expect(HeightUtils.maxHeight, greaterThan(HeightUtils.minHeight));
    });
  });
}
