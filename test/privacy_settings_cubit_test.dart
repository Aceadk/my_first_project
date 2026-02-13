import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';

void main() {
  group('PrivacySettingsCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with default settings when no data is persisted',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      expect(cubit.state, const ProfilePrivacySettings());

      await cubit.close();
    });

    test('initializes from persisted JSON settings', () async {
      final saved = ProfilePrivacySettings.allPrivate().copyWith(
        showAge: true,
        showLanguages: true,
      );
      SharedPreferences.setMockInitialValues({
        'privacy_settings': jsonEncode(saved.toJson()),
      });

      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      expect(cubit.state, saved);

      await cubit.close();
    });

    test('falls back to defaults when persisted JSON is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'privacy_settings': '{invalid-json',
      });

      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      expect(cubit.state, const ProfilePrivacySettings());

      await cubit.close();
    });

    test('toggle methods update state and persist JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      await cubit.toggleShowFirstName(true);
      await cubit.toggleShowLastName(true);
      await cubit.toggleShowAge(false);
      await cubit.toggleShowDateOfBirth(true);
      await cubit.toggleShowEmail(true);
      await cubit.toggleShowPhoneNumber(true);
      await cubit.toggleShowExactLocation(true);
      await cubit.toggleShowHeight(false);
      await cubit.toggleShowZodiacSign(false);
      await cubit.toggleShowEducation(false);
      await cubit.toggleShowFamilyPlans(false);
      await cubit.toggleShowPersonality(false);
      await cubit.toggleShowRelationshipGoals(false);
      await cubit.toggleShowWorkout(false);
      await cubit.toggleShowSmoking(false);
      await cubit.toggleShowDrinking(false);
      await cubit.toggleShowDiet(false);
      await cubit.toggleShowSleepingHabits(false);
      await cubit.toggleShowPets(false);
      await cubit.toggleShowJobTitle(false);
      await cubit.toggleShowCompany(false);
      await cubit.toggleShowSchool(false);
      await cubit.toggleShowFavoriteSongs(false);
      await cubit.toggleShowFavoriteSinger(false);
      await cubit.toggleShowSocialMedia(false);
      await cubit.toggleShowLanguages(false);
      await cubit.toggleShowOnlineStatus(true);
      await cubit.toggleShowLastActive(true);

      final current = cubit.state;
      expect(current.showFirstName, isTrue);
      expect(current.showLastName, isTrue);
      expect(current.showAge, isFalse);
      expect(current.showDateOfBirth, isTrue);
      expect(current.showEmail, isTrue);
      expect(current.showPhoneNumber, isTrue);
      expect(current.showExactLocation, isTrue);
      expect(current.showHeight, isFalse);
      expect(current.showZodiacSign, isFalse);
      expect(current.showEducation, isFalse);
      expect(current.showFamilyPlans, isFalse);
      expect(current.showPersonality, isFalse);
      expect(current.showRelationshipGoals, isFalse);
      expect(current.showWorkout, isFalse);
      expect(current.showSmoking, isFalse);
      expect(current.showDrinking, isFalse);
      expect(current.showDiet, isFalse);
      expect(current.showSleepingHabits, isFalse);
      expect(current.showPets, isFalse);
      expect(current.showJobTitle, isFalse);
      expect(current.showCompany, isFalse);
      expect(current.showSchool, isFalse);
      expect(current.showFavoriteSongs, isFalse);
      expect(current.showFavoriteSinger, isFalse);
      expect(current.showSocialMedia, isFalse);
      expect(current.showLanguages, isFalse);
      expect(current.showOnlineStatus, isTrue);
      expect(current.showLastActive, isTrue);

      final persistedRaw = prefs.getString('privacy_settings');
      expect(persistedRaw, isNotNull);
      final persisted = ProfilePrivacySettings.fromJson(
        jsonDecode(persistedRaw!),
      );
      expect(persisted, current);

      await cubit.close();
    });

    test('setAllPublic makes every field visible and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      await cubit.setAllPublic();

      expect(cubit.state, ProfilePrivacySettings.allPublic());
      final persistedRaw = prefs.getString('privacy_settings');
      expect(persistedRaw, isNotNull);
      final persisted = ProfilePrivacySettings.fromJson(
        jsonDecode(persistedRaw!),
      );
      expect(persisted, ProfilePrivacySettings.allPublic());

      await cubit.close();
    });

    test('setAllPrivate hides every field and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      await cubit.setAllPrivate();

      expect(cubit.state, ProfilePrivacySettings.allPrivate());
      final persistedRaw = prefs.getString('privacy_settings');
      expect(persistedRaw, isNotNull);
      final persisted = ProfilePrivacySettings.fromJson(
        jsonDecode(persistedRaw!),
      );
      expect(persisted, ProfilePrivacySettings.allPrivate());

      await cubit.close();
    });

    test('resetToDefaults restores default settings and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = PrivacySettingsCubit(preferences: prefs);

      await cubit.setAllPrivate();
      expect(cubit.state, ProfilePrivacySettings.allPrivate());

      await cubit.resetToDefaults();
      expect(cubit.state, const ProfilePrivacySettings());

      final persistedRaw = prefs.getString('privacy_settings');
      expect(persistedRaw, isNotNull);
      final persisted = ProfilePrivacySettings.fromJson(
        jsonDecode(persistedRaw!),
      );
      expect(persisted, const ProfilePrivacySettings());

      await cubit.close();
    });
  });
}
