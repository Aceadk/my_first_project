import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';

void main() {
  group('DiscoverySettingsCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('clamps invalid persisted age values on startup', () async {
      SharedPreferences.setMockInitialValues({
        'discovery_min_age': 15,
        'discovery_max_age': 99,
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      expect(cubit.state.minAge, 18);
      expect(cubit.state.maxAge, 75);
    });

    test('keeps maxAge >= minAge when persisted range is inverted', () async {
      SharedPreferences.setMockInitialValues({
        'discovery_min_age': 33,
        'discovery_max_age': 21,
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      expect(cubit.state.minAge, 33);
      expect(cubit.state.maxAge, 33);
    });

    test('clamps and persists distance', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      await cubit.setDistance(999);
      expect(cubit.state.distanceKm, 200.0);
      expect(prefs.getDouble('discovery_distance_km'), 200.0);

      await cubit.setDistance(0);
      expect(cubit.state.distanceKm, 1.0);
      expect(prefs.getDouble('discovery_distance_km'), 1.0);
    });

    test('normalizes and deduplicates interests before persisting', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      await cubit.setInterests([' music ', '', 'music', 'sports', '  ']);

      expect(cubit.state.interests, ['music', 'sports']);
      expect(
        prefs.getStringList('discovery_interests'),
        ['music', 'sports'],
      );
    });

    test('sets and clears passport location data', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      await cubit.setPassportMode(true);
      await cubit.setPassportLocation(
        locationName: 'Paris, France',
        latitude: 48.8566,
        longitude: 2.3522,
      );

      expect(cubit.state.passportModeEnabled, isTrue);
      expect(cubit.state.passportLocation, 'Paris, France');
      expect(prefs.getString('discovery_passport_location'), 'Paris, France');
      expect(prefs.getDouble('discovery_passport_lat'), 48.8566);
      expect(prefs.getDouble('discovery_passport_lng'), 2.3522);

      await cubit.clearPassportLocation();
      expect(cubit.state.passportModeEnabled, isFalse);
      expect(prefs.getBool('discovery_passport_enabled'), isFalse);
      expect(prefs.getString('discovery_passport_location'), isNull);
      expect(prefs.getDouble('discovery_passport_lat'), isNull);
      expect(prefs.getDouble('discovery_passport_lng'), isNull);
    });

    test('tracks advanced filters and clears them completely', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      await cubit.setHeightRange(minCm: 110, maxCm: 300);
      await cubit.setEducationLevels(['bachelors']);
      await cubit.setVerifiedOnly(true);
      await cubit.setSmokingFilter('never');

      expect(cubit.state.minHeightCm, 120);
      expect(cubit.state.maxHeightCm, 220);
      expect(cubit.state.hasActiveAdvancedFilters, isTrue);
      expect(cubit.state.activeAdvancedFilterCount, 4);

      await cubit.clearAllAdvancedFilters();

      expect(cubit.state.hasActiveAdvancedFilters, isFalse);
      expect(cubit.state.activeAdvancedFilterCount, 0);
      expect(cubit.state.minHeightCm, isNull);
      expect(cubit.state.maxHeightCm, isNull);
      expect(cubit.state.educationLevels, isEmpty);
      expect(cubit.state.verifiedOnly, isFalse);
      expect(cubit.state.smokingFilter, isNull);
      expect(prefs.getInt('discovery_min_height_cm'), isNull);
      expect(prefs.getInt('discovery_max_height_cm'), isNull);
      expect(prefs.getString('discovery_smoking_filter'), isNull);
    });

    test('setAgeRange clamps to valid bounds and order', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = DiscoverySettingsCubit(preferences: prefs);

      await cubit.setAgeRange(const RangeValues(16, 83));

      expect(cubit.state.minAge, 18);
      expect(cubit.state.maxAge, 75);
      expect(prefs.getInt('discovery_min_age'), 18);
      expect(prefs.getInt('discovery_max_age'), 75);
    });
  });
}
