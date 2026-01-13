import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState {
  const LocaleState({
    required this.languageCode,
    required this.region,
    required this.isDetecting,
    this.errorMessage,
    this.latitude,
    this.longitude,
  });

  final String languageCode;
  final String region;
  final bool isDetecting;
  final String? errorMessage;
  final double? latitude;
  final double? longitude;

  LocaleState copyWith({
    String? languageCode,
    String? region,
    bool? isDetecting,
    String? errorMessage,
    double? latitude,
    double? longitude,
  }) {
    return LocaleState(
      languageCode: languageCode ?? this.languageCode,
      region: region ?? this.region,
      isDetecting: isDetecting ?? this.isDetecting,
      errorMessage: errorMessage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;

  static const _languageKey = 'locale_language';
  static const _regionKey = 'locale_region';
  static const _latitudeKey = 'locale_latitude';
  static const _longitudeKey = 'locale_longitude';

  static LocaleState _readInitial(SharedPreferences prefs) {
    return LocaleState(
      languageCode: prefs.getString(_languageKey) ?? 'en',
      region: prefs.getString(_regionKey) ?? 'United States',
      isDetecting: false,
      latitude: prefs.getDouble(_latitudeKey),
      longitude: prefs.getDouble(_longitudeKey),
    );
  }

  Future<void> setLanguage(String code) async {
    await _persist(state.copyWith(languageCode: code, errorMessage: null));
  }

  Future<void> setRegion(String region) async {
    await _persist(state.copyWith(region: region, errorMessage: null));
  }

  Future<void> detectFromLocation() async {
    emit(state.copyWith(isDetecting: true, errorMessage: null));
    try {
      developer.log('LocaleCubit: Starting location detection...');

      // Check if location services are enabled
      final enabled = await Geolocator.isLocationServiceEnabled();
      developer.log('LocaleCubit: Location services enabled: $enabled');
      if (!enabled) {
        emit(state.copyWith(
          isDetecting: false,
          errorMessage: 'Turn on location services in your device settings.',
        ));
        return;
      }

      // Check and request permission
      var permission = await Geolocator.checkPermission();
      developer.log('LocaleCubit: Current permission: $permission');

      if (permission == LocationPermission.denied) {
        developer.log('LocaleCubit: Requesting permission...');
        permission = await Geolocator.requestPermission();
        developer.log('LocaleCubit: Permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          isDetecting: false,
          errorMessage: 'Location permission denied. Please allow location access in Settings.',
        ));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isDetecting: false,
          errorMessage: 'Location permission permanently denied. Please enable it in Settings > Privacy > Location Services.',
        ));
        return;
      }

      developer.log('LocaleCubit: Getting current position...');

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      developer.log('LocaleCubit: Got position: ${position.latitude}, ${position.longitude}');

      // Try to get placemark (reverse geocoding)
      String resolvedRegion;
      try {
        developer.log('LocaleCubit: Reverse geocoding...');
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        final place = placemarks.isNotEmpty ? placemarks.first : null;
        developer.log('LocaleCubit: Placemark: ${place?.locality}, ${place?.administrativeArea}, ${place?.country}');

        final components = <String>[
          if (place?.locality != null && place!.locality!.isNotEmpty)
            place.locality!,
          if (place?.administrativeArea != null &&
              place!.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
          if (place?.country != null && place!.country!.isNotEmpty)
            place.country!,
        ];
        resolvedRegion = components.isNotEmpty
            ? components.join(', ')
            : 'Lat ${position.latitude.toStringAsFixed(3)}, Lng ${position.longitude.toStringAsFixed(3)}';
      } catch (geocodeError) {
        developer.log('LocaleCubit: Geocoding error: $geocodeError');
        // If geocoding fails, use coordinates as fallback
        resolvedRegion = 'Lat ${position.latitude.toStringAsFixed(3)}, Lng ${position.longitude.toStringAsFixed(3)}';
      }

      developer.log('LocaleCubit: Resolved region: $resolvedRegion');

      await _persist(
        state.copyWith(
          region: resolvedRegion,
          latitude: position.latitude,
          longitude: position.longitude,
          isDetecting: false,
          errorMessage: null,
        ),
      );
    } on TimeoutException catch (e) {
      developer.log('LocaleCubit: Timeout error: $e');
      emit(state.copyWith(
        isDetecting: false,
        errorMessage: 'Location request timed out. Make sure you have GPS signal and try again.',
      ));
    } on LocationServiceDisabledException catch (e) {
      developer.log('LocaleCubit: Location service disabled: $e');
      emit(state.copyWith(
        isDetecting: false,
        errorMessage: 'Location services are disabled. Please enable them in Settings.',
      ));
    } on PermissionDeniedException catch (e) {
      developer.log('LocaleCubit: Permission denied: $e');
      emit(state.copyWith(
        isDetecting: false,
        errorMessage: 'Location permission was denied. Please allow location access.',
      ));
    } catch (e, stackTrace) {
      developer.log('LocaleCubit: Unexpected error: $e\n$stackTrace');
      String errorMessage = 'Could not detect location.';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Try moving to an area with better GPS signal.';
      }
      emit(state.copyWith(
        isDetecting: false,
        errorMessage: errorMessage,
      ));
    }
  }

  Future<void> _persist(LocaleState next) async {
    emit(next);
    await _preferences.setString(_languageKey, next.languageCode);
    await _preferences.setString(_regionKey, next.region);
    if (next.latitude != null) {
      await _preferences.setDouble(_latitudeKey, next.latitude!);
    }
    if (next.longitude != null) {
      await _preferences.setDouble(_longitudeKey, next.longitude!);
    }
  }
}
