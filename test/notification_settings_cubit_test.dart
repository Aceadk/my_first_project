import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';

void main() {
  group('NotificationSettingsCubit', () {
    late _AnalyticsServiceStub analyticsStub;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      analyticsStub = _AnalyticsServiceStub();
      AnalyticsService.setInstance(analyticsStub);
    });

    tearDown(() {
      AnalyticsService.resetInstance();
    });

    test('initializes with defaults when no values are persisted', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      expect(cubit.state.push, isTrue);
      expect(cubit.state.email, isTrue);
      expect(cubit.state.sound, isTrue);
      expect(cubit.state.vibration, isTrue);

      await cubit.close();
    });

    test('reads persisted values on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'notifications_push': false,
        'notifications_email': false,
        'notifications_sound': true,
        'notifications_vibration': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      expect(cubit.state.push, isFalse);
      expect(cubit.state.email, isFalse);
      expect(cubit.state.sound, isTrue);
      expect(cubit.state.vibration, isFalse);

      await cubit.close();
    });

    test('togglePush updates state, persistence, and analytics', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      await cubit.togglePush(false);

      expect(cubit.state.push, isFalse);
      expect(prefs.getBool('notifications_push'), isFalse);
      expect(analyticsStub.calls, [
        {'type': 'push', 'enabled': false},
      ]);

      await cubit.close();
    });

    test('toggleEmail updates state, persistence, and analytics', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      await cubit.toggleEmail(false);

      expect(cubit.state.email, isFalse);
      expect(prefs.getBool('notifications_email'), isFalse);
      expect(analyticsStub.calls, [
        {'type': 'email', 'enabled': false},
      ]);

      await cubit.close();
    });

    test('toggleSound updates state, persistence, and analytics', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      await cubit.toggleSound(false);

      expect(cubit.state.sound, isFalse);
      expect(prefs.getBool('notifications_sound'), isFalse);
      expect(analyticsStub.calls, [
        {'type': 'sound', 'enabled': false},
      ]);

      await cubit.close();
    });

    test('toggleVibration updates state, persistence, and analytics', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = NotificationSettingsCubit(preferences: prefs);

      await cubit.toggleVibration(false);

      expect(cubit.state.vibration, isFalse);
      expect(prefs.getBool('notifications_vibration'), isFalse);
      expect(analyticsStub.calls, [
        {'type': 'vibration', 'enabled': false},
      ]);

      await cubit.close();
    });

    test('copyWith only updates provided fields', () {
      const state = NotificationSettingsState(
        push: true,
        email: true,
        sound: true,
        vibration: true,
      );

      final next = state.copyWith(email: false, vibration: false);

      expect(next.push, isTrue);
      expect(next.email, isFalse);
      expect(next.sound, isTrue);
      expect(next.vibration, isFalse);
    });
  });
}

class _AnalyticsServiceStub extends AnalyticsService {
  _AnalyticsServiceStub() : super.forTesting();

  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> logNotificationSettingsChanged({
    required String type,
    required bool enabled,
  }) async {
    calls.add({'type': type, 'enabled': enabled});
  }
}
