import 'dart:async';
import '../models/incognito_settings.dart';

/// Service for managing incognito/private browsing mode.
class IncognitoService {
  IncognitoService._();
  static final IncognitoService instance = IncognitoService._();

  final _settingsController = StreamController<IncognitoSettings>.broadcast();
  Stream<IncognitoSettings> get settingsStream => _settingsController.stream;

  IncognitoSettings _currentSettings = const IncognitoSettings();

  IncognitoSettings get currentSettings => _currentSettings;
  bool get isIncognito => _currentSettings.isActive;

  /// Load settings.
  Future<IncognitoSettings> loadSettings() async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 300));
    _settingsController.add(_currentSettings);
    return _currentSettings;
  }

  /// Enable incognito mode.
  Future<IncognitoSettings> enableIncognito({
    bool hideFromLikedYou = true,
    bool hideLastActive = true,
    bool hideReadReceipts = true,
    bool onlyShowToLiked = false,
    bool isPremium = false,
  }) async {
    final expiresAt = isPremium
        ? null
        : DateTime.now().add(IncognitoSettings.freeDuration);

    _currentSettings = IncognitoSettings(
      isEnabled: true,
      enabledAt: DateTime.now(),
      expiresAt: expiresAt,
      hideFromLikedYou: hideFromLikedYou,
      hideLastActive: hideLastActive,
      hideReadReceipts: hideReadReceipts,
      onlyShowToLiked: onlyShowToLiked,
    );

    _settingsController.add(_currentSettings);

    // Schedule auto-disable for free users
    if (expiresAt != null) {
      _scheduleAutoDisable(expiresAt);
    }

    await _saveSettings();
    return _currentSettings;
  }

  /// Disable incognito mode.
  Future<IncognitoSettings> disableIncognito() async {
    _currentSettings = const IncognitoSettings(isEnabled: false);
    _settingsController.add(_currentSettings);
    await _saveSettings();
    return _currentSettings;
  }

  /// Update specific incognito settings.
  Future<IncognitoSettings> updateSettings({
    bool? hideFromLikedYou,
    bool? hideLastActive,
    bool? hideReadReceipts,
    bool? onlyShowToLiked,
  }) async {
    _currentSettings = _currentSettings.copyWith(
      hideFromLikedYou: hideFromLikedYou,
      hideLastActive: hideLastActive,
      hideReadReceipts: hideReadReceipts,
      onlyShowToLiked: onlyShowToLiked,
    );

    _settingsController.add(_currentSettings);
    await _saveSettings();
    return _currentSettings;
  }

  /// Check if profile should be visible to a specific user.
  bool isVisibleTo(String viewerUserId, {bool viewerHasLiked = false}) {
    if (!_currentSettings.isActive) return true;

    // If only showing to people who liked, check if viewer liked
    if (_currentSettings.onlyShowToLiked && !viewerHasLiked) {
      return false;
    }

    return true;
  }

  /// Check if should show read receipts.
  bool shouldShowReadReceipts() {
    if (!_currentSettings.isActive) return true;
    return !_currentSettings.hideReadReceipts;
  }

  /// Check if should show last active status.
  bool shouldShowLastActive() {
    if (!_currentSettings.isActive) return true;
    return !_currentSettings.hideLastActive;
  }

  /// Get remaining incognito time.
  Duration getRemainingTime() {
    return _currentSettings.remainingTime;
  }

  void _scheduleAutoDisable(DateTime disableAt) {
    final delay = disableAt.difference(DateTime.now());
    if (delay.isNegative) {
      disableIncognito();
      return;
    }

    Future.delayed(delay, () {
      if (_currentSettings.isEnabled && _currentSettings.isExpired) {
        disableIncognito();
      }
    });
  }

  Future<void> _saveSettings() async {
    // In production, save to backend
  }

  void dispose() {
    _settingsController.close();
  }
}
