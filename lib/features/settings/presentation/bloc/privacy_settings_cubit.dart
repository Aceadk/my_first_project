import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';

class PrivacySettingsCubit extends Cubit<ProfilePrivacySettings> {
  PrivacySettingsCubit({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;
  static const _storageKey = 'privacy_settings';

  static ProfilePrivacySettings _readInitial(SharedPreferences preferences) {
    final json = preferences.getString(_storageKey);
    if (json == null) return const ProfilePrivacySettings();
    try {
      return ProfilePrivacySettings.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('PrivacySettingsCubit: Error parsing saved settings, using defaults: $e');
      return const ProfilePrivacySettings();
    }
  }

  // Name visibility toggles
  Future<void> toggleShowFirstName(bool value) =>
      _update(state.copyWith(showFirstName: value));

  Future<void> toggleShowLastName(bool value) =>
      _update(state.copyWith(showLastName: value));

  // Sensitive info toggles
  Future<void> toggleShowAge(bool value) =>
      _update(state.copyWith(showAge: value));

  Future<void> toggleShowDateOfBirth(bool value) =>
      _update(state.copyWith(showDateOfBirth: value));

  Future<void> toggleShowEmail(bool value) =>
      _update(state.copyWith(showEmail: value));

  Future<void> toggleShowPhoneNumber(bool value) =>
      _update(state.copyWith(showPhoneNumber: value));

  Future<void> toggleShowExactLocation(bool value) =>
      _update(state.copyWith(showExactLocation: value));

  // Personal details toggles
  Future<void> toggleShowHeight(bool value) =>
      _update(state.copyWith(showHeight: value));

  Future<void> toggleShowZodiacSign(bool value) =>
      _update(state.copyWith(showZodiacSign: value));

  Future<void> toggleShowEducation(bool value) =>
      _update(state.copyWith(showEducation: value));

  Future<void> toggleShowFamilyPlans(bool value) =>
      _update(state.copyWith(showFamilyPlans: value));

  Future<void> toggleShowPersonality(bool value) =>
      _update(state.copyWith(showPersonality: value));

  Future<void> toggleShowRelationshipGoals(bool value) =>
      _update(state.copyWith(showRelationshipGoals: value));

  // Lifestyle toggles
  Future<void> toggleShowWorkout(bool value) =>
      _update(state.copyWith(showWorkout: value));

  Future<void> toggleShowSmoking(bool value) =>
      _update(state.copyWith(showSmoking: value));

  Future<void> toggleShowDrinking(bool value) =>
      _update(state.copyWith(showDrinking: value));

  Future<void> toggleShowDiet(bool value) =>
      _update(state.copyWith(showDiet: value));

  Future<void> toggleShowSleepingHabits(bool value) =>
      _update(state.copyWith(showSleepingHabits: value));

  Future<void> toggleShowPets(bool value) =>
      _update(state.copyWith(showPets: value));

  // Work toggles
  Future<void> toggleShowJobTitle(bool value) =>
      _update(state.copyWith(showJobTitle: value));

  Future<void> toggleShowCompany(bool value) =>
      _update(state.copyWith(showCompany: value));

  Future<void> toggleShowSchool(bool value) =>
      _update(state.copyWith(showSchool: value));

  // Music toggles
  Future<void> toggleShowFavoriteSongs(bool value) =>
      _update(state.copyWith(showFavoriteSongs: value));

  Future<void> toggleShowFavoriteSinger(bool value) =>
      _update(state.copyWith(showFavoriteSinger: value));

  // Social toggles
  Future<void> toggleShowSocialMedia(bool value) =>
      _update(state.copyWith(showSocialMedia: value));

  Future<void> toggleShowLanguages(bool value) =>
      _update(state.copyWith(showLanguages: value));

  // Online status toggles
  Future<void> toggleShowOnlineStatus(bool value) =>
      _update(state.copyWith(showOnlineStatus: value));

  Future<void> toggleShowLastActive(bool value) =>
      _update(state.copyWith(showLastActive: value));

  // Bulk actions
  Future<void> setAllPublic() => _update(ProfilePrivacySettings.allPublic());

  Future<void> setAllPrivate() => _update(ProfilePrivacySettings.allPrivate());

  Future<void> resetToDefaults() => _update(const ProfilePrivacySettings());

  Future<void> _update(ProfilePrivacySettings next) async {
    emit(next);
    await _persist(next);
  }

  Future<void> _persist(ProfilePrivacySettings settings) async {
    await _preferences.setString(_storageKey, jsonEncode(settings.toJson()));
  }
}
