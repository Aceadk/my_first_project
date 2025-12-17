import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/logic/storage/storage_settings_cubit.dart';

void main() {
  group('StorageSettingsCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = StorageSettingsCubit(preferences: prefs);

      expect(cubit.state.cacheSizeMb, 200);
      expect(cubit.state.mediaDownloadEnabled, isTrue);
      expect(cubit.state.mediaDownloadWifiOnly, isTrue);
    });

    test('clamps cache size and persists updates', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = StorageSettingsCubit(preferences: prefs);

      await cubit.setCacheSize(20); // below minimum
      expect(cubit.state.cacheSizeMb, 50);

      await cubit.setCacheSize(1200); // above maximum
      expect(cubit.state.cacheSizeMb, 1000);

      expect(prefs.getInt('storage_cache_mb'), 1000);
    });

    test('toggles media download flags', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = StorageSettingsCubit(preferences: prefs);

      await cubit.setMediaDownloadEnabled(false);
      expect(cubit.state.mediaDownloadEnabled, isFalse);

      await cubit.setMediaDownloadWifiOnly(false);
      expect(cubit.state.mediaDownloadWifiOnly, isFalse);

      expect(prefs.getBool('storage_media_enabled'), isFalse);
      expect(prefs.getBool('storage_media_wifi_only'), isFalse);
    });
  });
}
