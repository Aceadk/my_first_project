import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to track popular locations entered by users.
/// When a location reaches 1000+ entries, it becomes available in Passport Mode.
class PassportLocationsService {
  PassportLocationsService._();
  static final PassportLocationsService instance = PassportLocationsService._();

  static const String _locationCountsKey = 'passport_location_counts';
  static const String _passportLocationsKey = 'passport_available_locations';
  static const int _thresholdForPassport = 1000;

  // Default passport locations (always available)
  static const List<Map<String, String>> defaultLocations = [
    {'city': 'New York', 'country': 'United States'},
    {'city': 'Los Angeles', 'country': 'United States'},
    {'city': 'London', 'country': 'United Kingdom'},
    {'city': 'Paris', 'country': 'France'},
    {'city': 'Tokyo', 'country': 'Japan'},
    {'city': 'Dubai', 'country': 'United Arab Emirates'},
    {'city': 'Sydney', 'country': 'Australia'},
    {'city': 'Toronto', 'country': 'Canada'},
    {'city': 'Berlin', 'country': 'Germany'},
    {'city': 'Amsterdam', 'country': 'Netherlands'},
    {'city': 'Barcelona', 'country': 'Spain'},
    {'city': 'Rome', 'country': 'Italy'},
    {'city': 'Singapore', 'country': 'Singapore'},
    {'city': 'Hong Kong', 'country': 'China'},
    {'city': 'Mumbai', 'country': 'India'},
    {'city': 'São Paulo', 'country': 'Brazil'},
    {'city': 'Mexico City', 'country': 'Mexico'},
    {'city': 'Bangkok', 'country': 'Thailand'},
    {'city': 'Seoul', 'country': 'South Korea'},
    {'city': 'Istanbul', 'country': 'Turkey'},
  ];

  /// Record a user's location entry. Increments the count for that location.
  Future<void> recordLocation(String city, String country) async {
    if (city.isEmpty || country.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_locationCountsKey);
    Map<String, int> counts = {};

    if (countsJson != null) {
      final decoded = jsonDecode(countsJson) as Map<String, dynamic>;
      counts = decoded.map((key, value) => MapEntry(key, value as int));
    }

    final locationKey = _normalizeLocation(city, country);
    counts[locationKey] = (counts[locationKey] ?? 0) + 1;

    await prefs.setString(_locationCountsKey, jsonEncode(counts));

    // Check if this location should be added to passport
    if (counts[locationKey]! >= _thresholdForPassport) {
      await _addToPassportLocations(city, country);
    }
  }

  /// Get all available passport locations (default + popular user-added)
  Future<List<Map<String, String>>> getPassportLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_passportLocationsKey);

    List<Map<String, String>> locations = List.from(defaultLocations);

    if (locationsJson != null) {
      final decoded = jsonDecode(locationsJson) as List;
      for (final item in decoded) {
        final location = Map<String, String>.from(item as Map);
        // Avoid duplicates
        if (!locations.any((l) =>
            l['city']?.toLowerCase() == location['city']?.toLowerCase() &&
            l['country']?.toLowerCase() ==
                location['country']?.toLowerCase())) {
          locations.add(location);
        }
      }
    }

    // Sort alphabetically by city
    locations.sort((a, b) => (a['city'] ?? '').compareTo(b['city'] ?? ''));
    return locations;
  }

  /// Get location count for analytics
  Future<int> getLocationCount(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_locationCountsKey);

    if (countsJson == null) return 0;

    final decoded = jsonDecode(countsJson) as Map<String, dynamic>;
    final locationKey = _normalizeLocation(city, country);
    return (decoded[locationKey] as int?) ?? 0;
  }

  /// Get trending locations (top 10 by count, excluding defaults)
  Future<List<Map<String, dynamic>>> getTrendingLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_locationCountsKey);

    if (countsJson == null) return [];

    final decoded = jsonDecode(countsJson) as Map<String, dynamic>;
    final entries = decoded.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return entries.take(10).map((e) {
      final parts = e.key.split('|');
      return {
        'city': parts.isNotEmpty ? parts[0] : '',
        'country': parts.length > 1 ? parts[1] : '',
        'count': e.value,
      };
    }).toList();
  }

  String _normalizeLocation(String city, String country) {
    return '${city.trim().toLowerCase()}|${country.trim().toLowerCase()}';
  }

  Future<void> _addToPassportLocations(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_passportLocationsKey);

    List<Map<String, String>> locations = [];
    if (locationsJson != null) {
      final decoded = jsonDecode(locationsJson) as List;
      locations =
          decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    }

    // Check if already exists
    final exists = locations.any((l) =>
        l['city']?.toLowerCase() == city.toLowerCase() &&
        l['country']?.toLowerCase() == country.toLowerCase());

    if (!exists) {
      locations.add({'city': city, 'country': country});
      await prefs.setString(_passportLocationsKey, jsonEncode(locations));
    }
  }

  /// Search passport locations by query
  Future<List<Map<String, String>>> searchLocations(String query) async {
    if (query.isEmpty) return getPassportLocations();

    final allLocations = await getPassportLocations();
    final lowerQuery = query.toLowerCase();

    return allLocations.where((location) {
      final city = location['city']?.toLowerCase() ?? '';
      final country = location['country']?.toLowerCase() ?? '';
      return city.contains(lowerQuery) || country.contains(lowerQuery);
    }).toList();
  }
}
