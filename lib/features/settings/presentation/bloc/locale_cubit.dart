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
  });

  final String languageCode;
  final String region;
  final bool isDetecting;
  final String? errorMessage;

  LocaleState copyWith({
    String? languageCode,
    String? region,
    bool? isDetecting,
    String? errorMessage,
  }) {
    return LocaleState(
      languageCode: languageCode ?? this.languageCode,
      region: region ?? this.region,
      isDetecting: isDetecting ?? this.isDetecting,
      errorMessage: errorMessage,
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

  static LocaleState _readInitial(SharedPreferences prefs) {
    return LocaleState(
      languageCode: prefs.getString(_languageKey) ?? 'en',
      region: prefs.getString(_regionKey) ?? 'United States',
      isDetecting: false,
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
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        emit(state.copyWith(
          isDetecting: false,
          errorMessage: 'Turn on location services to detect your region.',
        ));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isDetecting: false,
          errorMessage: 'Location permission denied.',
        ));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final components = <String>[
        if (place?.locality != null && place!.locality!.isNotEmpty)
          place.locality!,
        if (place?.administrativeArea != null &&
            place!.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
        if (place?.country != null && place!.country!.isNotEmpty)
          place.country!,
      ];
      final resolvedRegion = components.isNotEmpty
          ? components.join(', ')
          : 'Lat ${position.latitude.toStringAsFixed(3)}, '
              'Lng ${position.longitude.toStringAsFixed(3)}';

      await _persist(
        state.copyWith(
          region: resolvedRegion,
          isDetecting: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        isDetecting: false,
        errorMessage: 'Could not detect location. Please try again.',
      ));
    }
  }

  Future<void> _persist(LocaleState next) async {
    emit(next);
    await _preferences.setString(_languageKey, next.languageCode);
    await _preferences.setString(_regionKey, next.region);
  }
}
