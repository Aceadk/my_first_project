import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoverySettingsState extends Equatable {
  const DiscoverySettingsState({
    required this.distanceKm,
    required this.minAge,
    required this.maxAge,
    required this.interests,
    required this.showDistance,
    required this.visible,
    this.passportModeEnabled = false,
    this.passportLocation,
    this.passportLatitude,
    this.passportLongitude,
    // Advanced filters (Plus features)
    this.minHeightCm,
    this.maxHeightCm,
    this.educationLevels = const [],
    this.relationshipGoals = const [],
    this.verifiedOnly = false,
    this.languageFilters = const [],
    this.smokingFilter,
    this.drinkingFilter,
    this.exerciseFilter,
    this.petsFilter,
    this.familyPlansFilter,
    this.zodiacFilter,
    this.religionFilter,
  });

  final double distanceKm;
  final int minAge;
  final int maxAge;
  final List<String> interests;
  final bool showDistance;
  final bool visible;

  /// Whether Passport mode is enabled (Plus feature).
  final bool passportModeEnabled;

  /// Display name of the passport location (e.g., "Paris, France").
  final String? passportLocation;

  /// Passport mode location latitude.
  final double? passportLatitude;

  /// Passport mode location longitude.
  final double? passportLongitude;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADVANCED FILTERS (Plus features)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum height filter in cm. Null means no minimum.
  final int? minHeightCm;

  /// Maximum height filter in cm. Null means no maximum.
  final int? maxHeightCm;

  /// Education level filters (e.g., ['bachelors', 'masters', 'phd']).
  final List<String> educationLevels;

  /// Relationship goal filters (e.g., ['serious', 'casual']).
  final List<String> relationshipGoals;

  /// Only show verified profiles.
  final bool verifiedOnly;

  /// Language filters for multilingual matching.
  final List<String> languageFilters;

  /// Smoking preference filter.
  final String? smokingFilter;

  /// Drinking preference filter.
  final String? drinkingFilter;

  /// Exercise preference filter.
  final String? exerciseFilter;

  /// Pets preference filter.
  final String? petsFilter;

  /// Family plans preference filter.
  final String? familyPlansFilter;

  /// Zodiac sign filter.
  final String? zodiacFilter;

  /// Religion filter.
  final String? religionFilter;

  /// Whether any advanced filters are active.
  bool get hasActiveAdvancedFilters =>
      minHeightCm != null ||
      maxHeightCm != null ||
      educationLevels.isNotEmpty ||
      relationshipGoals.isNotEmpty ||
      verifiedOnly ||
      languageFilters.isNotEmpty ||
      smokingFilter != null ||
      drinkingFilter != null ||
      exerciseFilter != null ||
      petsFilter != null ||
      familyPlansFilter != null ||
      zodiacFilter != null ||
      religionFilter != null;

  /// Count of active advanced filters.
  int get activeAdvancedFilterCount {
    int count = 0;
    if (minHeightCm != null || maxHeightCm != null) count++;
    if (educationLevels.isNotEmpty) count++;
    if (relationshipGoals.isNotEmpty) count++;
    if (verifiedOnly) count++;
    if (languageFilters.isNotEmpty) count++;
    if (smokingFilter != null) count++;
    if (drinkingFilter != null) count++;
    if (exerciseFilter != null) count++;
    if (petsFilter != null) count++;
    if (familyPlansFilter != null) count++;
    if (zodiacFilter != null) count++;
    if (religionFilter != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        distanceKm,
        minAge,
        maxAge,
        interests,
        showDistance,
        visible,
        passportModeEnabled,
        passportLocation,
        passportLatitude,
        passportLongitude,
        minHeightCm,
        maxHeightCm,
        educationLevels,
        relationshipGoals,
        verifiedOnly,
        languageFilters,
        smokingFilter,
        drinkingFilter,
        exerciseFilter,
        petsFilter,
        familyPlansFilter,
        zodiacFilter,
        religionFilter,
      ];

  DiscoverySettingsState copyWith({
    double? distanceKm,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    bool? showDistance,
    bool? visible,
    bool? passportModeEnabled,
    String? passportLocation,
    double? passportLatitude,
    double? passportLongitude,
    int? minHeightCm,
    int? maxHeightCm,
    List<String>? educationLevels,
    List<String>? relationshipGoals,
    bool? verifiedOnly,
    List<String>? languageFilters,
    String? smokingFilter,
    String? drinkingFilter,
    String? exerciseFilter,
    String? petsFilter,
    String? familyPlansFilter,
    String? zodiacFilter,
    String? religionFilter,
    bool clearMinHeight = false,
    bool clearMaxHeight = false,
    bool clearSmokingFilter = false,
    bool clearDrinkingFilter = false,
    bool clearExerciseFilter = false,
    bool clearPetsFilter = false,
    bool clearFamilyPlansFilter = false,
    bool clearZodiacFilter = false,
    bool clearReligionFilter = false,
  }) {
    return DiscoverySettingsState(
      distanceKm: distanceKm ?? this.distanceKm,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      interests: interests ?? this.interests,
      showDistance: showDistance ?? this.showDistance,
      visible: visible ?? this.visible,
      passportModeEnabled: passportModeEnabled ?? this.passportModeEnabled,
      passportLocation: passportLocation ?? this.passportLocation,
      passportLatitude: passportLatitude ?? this.passportLatitude,
      passportLongitude: passportLongitude ?? this.passportLongitude,
      minHeightCm: clearMinHeight ? null : (minHeightCm ?? this.minHeightCm),
      maxHeightCm: clearMaxHeight ? null : (maxHeightCm ?? this.maxHeightCm),
      educationLevels: educationLevels ?? this.educationLevels,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      languageFilters: languageFilters ?? this.languageFilters,
      smokingFilter: clearSmokingFilter ? null : (smokingFilter ?? this.smokingFilter),
      drinkingFilter: clearDrinkingFilter ? null : (drinkingFilter ?? this.drinkingFilter),
      exerciseFilter: clearExerciseFilter ? null : (exerciseFilter ?? this.exerciseFilter),
      petsFilter: clearPetsFilter ? null : (petsFilter ?? this.petsFilter),
      familyPlansFilter: clearFamilyPlansFilter ? null : (familyPlansFilter ?? this.familyPlansFilter),
      zodiacFilter: clearZodiacFilter ? null : (zodiacFilter ?? this.zodiacFilter),
      religionFilter: clearReligionFilter ? null : (religionFilter ?? this.religionFilter),
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
  static const _passportEnabledKey = 'discovery_passport_enabled';
  static const _passportLocationKey = 'discovery_passport_location';
  static const _passportLatKey = 'discovery_passport_lat';
  static const _passportLngKey = 'discovery_passport_lng';

  // Advanced filter keys
  static const _minHeightKey = 'discovery_min_height_cm';
  static const _maxHeightKey = 'discovery_max_height_cm';
  static const _educationLevelsKey = 'discovery_education_levels';
  static const _relationshipGoalsKey = 'discovery_relationship_goals';
  static const _verifiedOnlyKey = 'discovery_verified_only';
  static const _languageFiltersKey = 'discovery_language_filters';
  static const _smokingFilterKey = 'discovery_smoking_filter';
  static const _drinkingFilterKey = 'discovery_drinking_filter';
  static const _exerciseFilterKey = 'discovery_exercise_filter';
  static const _petsFilterKey = 'discovery_pets_filter';
  static const _familyPlansFilterKey = 'discovery_family_plans_filter';
  static const _zodiacFilterKey = 'discovery_zodiac_filter';
  static const _religionFilterKey = 'discovery_religion_filter';

  static const _defaultMinAge = 18;
  static const _defaultMaxAge = 45;
  static const _absoluteMaxAge = 75;
  static const _defaultDistance = 50.0;

  static DiscoverySettingsState _readInitial(SharedPreferences prefs) {
    final interestsRaw = prefs.getStringList(_interestsKey) ?? <String>[];

    final minAge = prefs.getInt(_minAgeKey) ?? _defaultMinAge;
    final maxAge = prefs.getInt(_maxAgeKey) ?? _defaultMaxAge;
    final safeMinAge = minAge.clamp(_defaultMinAge, _absoluteMaxAge);
    final safeMaxAge = maxAge.clamp(safeMinAge, _absoluteMaxAge);

    return DiscoverySettingsState(
      distanceKm: prefs.getDouble(_distanceKey) ?? _defaultDistance,
      minAge: safeMinAge,
      maxAge: safeMaxAge,
      interests: interestsRaw,
      showDistance: prefs.getBool(_showDistanceKey) ?? true,
      visible: prefs.getBool(_visibleKey) ?? true,
      passportModeEnabled: prefs.getBool(_passportEnabledKey) ?? false,
      passportLocation: prefs.getString(_passportLocationKey),
      passportLatitude: prefs.getDouble(_passportLatKey),
      passportLongitude: prefs.getDouble(_passportLngKey),
      // Advanced filters
      minHeightCm: prefs.getInt(_minHeightKey),
      maxHeightCm: prefs.getInt(_maxHeightKey),
      educationLevels: prefs.getStringList(_educationLevelsKey) ?? [],
      relationshipGoals: prefs.getStringList(_relationshipGoalsKey) ?? [],
      verifiedOnly: prefs.getBool(_verifiedOnlyKey) ?? false,
      languageFilters: prefs.getStringList(_languageFiltersKey) ?? [],
      smokingFilter: prefs.getString(_smokingFilterKey),
      drinkingFilter: prefs.getString(_drinkingFilterKey),
      exerciseFilter: prefs.getString(_exerciseFilterKey),
      petsFilter: prefs.getString(_petsFilterKey),
      familyPlansFilter: prefs.getString(_familyPlansFilterKey),
      zodiacFilter: prefs.getString(_zodiacFilterKey),
      religionFilter: prefs.getString(_religionFilterKey),
    );
  }

  Future<void> setDistance(double km) async {
    final safe = km.clamp(1.0, 200.0).toDouble();
    await _persist(state.copyWith(distanceKm: safe));
  }

  Future<void> setAgeRange(RangeValues range) async {
    final min = range.start.round().clamp(_defaultMinAge, _absoluteMaxAge);
    final max = range.end.round().clamp(min, _absoluteMaxAge);
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

  /// Enable or disable Passport mode.
  Future<void> setPassportMode(bool enabled) async {
    await _persist(state.copyWith(passportModeEnabled: enabled));
  }

  /// Set passport location with coordinates.
  Future<void> setPassportLocation({
    required String locationName,
    required double latitude,
    required double longitude,
  }) async {
    await _persist(state.copyWith(
      passportLocation: locationName,
      passportLatitude: latitude,
      passportLongitude: longitude,
    ));
  }

  /// Clear passport location (return to current location).
  Future<void> clearPassportLocation() async {
    emit(state.copyWith(
      passportModeEnabled: false,
    ));
    await _preferences.setBool(_passportEnabledKey, false);
    await _preferences.remove(_passportLocationKey);
    await _preferences.remove(_passportLatKey);
    await _preferences.remove(_passportLngKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADVANCED FILTER SETTERS (Plus features)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set height range filter.
  Future<void> setHeightRange({int? minCm, int? maxCm}) async {
    final safeMin = minCm?.clamp(120, 220);
    final safeMax = maxCm?.clamp(safeMin ?? 120, 220);
    await _persist(state.copyWith(
      minHeightCm: safeMin,
      maxHeightCm: safeMax,
      clearMinHeight: minCm == null,
      clearMaxHeight: maxCm == null,
    ));
  }

  /// Clear height filter.
  Future<void> clearHeightFilter() async {
    await _persist(state.copyWith(
      clearMinHeight: true,
      clearMaxHeight: true,
    ));
    await _preferences.remove(_minHeightKey);
    await _preferences.remove(_maxHeightKey);
  }

  /// Set education level filters.
  Future<void> setEducationLevels(List<String> levels) async {
    await _persist(state.copyWith(educationLevels: levels));
  }

  /// Set relationship goal filters.
  Future<void> setRelationshipGoals(List<String> goals) async {
    await _persist(state.copyWith(relationshipGoals: goals));
  }

  /// Set verified only filter.
  Future<void> setVerifiedOnly(bool value) async {
    await _persist(state.copyWith(verifiedOnly: value));
  }

  /// Set language filters.
  Future<void> setLanguageFilters(List<String> languages) async {
    await _persist(state.copyWith(languageFilters: languages));
  }

  /// Set smoking preference filter.
  Future<void> setSmokingFilter(String? value) async {
    await _persist(state.copyWith(
      smokingFilter: value,
      clearSmokingFilter: value == null,
    ));
  }

  /// Set drinking preference filter.
  Future<void> setDrinkingFilter(String? value) async {
    await _persist(state.copyWith(
      drinkingFilter: value,
      clearDrinkingFilter: value == null,
    ));
  }

  /// Set exercise preference filter.
  Future<void> setExerciseFilter(String? value) async {
    await _persist(state.copyWith(
      exerciseFilter: value,
      clearExerciseFilter: value == null,
    ));
  }

  /// Set pets preference filter.
  Future<void> setPetsFilter(String? value) async {
    await _persist(state.copyWith(
      petsFilter: value,
      clearPetsFilter: value == null,
    ));
  }

  /// Set family plans filter.
  Future<void> setFamilyPlansFilter(String? value) async {
    await _persist(state.copyWith(
      familyPlansFilter: value,
      clearFamilyPlansFilter: value == null,
    ));
  }

  /// Set zodiac sign filter.
  Future<void> setZodiacFilter(String? value) async {
    await _persist(state.copyWith(
      zodiacFilter: value,
      clearZodiacFilter: value == null,
    ));
  }

  /// Set religion filter.
  Future<void> setReligionFilter(String? value) async {
    await _persist(state.copyWith(
      religionFilter: value,
      clearReligionFilter: value == null,
    ));
  }

  /// Clear all advanced filters.
  Future<void> clearAllAdvancedFilters() async {
    await _persist(state.copyWith(
      clearMinHeight: true,
      clearMaxHeight: true,
      educationLevels: [],
      relationshipGoals: [],
      verifiedOnly: false,
      languageFilters: [],
      clearSmokingFilter: true,
      clearDrinkingFilter: true,
      clearExerciseFilter: true,
      clearPetsFilter: true,
      clearFamilyPlansFilter: true,
      clearZodiacFilter: true,
      clearReligionFilter: true,
    ));
    // Clear from prefs
    await _preferences.remove(_minHeightKey);
    await _preferences.remove(_maxHeightKey);
    await _preferences.remove(_smokingFilterKey);
    await _preferences.remove(_drinkingFilterKey);
    await _preferences.remove(_exerciseFilterKey);
    await _preferences.remove(_petsFilterKey);
    await _preferences.remove(_familyPlansFilterKey);
    await _preferences.remove(_zodiacFilterKey);
    await _preferences.remove(_religionFilterKey);
  }

  Future<void> _persist(DiscoverySettingsState next) async {
    emit(next);
    await _preferences.setDouble(_distanceKey, next.distanceKm);
    await _preferences.setInt(_minAgeKey, next.minAge);
    await _preferences.setInt(_maxAgeKey, next.maxAge);
    await _preferences.setStringList(_interestsKey, next.interests);
    await _preferences.setBool(_showDistanceKey, next.showDistance);
    await _preferences.setBool(_visibleKey, next.visible);
    await _preferences.setBool(_passportEnabledKey, next.passportModeEnabled);
    if (next.passportLocation != null) {
      await _preferences.setString(_passportLocationKey, next.passportLocation!);
    }
    if (next.passportLatitude != null) {
      await _preferences.setDouble(_passportLatKey, next.passportLatitude!);
    }
    if (next.passportLongitude != null) {
      await _preferences.setDouble(_passportLngKey, next.passportLongitude!);
    }
    // Advanced filters
    if (next.minHeightCm != null) {
      await _preferences.setInt(_minHeightKey, next.minHeightCm!);
    }
    if (next.maxHeightCm != null) {
      await _preferences.setInt(_maxHeightKey, next.maxHeightCm!);
    }
    await _preferences.setStringList(_educationLevelsKey, next.educationLevels);
    await _preferences.setStringList(_relationshipGoalsKey, next.relationshipGoals);
    await _preferences.setBool(_verifiedOnlyKey, next.verifiedOnly);
    await _preferences.setStringList(_languageFiltersKey, next.languageFilters);
    if (next.smokingFilter != null) {
      await _preferences.setString(_smokingFilterKey, next.smokingFilter!);
    }
    if (next.drinkingFilter != null) {
      await _preferences.setString(_drinkingFilterKey, next.drinkingFilter!);
    }
    if (next.exerciseFilter != null) {
      await _preferences.setString(_exerciseFilterKey, next.exerciseFilter!);
    }
    if (next.petsFilter != null) {
      await _preferences.setString(_petsFilterKey, next.petsFilter!);
    }
    if (next.familyPlansFilter != null) {
      await _preferences.setString(_familyPlansFilterKey, next.familyPlansFilter!);
    }
    if (next.zodiacFilter != null) {
      await _preferences.setString(_zodiacFilterKey, next.zodiacFilter!);
    }
    if (next.religionFilter != null) {
      await _preferences.setString(_religionFilterKey, next.religionFilter!);
    }
  }
}
