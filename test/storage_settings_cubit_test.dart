import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

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

    test(
      'clearCache deletes temp/cache contents and resets cache size',
      () async {
        final root = await Directory.systemTemp.createTemp('storage-cubit-');
        final tempDir = Directory('${root.path}/temp')
          ..createSync(recursive: true);
        final cacheDir = Directory('${root.path}/cache')
          ..createSync(recursive: true);
        final tempFile = File('${tempDir.path}/tmp.txt')
          ..writeAsStringSync('1');
        final tempNestedDir = Directory('${tempDir.path}/nested')
          ..createSync(recursive: true);
        final tempNestedFile = File('${tempNestedDir.path}/n.txt')
          ..writeAsStringSync('2');
        final cacheFile = File('${cacheDir.path}/cache.txt')
          ..writeAsStringSync('3');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (call) async {
              if (call.method == 'getTemporaryDirectory') {
                return tempDir.path;
              }
              if (call.method == 'getApplicationCacheDirectory') {
                return cacheDir.path;
              }
              return root.path;
            });
        addTearDown(() async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(pathProviderChannel, null);
          if (await root.exists()) {
            await root.delete(recursive: true);
          }
        });

        final prefs = await SharedPreferences.getInstance();
        final cubit = StorageSettingsCubit(preferences: prefs);
        await cubit.setCacheSize(700);

        await cubit.clearCache();

        expect(await tempFile.exists(), isFalse);
        expect(await tempNestedFile.exists(), isFalse);
        expect(await tempNestedDir.exists(), isFalse);
        expect(await cacheFile.exists(), isFalse);
        expect(cubit.state.cacheSizeMb, 200);
        expect(prefs.getInt('storage_cache_mb'), 200);
      },
    );

    test('clearCache handles identical temp/cache directory paths', () async {
      final root = await Directory.systemTemp.createTemp('storage-cubit-same-');
      final sharedDir = Directory('${root.path}/shared')
        ..createSync(recursive: true);
      final first = File('${sharedDir.path}/a.txt')..writeAsStringSync('a');
      final second = File('${sharedDir.path}/b.txt')..writeAsStringSync('b');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
            if (call.method == 'getTemporaryDirectory' ||
                call.method == 'getApplicationCacheDirectory') {
              return sharedDir.path;
            }
            return root.path;
          });
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final cubit = StorageSettingsCubit(preferences: prefs);
      await cubit.setCacheSize(900);

      await cubit.clearCache();

      expect(await first.exists(), isFalse);
      expect(await second.exists(), isFalse);
      expect(cubit.state.cacheSizeMb, 200);
    });

    test(
      'clearCache swallows path-provider failures and still resets size',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (call) async {
              throw PlatformException(
                code: 'path-provider-failed',
                message: 'simulated failure',
              );
            });
        addTearDown(() async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(pathProviderChannel, null);
        });

        final prefs = await SharedPreferences.getInstance();
        final cubit = StorageSettingsCubit(preferences: prefs);
        await cubit.setCacheSize(500);

        await cubit.clearCache();

        expect(cubit.state.cacheSizeMb, 200);
        expect(prefs.getInt('storage_cache_mb'), 200);
      },
    );
  });
}
