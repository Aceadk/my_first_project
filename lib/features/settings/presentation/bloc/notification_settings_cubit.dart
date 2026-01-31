import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/services/analytics_service.dart';

class NotificationSettingsState {
  const NotificationSettingsState({
    required this.push,
    required this.email,
    required this.sound,
    required this.vibration,
  });

  final bool push;
  final bool email;
  final bool sound;
  final bool vibration;

  NotificationSettingsState copyWith({
    bool? push,
    bool? email,
    bool? sound,
    bool? vibration,
  }) {
    return NotificationSettingsState(
      push: push ?? this.push,
      email: email ?? this.email,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
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

  static NotificationSettingsState _readInitial(
    SharedPreferences preferences,
  ) {
    return NotificationSettingsState(
      push: preferences.getBool(_pushKey) ?? true,
      email: preferences.getBool(_emailKey) ?? true,
      sound: preferences.getBool(_soundKey) ?? true,
      vibration: preferences.getBool(_vibrationKey) ?? true,
    );
  }

  Future<void> togglePush(bool value) async {
    await AnalyticsService.instance
        .logNotificationSettingsChanged(type: 'push', enabled: value);
    await _update(state.copyWith(push: value));
  }

  Future<void> toggleEmail(bool value) async {
    await AnalyticsService.instance
        .logNotificationSettingsChanged(type: 'email', enabled: value);
    await _update(state.copyWith(email: value));
  }

  Future<void> toggleSound(bool value) async {
    await AnalyticsService.instance
        .logNotificationSettingsChanged(type: 'sound', enabled: value);
    await _update(state.copyWith(sound: value));
  }

  Future<void> toggleVibration(bool value) async {
    await AnalyticsService.instance
        .logNotificationSettingsChanged(type: 'vibration', enabled: value);
    await _update(state.copyWith(vibration: value));
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
  }
}
