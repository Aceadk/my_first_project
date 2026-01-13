import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result of a location fetch operation.
class LocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? displayLocation;
  final DateTime timestamp;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.displayLocation,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LocationResult(lat: $latitude, lng: $longitude, city: $city, country: $country)';
  }
}

/// Service for handling location operations including real-time tracking.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<LocationResult>.broadcast();

  /// Stream of location updates for real-time tracking.
  Stream<LocationResult> get locationStream => _locationController.stream;

  /// Check if location services are available and permissions granted.
  Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      developer.log('LocationService: Error checking availability: $e');
      return false;
    }
  }

  /// Request location permission if not already granted.
  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('LocationService: Permission denied forever');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      developer.log('LocationService: Error requesting permission: $e');
      return false;
    }
  }

  /// Get current location once.
  Future<LocationResult?> getCurrentLocation({
    bool includeGeocoding = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      developer.log('LocationService: Getting current location...');

      // Check services and permissions
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('LocationService: Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('LocationService: Permission denied: $permission');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      ).timeout(timeout);

      developer.log(
          'LocationService: Got position: ${position.latitude}, ${position.longitude}');

      // Reverse geocode if requested
      String? city, state, country, displayLocation;
      if (includeGeocoding) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 10));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            city = place.locality;
            state = place.administrativeArea;
            country = place.country;

            final components = <String>[
              if (city != null && city.isNotEmpty) city,
              if (country != null && country.isNotEmpty) country,
            ];
            displayLocation =
                components.isNotEmpty ? components.join(', ') : null;
          }
        } catch (geocodeError) {
          developer.log('LocationService: Geocoding error: $geocodeError');
        }
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
        country: country,
        displayLocation: displayLocation,
        timestamp: position.timestamp,
      );
    } catch (e) {
      developer.log('LocationService: Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking.
  ///
  /// [distanceFilter] - Minimum distance (in meters) before an update is triggered.
  /// [intervalDuration] - Minimum time between updates (Android only).
  void startLocationStream({
    int distanceFilter = 100, // meters
    Duration intervalDuration = const Duration(minutes: 5),
  }) async {
    developer.log('LocationService: Starting location stream...');

    // Check permissions first
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      developer.log('LocationService: No permission for location stream');
      return;
    }

    // Cancel existing stream if any
    await stopLocationStream();

    // Configure location settings
    late LocationSettings locationSettings;

    // Platform-specific settings
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      intervalDuration: intervalDuration,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText:
            'CrushHour is updating your location to show you nearby matches',
        notificationTitle: 'Location Active',
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        developer.log(
            'LocationService: Stream update: ${position.latitude}, ${position.longitude}');

        // Reverse geocode for each update
        String? city, state, country, displayLocation;
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            city = place.locality;
            state = place.administrativeArea;
            country = place.country;

            final components = <String>[
              if (city != null && city.isNotEmpty) city,
              if (country != null && country.isNotEmpty) country,
            ];
            displayLocation =
                components.isNotEmpty ? components.join(', ') : null;
          }
        } catch (e) {
          developer.log('LocationService: Geocoding error in stream: $e');
        }

        final result = LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          city: city,
          state: state,
          country: country,
          displayLocation: displayLocation,
          timestamp: position.timestamp,
        );

        _locationController.add(result);
      },
      onError: (error) {
        developer.log('LocationService: Stream error: $error');
      },
    );

    developer.log('LocationService: Location stream started');
  }

  /// Stop continuous location tracking.
  Future<void> stopLocationStream() async {
    await _positionStream?.cancel();
    _positionStream = null;
    developer.log('LocationService: Location stream stopped');
  }

  /// Check if location stream is active.
  bool get isStreamActive => _positionStream != null;

  /// Calculate distance between two coordinates in kilometers.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Dispose the service and clean up resources.
  void dispose() {
    stopLocationStream();
    _locationController.close();
  }
}
