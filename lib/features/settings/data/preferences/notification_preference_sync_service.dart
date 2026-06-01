import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/features/settings/data/preferences/preference_sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferenceRecord {
  const NotificationPreferenceRecord({
    required this.push,
    required this.email,
    required this.sound,
    required this.vibration,
    required this.catMatches,
    required this.catMessages,
    required this.catLikes,
    required this.catProfileViews,
    required this.catPromotions,
    this.catSafetyAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
  });

  static const defaults = NotificationPreferenceRecord(
    push: true,
    email: true,
    sound: true,
    vibration: true,
    catMatches: true,
    catMessages: true,
    catLikes: true,
    catProfileViews: true,
    catPromotions: true,
  );

  final bool push;
  final bool email;
  final bool sound;
  final bool vibration;
  final bool catMatches;
  final bool catMessages;
  final bool catLikes;
  final bool catProfileViews;
  final bool catPromotions;
  final bool catSafetyAlerts;
  final bool quietHoursEnabled;
  final int quietHoursStart;
  final int quietHoursEnd;

  NotificationPreferenceRecord copyWith({
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
    return NotificationPreferenceRecord(
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

  Map<String, dynamic> toRemoteMap() {
    return <String, dynamic>{
      'push': push,
      'email': email,
      'sound': sound,
      'vibration': vibration,
      'matches': catMatches,
      'messages': catMessages,
      'likes': catLikes,
      'profileViews': catProfileViews,
      'promotions': catPromotions,
      'safetyAlerts': true,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  static NotificationPreferenceRecord fromRemoteMap(Map<String, dynamic> data) {
    return NotificationPreferenceRecord(
      push: _asBool(data['push'], defaults.push),
      email: _asBool(data['email'], defaults.email),
      sound: _asBool(data['sound'], defaults.sound),
      vibration: _asBool(data['vibration'], defaults.vibration),
      catMatches: _asBool(data['matches'], defaults.catMatches),
      catMessages: _asBool(data['messages'], defaults.catMessages),
      catLikes: _asBool(data['likes'], defaults.catLikes),
      catProfileViews: _asBool(data['profileViews'], defaults.catProfileViews),
      catPromotions: _asBool(data['promotions'], defaults.catPromotions),
      catSafetyAlerts: true,
      quietHoursEnabled: _asBool(
        data['quietHoursEnabled'],
        defaults.quietHoursEnabled,
      ),
      quietHoursStart: _asHour(
        data['quietHoursStart'],
        defaults.quietHoursStart,
      ),
      quietHoursEnd: _asHour(data['quietHoursEnd'], defaults.quietHoursEnd),
    );
  }

  bool sameValue(NotificationPreferenceRecord other) {
    return push == other.push &&
        email == other.email &&
        sound == other.sound &&
        vibration == other.vibration &&
        catMatches == other.catMatches &&
        catMessages == other.catMessages &&
        catLikes == other.catLikes &&
        catProfileViews == other.catProfileViews &&
        catPromotions == other.catPromotions &&
        catSafetyAlerts == other.catSafetyAlerts &&
        quietHoursEnabled == other.quietHoursEnabled &&
        quietHoursStart == other.quietHoursStart &&
        quietHoursEnd == other.quietHoursEnd;
  }

  static bool _asBool(Object? value, bool fallback) {
    if (value is bool) return value;
    return fallback;
  }

  static int _asHour(Object? value, int fallback) {
    if (value is num) {
      final hour = value.round().clamp(0, 23);
      return hour;
    }
    return fallback;
  }
}

class NotificationPreferenceHydrationResult {
  const NotificationPreferenceHydrationResult({
    required this.record,
    required this.source,
    required this.hadConflict,
  });

  final NotificationPreferenceRecord record;
  final PreferenceResolutionSource source;
  final bool hadConflict;
}

class NotificationPreferenceSyncService {
  NotificationPreferenceSyncService._({
    required SharedPreferences preferences,
    required Future<PreferenceSyncSnapshot<NotificationPreferenceRecord>?>
    Function()?
    fetchRemoteSnapshot,
    required Future<void> Function(
      NotificationPreferenceRecord record,
      DateTime updatedAt,
    )?
    pushRemoteSnapshot,
    required Future<bool> Function()? requestPushPermission,
    required Future<void> Function()? disablePush,
    required DateTime Function() now,
  }) : _preferences = preferences,
       _fetchRemoteSnapshot = fetchRemoteSnapshot,
       _pushRemoteSnapshot = pushRemoteSnapshot,
       _requestPushPermission = requestPushPermission,
       _disablePush = disablePush,
       _now = now;

  factory NotificationPreferenceSyncService.localOnly({
    required SharedPreferences preferences,
    DateTime Function()? now,
  }) {
    return NotificationPreferenceSyncService._(
      preferences: preferences,
      fetchRemoteSnapshot: null,
      pushRemoteSnapshot: null,
      requestPushPermission: null,
      disablePush: null,
      now: now ?? DateTime.now,
    );
  }

  factory NotificationPreferenceSyncService.withPushService({
    required SharedPreferences preferences,
    required PushNotificationService pushService,
    DateTime Function()? now,
  }) {
    return NotificationPreferenceSyncService._(
      preferences: preferences,
      fetchRemoteSnapshot: () async {
        final remote = await pushService.fetchNotificationPreferencesSnapshot();
        if (remote == null) return null;
        return PreferenceSyncSnapshot<NotificationPreferenceRecord>(
          value: NotificationPreferenceRecord.fromRemoteMap(remote.preferences),
          updatedAt: remote.updatedAt,
        );
      },
      pushRemoteSnapshot: (record, updatedAt) async {
        await pushService.updateNotificationPreferencesMap(
          record.toRemoteMap(),
          clientUpdatedAt: updatedAt,
        );
      },
      requestPushPermission: pushService.requestPermissionForCurrentUser,
      disablePush: pushService.disablePushForCurrentUser,
      now: now ?? DateTime.now,
    );
  }

  factory NotificationPreferenceSyncService.testable({
    required SharedPreferences preferences,
    Future<PreferenceSyncSnapshot<NotificationPreferenceRecord>?> Function()?
    fetchRemoteSnapshot,
    Future<void> Function(
      NotificationPreferenceRecord record,
      DateTime updatedAt,
    )?
    pushRemoteSnapshot,
    Future<bool> Function()? requestPushPermission,
    Future<void> Function()? disablePush,
    DateTime Function()? now,
  }) {
    return NotificationPreferenceSyncService._(
      preferences: preferences,
      fetchRemoteSnapshot: fetchRemoteSnapshot,
      pushRemoteSnapshot: pushRemoteSnapshot,
      requestPushPermission: requestPushPermission,
      disablePush: disablePush,
      now: now ?? DateTime.now,
    );
  }

  final SharedPreferences _preferences;
  final Future<PreferenceSyncSnapshot<NotificationPreferenceRecord>?>
  Function()?
  _fetchRemoteSnapshot;
  final Future<void> Function(
    NotificationPreferenceRecord record,
    DateTime updatedAt,
  )?
  _pushRemoteSnapshot;
  final Future<bool> Function()? _requestPushPermission;
  final Future<void> Function()? _disablePush;
  final DateTime Function() _now;

  static const _pushKey = 'notifications_push';
  static const _emailKey = 'notifications_email';
  static const _soundKey = 'notifications_sound';
  static const _vibrationKey = 'notifications_vibration';
  static const _catMatchesKey = 'notifications_cat_matches';
  static const _catMessagesKey = 'notifications_cat_messages';
  static const _catLikesKey = 'notifications_cat_likes';
  static const _catProfileViewsKey = 'notifications_cat_profile_views';
  static const _catPromotionsKey = 'notifications_cat_promotions';
  static const _quietHoursEnabledKey = 'notifications_quiet_hours_enabled';
  static const _quietHoursStartKey = 'notifications_quiet_hours_start';
  static const _quietHoursEndKey = 'notifications_quiet_hours_end';
  static const _syncUpdatedAtMsKey = 'notifications_sync_updated_at_ms';

  final PreferenceSyncEngine<NotificationPreferenceRecord>
  _syncEngine = PreferenceSyncEngine<NotificationPreferenceRecord>(
    equals: (left, right) => left.sameValue(right),
    // For equal timestamps with divergent values, treat server as source of truth.
    resolveConflict: (_, remoteValue) => remoteValue,
  );

  PreferenceSyncSnapshot<NotificationPreferenceRecord> readLocalSnapshot() {
    final updatedAtMs = _preferences.getInt(_syncUpdatedAtMsKey);
    return PreferenceSyncSnapshot<NotificationPreferenceRecord>(
      value: NotificationPreferenceRecord(
        push:
            _preferences.getBool(_pushKey) ??
            NotificationPreferenceRecord.defaults.push,
        email:
            _preferences.getBool(_emailKey) ??
            NotificationPreferenceRecord.defaults.email,
        sound:
            _preferences.getBool(_soundKey) ??
            NotificationPreferenceRecord.defaults.sound,
        vibration:
            _preferences.getBool(_vibrationKey) ??
            NotificationPreferenceRecord.defaults.vibration,
        catMatches:
            _preferences.getBool(_catMatchesKey) ??
            NotificationPreferenceRecord.defaults.catMatches,
        catMessages:
            _preferences.getBool(_catMessagesKey) ??
            NotificationPreferenceRecord.defaults.catMessages,
        catLikes:
            _preferences.getBool(_catLikesKey) ??
            NotificationPreferenceRecord.defaults.catLikes,
        catProfileViews:
            _preferences.getBool(_catProfileViewsKey) ??
            NotificationPreferenceRecord.defaults.catProfileViews,
        catPromotions:
            _preferences.getBool(_catPromotionsKey) ??
            NotificationPreferenceRecord.defaults.catPromotions,
        catSafetyAlerts: true,
        quietHoursEnabled:
            _preferences.getBool(_quietHoursEnabledKey) ??
            NotificationPreferenceRecord.defaults.quietHoursEnabled,
        quietHoursStart:
            _preferences.getInt(_quietHoursStartKey) ??
            NotificationPreferenceRecord.defaults.quietHoursStart,
        quietHoursEnd:
            _preferences.getInt(_quietHoursEndKey) ??
            NotificationPreferenceRecord.defaults.quietHoursEnd,
      ),
      updatedAt: updatedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  Future<NotificationPreferenceHydrationResult> hydrate() async {
    final localSnapshot = readLocalSnapshot();
    final fetchRemoteSnapshot = _fetchRemoteSnapshot;
    if (fetchRemoteSnapshot == null) {
      return NotificationPreferenceHydrationResult(
        record: localSnapshot.value,
        source: PreferenceResolutionSource.local,
        hadConflict: false,
      );
    }

    final remoteSnapshot = await fetchRemoteSnapshot();
    final pushRemoteSnapshot = _pushRemoteSnapshot;
    final mergeResult = _syncEngine.resolve(
      local: localSnapshot,
      remote: remoteSnapshot,
    );
    final mergedRecord = mergeResult.value;
    final mergedUpdatedAt = mergeResult.updatedAt ?? _now();

    final localChanged = !localSnapshot.value.sameValue(mergedRecord);
    if (localChanged) {
      await _persistLocal(record: mergedRecord, updatedAt: mergedUpdatedAt);
    } else if (localSnapshot.updatedAt == null &&
        mergeResult.updatedAt != null) {
      await _persistLocal(record: mergedRecord, updatedAt: mergedUpdatedAt);
    }

    if (remoteSnapshot != null &&
        pushRemoteSnapshot != null &&
        !remoteSnapshot.value.sameValue(mergedRecord)) {
      try {
        await pushRemoteSnapshot(mergedRecord, mergedUpdatedAt);
      } catch (_) {
        // Local state remains authoritative if remote sync fails.
      }
    }

    return NotificationPreferenceHydrationResult(
      record: mergedRecord,
      source: mergeResult.source,
      hadConflict: mergeResult.hadConflict,
    );
  }

  Future<void> persist(NotificationPreferenceRecord record) async {
    final updatedAt = _now();
    await _persistLocal(record: record, updatedAt: updatedAt);

    final pushRemoteSnapshot = _pushRemoteSnapshot;
    if (pushRemoteSnapshot != null) {
      try {
        await pushRemoteSnapshot(record, updatedAt);
      } catch (_) {
        // Local preference update should not fail if remote sync fails.
      }
    }
  }

  Future<bool> requestPushPermissionForCurrentUser() async {
    final requestPushPermission = _requestPushPermission;
    if (requestPushPermission == null) return true;
    return requestPushPermission();
  }

  Future<void> disablePushForCurrentUser() async {
    final disablePush = _disablePush;
    if (disablePush == null) return;
    await disablePush();
  }

  Future<void> _persistLocal({
    required NotificationPreferenceRecord record,
    required DateTime updatedAt,
  }) async {
    await _preferences.setBool(_pushKey, record.push);
    await _preferences.setBool(_emailKey, record.email);
    await _preferences.setBool(_soundKey, record.sound);
    await _preferences.setBool(_vibrationKey, record.vibration);
    await _preferences.setBool(_catMatchesKey, record.catMatches);
    await _preferences.setBool(_catMessagesKey, record.catMessages);
    await _preferences.setBool(_catLikesKey, record.catLikes);
    await _preferences.setBool(_catProfileViewsKey, record.catProfileViews);
    await _preferences.setBool(_catPromotionsKey, record.catPromotions);
    await _preferences.setBool(_quietHoursEnabledKey, record.quietHoursEnabled);
    await _preferences.setInt(_quietHoursStartKey, record.quietHoursStart);
    await _preferences.setInt(_quietHoursEndKey, record.quietHoursEnd);
    await _preferences.setInt(
      _syncUpdatedAtMsKey,
      updatedAt.millisecondsSinceEpoch,
    );
  }
}
