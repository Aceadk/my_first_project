import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/services/analytics_service.dart';

class NotificationSettingsState {
  const NotificationSettingsState({
    required this.push,
    required this.email,
    required this.sound,
    required this.vibration,
    this.catMatches = true,
    this.catMessages = true,
    this.catLikes = true,
    this.catProfileViews = true,
    this.catPromotions = true,
    this.catSafetyAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
  });

  final bool push;
  final bool email;
  final bool sound;
  final bool vibration;

  /// Category toggles
  final bool catMatches;
  final bool catMessages;
  final bool catLikes;
  final bool catProfileViews;
  final bool catPromotions;

  /// Safety alerts are always on — stored but never disabled.
  final bool catSafetyAlerts;

  /// Quiet hours (notifications queued during this window).
  final bool quietHoursEnabled;
  final int quietHoursStart; // 0-23
  final int quietHoursEnd; // 0-23

  /// How many of the 6 categories are enabled.
  int get enabledCategoryCount {
    int count = 0;
    if (catMatches) count++;
    if (catMessages) count++;
    if (catLikes) count++;
    if (catProfileViews) count++;
    if (catPromotions) count++;
    if (catSafetyAlerts) count++;
    return count;
  }

  NotificationSettingsState copyWith({
    bool? push,
    bool? email,
    bool? sound,
    bool? vibration,
    bool? catMatches,
    bool? catMessages,
    bool? catLikes,
    bool? catProfileViews,
    bool? catPromotions,
    bool? catSafetyAlerts,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) {
    return NotificationSettingsState(
      push: push ?? this.push,
      email: email ?? this.email,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      catMatches: catMatches ?? this.catMatches,
      catMessages: catMessages ?? this.catMessages,
      catLikes: catLikes ?? this.catLikes,
      catProfileViews: catProfileViews ?? this.catProfileViews,
      catPromotions: catPromotions ?? this.catPromotions,
      catSafetyAlerts: catSafetyAlerts ?? this.catSafetyAlerts,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_readInitial(preferences));

  final SharedPreferences _preferences;

  static const _pushKey = 'notifications_push';
  static const _emailKey = 'notifications_email';
  static const _soundKey = 'notifications_sound';
  static const _vibrationKey = 'notifications_vibration';
  static const _catMatchesKey = 'notifications_cat_matches';
  static const _catMessagesKey = 'notifications_cat_messages';
  static const _catLikesKey = 'notifications_cat_likes';
  static const _catProfileViewsKey = 'notifications_cat_profile_views';
  static const _catPromotionsKey = 'notifications_cat_promotions';
  static const _quietHoursEnabledKey = 'notifications_quiet_hours_enabled';
  static const _quietHoursStartKey = 'notifications_quiet_hours_start';
  static const _quietHoursEndKey = 'notifications_quiet_hours_end';

  static NotificationSettingsState _readInitial(SharedPreferences preferences) {
    return NotificationSettingsState(
      push: preferences.getBool(_pushKey) ?? true,
      email: preferences.getBool(_emailKey) ?? true,
      sound: preferences.getBool(_soundKey) ?? true,
      vibration: preferences.getBool(_vibrationKey) ?? true,
      catMatches: preferences.getBool(_catMatchesKey) ?? true,
      catMessages: preferences.getBool(_catMessagesKey) ?? true,
      catLikes: preferences.getBool(_catLikesKey) ?? true,
      catProfileViews: preferences.getBool(_catProfileViewsKey) ?? true,
      catPromotions: preferences.getBool(_catPromotionsKey) ?? true,
      catSafetyAlerts: true, // Always on
      quietHoursEnabled: preferences.getBool(_quietHoursEnabledKey) ?? false,
      quietHoursStart: preferences.getInt(_quietHoursStartKey) ?? 22,
      quietHoursEnd: preferences.getInt(_quietHoursEndKey) ?? 8,
    );
  }

  Future<void> togglePush(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'push',
      enabled: value,
    );
    await _update(state.copyWith(push: value));
  }

  Future<void> toggleEmail(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'email',
      enabled: value,
    );
    await _update(state.copyWith(email: value));
  }

  Future<void> toggleSound(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'sound',
      enabled: value,
    );
    await _update(state.copyWith(sound: value));
  }

  Future<void> toggleVibration(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'vibration',
      enabled: value,
    );
    await _update(state.copyWith(vibration: value));
  }

  Future<void> toggleCatMatches(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'cat_matches',
      enabled: value,
    );
    await _update(state.copyWith(catMatches: value));
  }

  Future<void> toggleCatMessages(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'cat_messages',
      enabled: value,
    );
    await _update(state.copyWith(catMessages: value));
  }

  Future<void> toggleCatLikes(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'cat_likes',
      enabled: value,
    );
    await _update(state.copyWith(catLikes: value));
  }

  Future<void> toggleCatProfileViews(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'cat_profile_views',
      enabled: value,
    );
    await _update(state.copyWith(catProfileViews: value));
  }

  Future<void> toggleCatPromotions(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'cat_promotions',
      enabled: value,
    );
    await _update(state.copyWith(catPromotions: value));
  }

  Future<void> toggleQuietHours(bool value) async {
    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'quiet_hours',
      enabled: value,
    );
    await _update(state.copyWith(quietHoursEnabled: value));
  }

  Future<void> setQuietHoursStart(int hour) async {
    await _update(state.copyWith(quietHoursStart: hour));
  }

  Future<void> setQuietHoursEnd(int hour) async {
    await _update(state.copyWith(quietHoursEnd: hour));
  }

  Future<void> _update(NotificationSettingsState next) async {
    emit(next);
    await _persist(next);
  }

  Future<void> _persist(NotificationSettingsState state) async {
    await _preferences.setBool(_pushKey, state.push);
    await _preferences.setBool(_emailKey, state.email);
    await _preferences.setBool(_soundKey, state.sound);
    await _preferences.setBool(_vibrationKey, state.vibration);
    await _preferences.setBool(_catMatchesKey, state.catMatches);
    await _preferences.setBool(_catMessagesKey, state.catMessages);
    await _preferences.setBool(_catLikesKey, state.catLikes);
    await _preferences.setBool(_catProfileViewsKey, state.catProfileViews);
    await _preferences.setBool(_catPromotionsKey, state.catPromotions);
    await _preferences.setBool(_quietHoursEnabledKey, state.quietHoursEnabled);
    await _preferences.setInt(_quietHoursStartKey, state.quietHoursStart);
    await _preferences.setInt(_quietHoursEndKey, state.quietHoursEnd);
  }
}
