import 'dart:io';
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsState {
  const StorageSettingsState({
    required this.cacheSizeMb,
    required this.mediaDownloadWifiOnly,
    required this.mediaDownloadEnabled,
  });

  final int cacheSizeMb;
  final bool mediaDownloadWifiOnly;
  final bool mediaDownloadEnabled;

  StorageSettingsState copyWith({
    int? cacheSizeMb,
    bool? mediaDownloadWifiOnly,
    bool? mediaDownloadEnabled,
  }) {
    return StorageSettingsState(
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      mediaDownloadWifiOnly:
          mediaDownloadWifiOnly ?? this.mediaDownloadWifiOnly,
      mediaDownloadEnabled: mediaDownloadEnabled ?? this.mediaDownloadEnabled,
    );
  }
}

class StorageSettingsCubit extends Cubit<StorageSettingsState> {
  StorageSettingsCubit({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_readInitial(preferences));

  final SharedPreferences _preferences;

  static const _cacheKey = 'storage_cache_mb';
  static const _wifiOnlyKey = 'storage_media_wifi_only';
  static const _downloadEnabledKey = 'storage_media_enabled';

  static const _defaultCacheMb = 200;

  static StorageSettingsState _readInitial(SharedPreferences prefs) {
    return StorageSettingsState(
      cacheSizeMb: prefs.getInt(_cacheKey) ?? _defaultCacheMb,
      mediaDownloadWifiOnly: prefs.getBool(_wifiOnlyKey) ?? true,
      mediaDownloadEnabled: prefs.getBool(_downloadEnabledKey) ?? true,
    );
  }

  Future<void> setCacheSize(int mb) async {
    final clamped = mb.clamp(50, 1000);
    await _persist(state.copyWith(cacheSizeMb: clamped));
  }

  Future<void> setMediaDownloadEnabled(bool enabled) async {
    await _persist(state.copyWith(mediaDownloadEnabled: enabled));
  }

  Future<void> setMediaDownloadWifiOnly(bool wifiOnly) async {
    await _persist(state.copyWith(mediaDownloadWifiOnly: wifiOnly));
  }

  Future<void> clearCache() async {
    try {
      // Get the temporary directory where cached files are stored
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        // Delete all files in the temp directory
        final files = tempDir.listSync();
        for (final file in files) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            AppLogger.debug(
              'StorageSettingsCubit: Failed to delete ${file.path}: $e',
            );
          }
        }
      }

      // Also clear the app's cache directory if different
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists() && cacheDir.path != tempDir.path) {
        final cacheFiles = cacheDir.listSync();
        for (final file in cacheFiles) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            AppLogger.debug(
              'StorageSettingsCubit: Failed to delete ${file.path}: $e',
            );
          }
        }
      }

      AppLogger.debug('StorageSettingsCubit: Cache cleared successfully');
    } catch (e) {
      AppLogger.error('StorageSettingsCubit: Failed to clear cache: $e');
    }

    // Reset tracked cache size to default
    await _persist(state.copyWith(cacheSizeMb: _defaultCacheMb));
  }

  Future<void> _persist(StorageSettingsState next) async {
    emit(next);
    await _preferences.setInt(_cacheKey, next.cacheSizeMb);
    await _preferences.setBool(_wifiOnlyKey, next.mediaDownloadWifiOnly);
    await _preferences.setBool(_downloadEnabledKey, next.mediaDownloadEnabled);
  }
}
