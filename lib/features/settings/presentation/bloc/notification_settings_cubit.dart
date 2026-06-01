import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/settings/data/preferences/notification_preference_sync_service.dart';

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
  NotificationSettingsCubit({
    required SharedPreferences preferences,
    NotificationPreferenceSyncService? syncService,
  }) : this._(
         syncService ??
             NotificationPreferenceSyncService.localOnly(
               preferences: preferences,
             ),
       );

  NotificationSettingsCubit._(this._syncService)
    : super(_stateFromRecord(_syncService.readLocalSnapshot().value)) {
    unawaited(_hydrateFromRemote());
  }

  final NotificationPreferenceSyncService _syncService;

  Future<bool> togglePush(bool value) async {
    var enabled = value;
    if (value) {
      enabled = await _syncService.requestPushPermissionForCurrentUser();
    } else {
      await _syncService.disablePushForCurrentUser();
    }

    await AnalyticsService.instance.logNotificationSettingsChanged(
      type: 'push',
      enabled: enabled,
    );
    await _update(state.copyWith(push: enabled));
    return enabled;
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
    await _syncService.persist(_recordFromState(next));
  }

  Future<void> _hydrateFromRemote() async {
    final hydration = await _syncService.hydrate();
    if (isClosed) return;
    final mergedState = _stateFromRecord(hydration.record);
    if (!_stateEquals(state, mergedState)) {
      emit(mergedState);
    }
  }

  static NotificationPreferenceRecord _recordFromState(
    NotificationSettingsState state,
  ) {
    return NotificationPreferenceRecord(
      push: state.push,
      email: state.email,
      sound: state.sound,
      vibration: state.vibration,
      catMatches: state.catMatches,
      catMessages: state.catMessages,
      catLikes: state.catLikes,
      catProfileViews: state.catProfileViews,
      catPromotions: state.catPromotions,
      catSafetyAlerts: state.catSafetyAlerts,
      quietHoursEnabled: state.quietHoursEnabled,
      quietHoursStart: state.quietHoursStart,
      quietHoursEnd: state.quietHoursEnd,
    );
  }

  static NotificationSettingsState _stateFromRecord(
    NotificationPreferenceRecord record,
  ) {
    return NotificationSettingsState(
      push: record.push,
      email: record.email,
      sound: record.sound,
      vibration: record.vibration,
      catMatches: record.catMatches,
      catMessages: record.catMessages,
      catLikes: record.catLikes,
      catProfileViews: record.catProfileViews,
      catPromotions: record.catPromotions,
      catSafetyAlerts: true,
      quietHoursEnabled: record.quietHoursEnabled,
      quietHoursStart: record.quietHoursStart,
      quietHoursEnd: record.quietHoursEnd,
    );
  }

  static bool _stateEquals(
    NotificationSettingsState left,
    NotificationSettingsState right,
  ) {
    return left.push == right.push &&
        left.email == right.email &&
        left.sound == right.sound &&
        left.vibration == right.vibration &&
        left.catMatches == right.catMatches &&
        left.catMessages == right.catMessages &&
        left.catLikes == right.catLikes &&
        left.catProfileViews == right.catProfileViews &&
        left.catPromotions == right.catPromotions &&
        left.catSafetyAlerts == right.catSafetyAlerts &&
        left.quietHoursEnabled == right.quietHoursEnabled &&
        left.quietHoursStart == right.quietHoursStart &&
        left.quietHoursEnd == right.quietHoursEnd;
  }
}
