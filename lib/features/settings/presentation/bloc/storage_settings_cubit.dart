import 'package:flutter_bloc/flutter_bloc.dart';
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
      mediaDownloadEnabled:
          mediaDownloadEnabled ?? this.mediaDownloadEnabled,
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
    // Hook for clearing caches; currently resets size to default.
    await _persist(state.copyWith(cacheSizeMb: _defaultCacheMb));
  }

  Future<void> _persist(StorageSettingsState next) async {
    emit(next);
    await _preferences.setInt(_cacheKey, next.cacheSizeMb);
    await _preferences.setBool(_wifiOnlyKey, next.mediaDownloadWifiOnly);
    await _preferences.setBool(_downloadEnabledKey, next.mediaDownloadEnabled);
  }
}
