import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoverySettingsState {
  const DiscoverySettingsState({
    required this.distanceKm,
    required this.minAge,
    required this.maxAge,
    required this.interests,
    required this.showDistance,
    required this.visible,
  });

  final double distanceKm;
  final int minAge;
  final int maxAge;
  final List<String> interests;
  final bool showDistance;
  final bool visible;

  DiscoverySettingsState copyWith({
    double? distanceKm,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    bool? showDistance,
    bool? visible,
  }) {
    return DiscoverySettingsState(
      distanceKm: distanceKm ?? this.distanceKm,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      interests: interests ?? this.interests,
      showDistance: showDistance ?? this.showDistance,
      visible: visible ?? this.visible,
    );
  }
}

class DiscoverySettingsCubit extends Cubit<DiscoverySettingsState> {
  DiscoverySettingsCubit({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;

  static const _distanceKey = 'discovery_distance_km';
  static const _minAgeKey = 'discovery_min_age';
  static const _maxAgeKey = 'discovery_max_age';
  static const _interestsKey = 'discovery_interests';
  static const _showDistanceKey = 'discovery_show_distance';
  static const _visibleKey = 'discovery_visible';

  static const _defaultMinAge = 18;
  static const _defaultMaxAge = 45;
  static const _defaultDistance = 50.0;

  static DiscoverySettingsState _readInitial(SharedPreferences prefs) {
    final interestsRaw = prefs.getStringList(_interestsKey) ?? <String>[];

    final minAge = prefs.getInt(_minAgeKey) ?? _defaultMinAge;
    final maxAge = prefs.getInt(_maxAgeKey) ?? _defaultMaxAge;
    final safeMinAge = minAge.clamp(_defaultMinAge, 99);
    final safeMaxAge = maxAge.clamp(safeMinAge, 99);

    return DiscoverySettingsState(
      distanceKm: prefs.getDouble(_distanceKey) ?? _defaultDistance,
      minAge: safeMinAge,
      maxAge: safeMaxAge,
      interests: interestsRaw,
      showDistance: prefs.getBool(_showDistanceKey) ?? true,
      visible: prefs.getBool(_visibleKey) ?? true,
    );
  }

  Future<void> setDistance(double km) async {
    final safe = km.clamp(1.0, 200.0).toDouble();
    await _persist(state.copyWith(distanceKm: safe));
  }

  Future<void> setAgeRange(RangeValues range) async {
    final min = range.start.round().clamp(_defaultMinAge, 99);
    final max = range.end.round().clamp(min, 99);
    await _persist(state.copyWith(minAge: min, maxAge: max));
  }

  Future<void> setInterests(List<String> interests) async {
    final sanitized = interests.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    await _persist(state.copyWith(interests: sanitized));
  }

  Future<void> setShowDistance(bool value) async {
    await _persist(state.copyWith(showDistance: value));
  }

  Future<void> setVisible(bool value) async {
    await _persist(state.copyWith(visible: value));
  }

  Future<void> _persist(DiscoverySettingsState next) async {
    emit(next);
    await _preferences.setDouble(_distanceKey, next.distanceKm);
    await _preferences.setInt(_minAgeKey, next.minAge);
    await _preferences.setInt(_maxAgeKey, next.maxAge);
    await _preferences.setStringList(_interestsKey, next.interests);
    await _preferences.setBool(_showDistanceKey, next.showDistance);
    await _preferences.setBool(_visibleKey, next.visible);
  }
}
