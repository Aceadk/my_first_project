import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/data/models/user.dart';

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit({
    required SharedPreferences preferences,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _preferences = preferences,
        _authRepository = authRepository,
        _profileRepository = profileRepository,
        super(_readInitial(preferences)) {
    _authSubscription =
        _authRepository.authStateChanges().listen(_syncFromUser);
  }

  final SharedPreferences _preferences;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  static const _key = 'crush_theme_mode';
  late final StreamSubscription _authSubscription;

  static AppThemeMode _readInitial(SharedPreferences prefs) {
    return appThemeModeFromKey(prefs.getString(_key));
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _preferences.setString(_key, mode.storageKey);
    await _syncToAccount(mode);
  }

  Future<void> _syncToAccount(AppThemeMode mode) async {
    try {
      await _profileRepository.updateThemePreference(mode.storageKey);
    } catch (_) {
      // Best-effort sync. Local preference still applies.
    }
  }

  Future<void> _syncFromUser(CrushUser? user) async {
    if (user == null) return;
    final preference = user.themePreference;
    if (preference == null || preference.isEmpty) return;
    final remoteMode = appThemeModeFromKey(preference);
    if (remoteMode == state) return;

    emit(remoteMode);
    await _preferences.setString(_key, remoteMode.storageKey);
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
