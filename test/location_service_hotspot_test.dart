import 'dart:async';

import 'package:crushhour/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = LocationService.instance;
  late GeolocatorPlatform originalGeolocatorPlatform;
  GeocodingPlatform? originalGeocodingPlatform;

  setUpAll(() async {
    originalGeolocatorPlatform = GeolocatorPlatform.instance;
    originalGeocodingPlatform = GeocodingPlatform.instance;
    await service.stopLocationStream();
  });

  setUp(() {
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
    GeocodingPlatform.instance = _FakeGeocodingPlatform();
  });

  tearDown(() async {
    await service.stopLocationStream();
  });

  tearDownAll(() async {
    await service.stopLocationStream();
    GeolocatorPlatform.instance = originalGeolocatorPlatform;
    if (originalGeocodingPlatform != null) {
      GeocodingPlatform.instance = originalGeocodingPlatform!;
    }
  });

  group('LocationService hotspot coverage', () {
    test('calculateDistanceKm returns zero for same coordinates', () {
      final distance = LocationService.calculateDistanceKm(
        37.7749,
        -122.4194,
        37.7749,
        -122.4194,
      );
      expect(distance, 0);
    });

    test(
      'calculateDistanceKm returns positive distance for different points',
      () {
        final distance = LocationService.calculateDistanceKm(
          37.7749,
          -122.4194, // San Francisco
          34.0522,
          -118.2437, // Los Angeles
        );
        expect(distance, greaterThan(500));
        expect(distance, lessThan(700));
      },
    );

    test('LocationResult toString includes key fields', () {
      final result = LocationResult(
        latitude: 10.5,
        longitude: 20.7,
        city: 'Austin',
        country: 'US',
        timestamp: DateTime(2026, 2, 13),
      );

      final text = result.toString();
      expect(text, contains('lat: 10.5'));
      expect(text, contains('lng: 20.7'));
      expect(text, contains('city: Austin'));
      expect(text, contains('country: US'));
    });

    test('isLocationAvailable respects service state and permission', () async {
      final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;

      fake.serviceEnabled = false;
      expect(await service.isLocationAvailable(), isFalse);

      fake.serviceEnabled = true;
      fake.permission = LocationPermission.denied;
      expect(await service.isLocationAvailable(), isFalse);

      fake.permission = LocationPermission.always;
      expect(await service.isLocationAvailable(), isTrue);

      fake.checkPermissionError = StateError('permission check failed');
      expect(await service.isLocationAvailable(), isFalse);
    });

    test(
      'requestPermission handles denied, granted, and deniedForever',
      () async {
        final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;

        fake.permission = LocationPermission.denied;
        fake.requestPermissionResult = LocationPermission.whileInUse;
        expect(await service.requestPermission(), isTrue);
        expect(fake.requestPermissionCalls, 1);

        fake.permission = LocationPermission.deniedForever;
        expect(await service.requestPermission(), isFalse);

        fake.permission = LocationPermission.always;
        expect(await service.requestPermission(), isTrue);
      },
    );

    test(
      'getCurrentLocation returns null when service disabled or denied',
      () async {
        final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;

        fake.serviceEnabled = false;
        expect(await service.getCurrentLocation(), isNull);

        fake.serviceEnabled = true;
        fake.permission = LocationPermission.denied;
        fake.requestPermissionResult = LocationPermission.denied;
        expect(await service.getCurrentLocation(), isNull);
      },
    );

    test('getCurrentLocation returns coordinates without geocoding', () async {
      final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      fake.permission = LocationPermission.whileInUse;
      fake.currentPosition = _position(latitude: 47.6205, longitude: -122.3493);

      final result = await service.getCurrentLocation(includeGeocoding: false);

      expect(result, isNotNull);
      expect(result!.latitude, 47.6205);
      expect(result.longitude, -122.3493);
      expect(result.city, isNull);
      expect(result.displayLocation, isNull);
      expect(fake.lastLocationSettings, isA<LocationSettings>());
    });

    test(
      'getCurrentLocation maps geocoded city/country and handles errors',
      () async {
        final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        final geocoding = GeocodingPlatform.instance as _FakeGeocodingPlatform;

        fake.permission = LocationPermission.whileInUse;
        fake.currentPosition = _position(
          latitude: 30.2672,
          longitude: -97.7431,
        );
        geocoding.placemarks = const [
          Placemark(
            locality: 'Austin',
            administrativeArea: 'Texas',
            country: 'US',
          ),
        ];

        final withPlacemark = await service.getCurrentLocation();
        expect(withPlacemark, isNotNull);
        expect(withPlacemark!.city, 'Austin');
        expect(withPlacemark.state, 'Texas');
        expect(withPlacemark.country, 'US');
        expect(withPlacemark.displayLocation, 'Austin, US');

        geocoding.placemarkError = StateError('geocode failed');
        final withoutPlacemark = await service.getCurrentLocation();
        expect(withoutPlacemark, isNotNull);
        expect(withoutPlacemark!.city, isNull);
        expect(withoutPlacemark.displayLocation, isNull);
      },
    );

    test('getCurrentLocation returns null on location exception', () async {
      final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      fake.permission = LocationPermission.whileInUse;
      fake.currentPositionError = TimeoutException('position timeout');

      expect(await service.getCurrentLocation(), isNull);
    });

    test('startLocationStream exits when permission is denied', () async {
      final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      fake.permission = LocationPermission.denied;
      fake.requestPermissionResult = LocationPermission.denied;

      service.startLocationStream();
      await Future<void>.delayed(Duration.zero);

      expect(service.isStreamActive, isFalse);
    });

    test(
      'startLocationStream emits updates and stopLocationStream cancels',
      () async {
        final fake = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        final geocoding = GeocodingPlatform.instance as _FakeGeocodingPlatform;
        final controller = StreamController<Position>();

        fake.permission = LocationPermission.whileInUse;
        fake.positionStream = controller.stream;
        geocoding.placemarks = const [
          Placemark(
            locality: 'Seattle',
            administrativeArea: 'WA',
            country: 'US',
          ),
        ];

        final nextUpdate = service.locationStream.first;
        service.startLocationStream(distanceFilter: 25);
        await Future<void>.delayed(Duration.zero);

        controller.add(_position(latitude: 47.6062, longitude: -122.3321));

        final update = await nextUpdate.timeout(const Duration(seconds: 1));
        expect(update.city, 'Seattle');
        expect(update.displayLocation, 'Seattle, US');
        expect(service.isStreamActive, isTrue);

        await service.stopLocationStream();
        expect(service.isStreamActive, isFalse);
        await controller.close();
      },
    );
  });
}

Position _position({
  required double latitude,
  required double longitude,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime(2026, 2, 13, 12),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Stream<Position> positionStream = const Stream<Position>.empty();
  Position? currentPosition;
  Object? checkPermissionError;
  Object? requestPermissionError;
  Object? currentPositionError;
  LocationSettings? lastLocationSettings;
  int requestPermissionCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    if (checkPermissionError != null) {
      throw checkPermissionError!;
    }
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    if (requestPermissionError != null) {
      throw requestPermissionError!;
    }
    permission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    lastLocationSettings = locationSettings;
    if (currentPositionError != null) {
      throw currentPositionError!;
    }
    if (currentPosition == null) {
      throw StateError('currentPosition was not configured');
    }
    return currentPosition!;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    lastLocationSettings = locationSettings;
    return positionStream;
  }
}

class _FakeGeocodingPlatform extends GeocodingPlatform {
  List<Placemark> placemarks = const [];
  Object? placemarkError;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (placemarkError != null) {
      throw placemarkError!;
    }
    return placemarks;
  }
}
