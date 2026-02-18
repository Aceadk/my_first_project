import 'dart:async';

import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeolocatorPlatform originalGeolocatorPlatform;
  GeocodingPlatform? originalGeocodingPlatform;

  setUpAll(() {
    originalGeolocatorPlatform = GeolocatorPlatform.instance;
    originalGeocodingPlatform = GeocodingPlatform.instance;
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocatorPlatform;
    if (originalGeocodingPlatform != null) {
      GeocodingPlatform.instance = originalGeocodingPlatform!;
    }
  });

  group('LocaleCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
      GeocodingPlatform.instance = _FakeGeocodingPlatform();
    });

    test('loads defaults when no prefs stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);

      expect(cubit.state.languageCode, 'en');
      expect(cubit.state.region, 'United States');
      expect(cubit.state.isDetecting, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('persists language and region updates', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);

      await cubit.setLanguage('es');
      await cubit.setRegion('Madrid, Spain');

      expect(cubit.state.languageCode, 'es');
      expect(cubit.state.region, 'Madrid, Spain');
      expect(prefs.getString('locale_language'), 'es');
      expect(prefs.getString('locale_region'), 'Madrid, Spain');
    });

    test(
      'detectFromLocation emits guidance when location service is disabled',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        geolocator.serviceEnabled = false;

        await cubit.detectFromLocation();

        expect(cubit.state.isDetecting, isFalse);
        expect(
          cubit.state.errorMessage,
          'Turn on location services in your device settings.',
        );
      },
    );

    test(
      'detectFromLocation requests permission and handles denied response',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        geolocator.permission = LocationPermission.denied;
        geolocator.requestPermissionResult = LocationPermission.denied;

        await cubit.detectFromLocation();

        expect(geolocator.requestPermissionCalls, 1);
        expect(cubit.state.isDetecting, isFalse);
        expect(
          cubit.state.errorMessage,
          'Location permission denied. Please allow location access in Settings.',
        );
      },
    );

    test('detectFromLocation handles denied forever permission', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);
      final geolocator = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      geolocator.permission = LocationPermission.deniedForever;

      await cubit.detectFromLocation();

      expect(cubit.state.isDetecting, isFalse);
      expect(
        cubit.state.errorMessage,
        'Location permission permanently denied. Please enable it in Settings > Privacy > Location Services.',
      );
    });

    test(
      'detectFromLocation resolves placemark and persists coordinates',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        final geocoding = GeocodingPlatform.instance as _FakeGeocodingPlatform;
        geolocator.currentPosition = _position(30.2672, -97.7431);
        geocoding.placemarks = const [
          Placemark(
            locality: 'Austin',
            administrativeArea: 'Texas',
            country: 'US',
          ),
        ];

        await cubit.detectFromLocation();

        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.isDetecting, isFalse);
        expect(cubit.state.region, 'Austin, Texas, US');
        expect(cubit.state.latitude, 30.2672);
        expect(cubit.state.longitude, -97.7431);
        expect(prefs.getDouble('locale_latitude'), 30.2672);
        expect(prefs.getDouble('locale_longitude'), -97.7431);
        expect(prefs.getString('locale_region'), 'Austin, Texas, US');
      },
    );

    test(
      'detectFromLocation falls back to coordinates on geocoding failure',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        final geocoding = GeocodingPlatform.instance as _FakeGeocodingPlatform;
        geolocator.currentPosition = _position(10.1234, 20.9876);
        geocoding.placemarkError = StateError('geocode failed');

        await cubit.detectFromLocation();

        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.region, 'Lat 10.123, Lng 20.988');
        expect(prefs.getString('locale_region'), 'Lat 10.123, Lng 20.988');
      },
    );

    test(
      'detectFromLocation falls back to coordinates when placemark has no components',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        final geocoding = GeocodingPlatform.instance as _FakeGeocodingPlatform;
        geolocator.currentPosition = _position(51.5074, -0.1278);
        geocoding.placemarks = const [Placemark()];

        await cubit.detectFromLocation();

        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.region, 'Lat 51.507, Lng -0.128');
      },
    );

    test('detectFromLocation handles timeout exceptions', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);
      final geolocator = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      geolocator.currentPositionError = TimeoutException('request timeout');

      await cubit.detectFromLocation();

      expect(cubit.state.isDetecting, isFalse);
      expect(
        cubit.state.errorMessage,
        'Location request timed out. Make sure you have GPS signal and try again.',
      );
    });

    test(
      'detectFromLocation handles location service disabled exceptions from geolocator',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        geolocator.currentPositionError =
            const LocationServiceDisabledException();

        await cubit.detectFromLocation();

        expect(
          cubit.state.errorMessage,
          'Location services are disabled. Please enable them in Settings.',
        );
      },
    );

    test('detectFromLocation handles permission denied exceptions', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);
      final geolocator = GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
      geolocator.currentPositionError = const PermissionDeniedException(
        'denied by user',
      );

      await cubit.detectFromLocation();

      expect(
        cubit.state.errorMessage,
        'Location permission was denied. Please allow location access.',
      );
    });

    test(
      'detectFromLocation maps generic network errors to network message',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        geolocator.checkPermissionError = StateError('network unavailable');

        await cubit.detectFromLocation();

        expect(
          cubit.state.errorMessage,
          'Network error. Check your internet connection and try again.',
        );
      },
    );

    test(
      'detectFromLocation maps generic timeout text to timeout message',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: prefs);
        final geolocator =
            GeolocatorPlatform.instance as _FakeGeolocatorPlatform;
        geolocator.checkPermissionError = StateError(
          'timeout while requesting',
        );

        await cubit.detectFromLocation();

        expect(
          cubit.state.errorMessage,
          'Request timed out. Try moving to an area with better GPS signal.',
        );
      },
    );
  });
}

Position _position(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 2, 17, 12),
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
  Object? checkPermissionError;
  Object? currentPositionError;
  Position currentPosition = _position(37.7749, -122.4194);
  int requestPermissionCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

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
    permission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (currentPositionError != null) {
      throw currentPositionError!;
    }
    return currentPosition;
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
