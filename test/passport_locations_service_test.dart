import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/features/discovery/data/services/passport_locations_service.dart';

void main() {
  group('PassportLocationsService', () {
    late PassportLocationsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = PassportLocationsService.instance;
    });

    test('recordLocation increments counts and ignores empty values', () async {
      await service.recordLocation('', 'Nepal');
      await service.recordLocation('Kathmandu', '');
      expect(await service.getLocationCount('Kathmandu', 'Nepal'), equals(0));

      await service.recordLocation('Kathmandu', 'Nepal');
      await service.recordLocation('Kathmandu', 'Nepal');
      expect(await service.getLocationCount('Kathmandu', 'Nepal'), equals(2));
    });

    test('adds location to passport list when threshold is reached', () async {
      SharedPreferences.setMockInitialValues(const {
        'passport_location_counts': '{"kathmandu|nepal":999}',
      });

      await service.recordLocation('Kathmandu', 'Nepal');
      final locations = await service.getPassportLocations();

      expect(
        locations.any(
          (l) => l['city'] == 'Kathmandu' && l['country'] == 'Nepal',
        ),
        isTrue,
      );
    });

    test('getPassportLocations merges defaults and sorts by city', () async {
      final locations = await service.getPassportLocations();
      expect(locations, isNotEmpty);

      final cities = locations.map((l) => l['city'] ?? '').toList();
      final sorted = List<String>.from(cities)..sort();
      expect(cities, equals(sorted));
      expect(cities, contains('New York'));
      expect(cities, contains('Tokyo'));
    });

    test('searchLocations filters by city or country', () async {
      SharedPreferences.setMockInitialValues(const {
        'passport_available_locations':
            '[{"city":"Kathmandu","country":"Nepal"},{"city":"Pokhara","country":"Nepal"}]',
      });

      final byCity = await service.searchLocations('kath');
      expect(byCity.any((l) => l['city'] == 'Kathmandu'), isTrue);

      final byCountry = await service.searchLocations('nepal');
      expect(byCountry.length, greaterThanOrEqualTo(2));

      final allForEmpty = await service.searchLocations('');
      expect(allForEmpty.length, greaterThanOrEqualTo(byCountry.length));
    });

    test('getTrendingLocations returns top locations sorted by count', () async {
      SharedPreferences.setMockInitialValues(const {
        'passport_location_counts':
            '{"kathmandu|nepal":10,"pokhara|nepal":25,"london|united kingdom":5}',
      });

      final trending = await service.getTrendingLocations();
      expect(trending, hasLength(3));
      expect(trending.first['city'], equals('pokhara'));
      expect(trending.first['country'], equals('nepal'));
      expect(trending.first['count'], equals(25));
    });
  });
}
