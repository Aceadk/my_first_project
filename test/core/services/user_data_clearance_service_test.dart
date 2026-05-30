import 'package:crushhour/core/security/biometric_service.dart';
import 'package:crushhour/core/security/session_manager.dart';
import 'package:crushhour/core/services/app_state_preserver.dart';
import 'package:crushhour/core/services/user_data_clearance_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStore = <String, String>{};

  Future<dynamic> secureStorageHandler(MethodCall call) async {
    final args = ((call.arguments as Map?) ?? const <Object?, Object?>{})
        .cast<Object?, Object?>();
    final key = args['key'] as String?;

    switch (call.method) {
      case 'read':
        return key == null ? null : secureStore[key];
      case 'write':
        if (key != null) {
          final value = args['value']?.toString();
          if (value == null) {
            secureStore.remove(key);
          } else {
            secureStore[key] = value;
          }
        }
        return null;
      case 'delete':
        if (key != null) {
          secureStore.remove(key);
        }
        return null;
      case 'deleteAll':
        secureStore.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(secureStore);
      case 'containsKey':
        return key != null && secureStore.containsKey(key);
    }

    return null;
  }

  setUp(() async {
    secureStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, secureStorageHandler);
    await AppStatePreserver.instance.initialize(const FlutterSecureStorage());
    await AppStatePreserver.instance.clearPreservedRoute();
    await SessionManager.instance.clearSession();
  });

  tearDown(() async {
    SessionManager.instance.pause();
    await SessionManager.instance.clearSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test(
    'clearAllUserData removes preference and secure auth-adjacent artifacts',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'safety_blocked': 'user-2',
        'privacy_settings': '{"showOnline":false}',
        'offline_action_queue': '[]',
        'crush_theme_mode': 'dark',
      });
      final preferences = await SharedPreferences.getInstance();

      await SessionManager.instance.initialize(
        timeout: const Duration(minutes: 5),
        enabled: true,
      );
      await AppStatePreserver.instance.saveCurrentRoute('/chat/match-1');
      await BiometricService.instance.setEnabled(true);
      await BiometricService.instance.setPinHash('pin-hash');

      expect(preferences.getString('safety_blocked'), 'user-2');
      expect(secureStore['last_activity_timestamp'], isNotNull);
      expect(secureStore['app_last_route'], '/chat/match-1');
      expect(secureStore['biometric_auth_enabled'], 'true');
      expect(secureStore['biometric_pin_hash'], 'pin-hash');

      await UserDataClearanceService.instance.clearAllUserData();

      expect(preferences.getString('safety_blocked'), isNull);
      expect(preferences.getString('privacy_settings'), isNull);
      expect(preferences.getString('offline_action_queue'), isNull);
      expect(preferences.getString('crush_theme_mode'), 'dark');
      expect(secureStore.containsKey('last_activity_timestamp'), isFalse);
      expect(secureStore.containsKey('app_last_route'), isFalse);
      expect(secureStore.containsKey('app_last_route_timestamp'), isFalse);
      expect(secureStore.containsKey('biometric_auth_enabled'), isFalse);
      expect(secureStore.containsKey('biometric_pin_hash'), isFalse);
    },
  );
}
