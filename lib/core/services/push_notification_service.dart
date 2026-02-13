import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/security/secure_logger.dart';
import 'package:crushhour/core/app_logger.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Background message: ${message.messageId}');
}

/// Service to handle push notifications via Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// SharedPreferences keys for notification settings
  static const _soundKey = 'notifications_sound';
  static const _vibrationKey = 'notifications_vibration';

  String? _currentUserId;

  /// Callback when notification is tapped
  void Function(String? payload)? onNotificationTapped;

  /// Callback when a new message is received while app is in foreground
  void Function(RemoteMessage message)? onForegroundMessage;

  @visibleForTesting
  Future<void> Function({
    required int id,
    String? title,
    String? body,
    required bool soundEnabled,
    required bool vibrationEnabled,
    String? payload,
  })?
  showLocalNotificationOverride;

  @visibleForTesting
  Future<RemoteMessage?> Function()? initialMessageProviderOverride;

  @visibleForTesting
  Future<String?> Function()? tokenProviderOverride;

  @visibleForTesting
  Stream<String>? tokenRefreshOverride;

  @visibleForTesting
  Future<void> Function(String userId, String token)? saveTokenOverride;

  @visibleForTesting
  Future<void> Function(String userId, String token)? deleteTokenOverride;

  @visibleForTesting
  Future<void> Function(String userId, Map<String, dynamic> prefs)?
  saveNotificationPrefsOverride;

  @visibleForTesting
  Future<void> Function()? requestPermissionOverride;

  @visibleForTesting
  Future<void> Function()? initializeLocalNotificationsOverride;

  @visibleForTesting
  Future<void> Function()? createNotificationChannelOverride;

  @visibleForTesting
  void Function()? setupMessageHandlersOverride;

  @visibleForTesting
  Future<void> Function()? printFcmTokenOverride;

  @visibleForTesting
  Future<void> Function(String topic)? subscribeToTopicOverride;

  @visibleForTesting
  Future<void> Function(String topic)? unsubscribeFromTopicOverride;

  @visibleForTesting
  Future<void> Function(int id)? cancelNotificationOverride;

  @visibleForTesting
  Future<void> Function()? cancelAllNotificationsOverride;

  /// Android notification channel for high importance notifications
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Initialize the notification service
  Future<void> initialize() async {
    // Request permission
    if (requestPermissionOverride != null) {
      await requestPermissionOverride!();
    } else {
      await _requestPermission();
    }

    // Initialize local notifications
    if (initializeLocalNotificationsOverride != null) {
      await initializeLocalNotificationsOverride!();
    } else {
      await _initializeLocalNotifications();
    }

    // Create Android notification channel
    if (createNotificationChannelOverride != null) {
      await createNotificationChannelOverride!();
    } else {
      await _createNotificationChannel();
    }

    // Set up message handlers
    if (setupMessageHandlersOverride != null) {
      setupMessageHandlersOverride!();
    } else {
      _setupMessageHandlers();
    }

    // Get and print FCM token (for testing)
    if (printFcmTokenOverride != null) {
      await printFcmTokenOverride!();
    } else {
      await _printFCMToken();
    }
  }

  @visibleForTesting
  void clearTestOverrides() {
    showLocalNotificationOverride = null;
    initialMessageProviderOverride = null;
    tokenProviderOverride = null;
    tokenRefreshOverride = null;
    saveTokenOverride = null;
    deleteTokenOverride = null;
    saveNotificationPrefsOverride = null;
    requestPermissionOverride = null;
    initializeLocalNotificationsOverride = null;
    createNotificationChannelOverride = null;
    setupMessageHandlersOverride = null;
    printFcmTokenOverride = null;
    subscribeToTopicOverride = null;
    unsubscribeFromTopicOverride = null;
    cancelNotificationOverride = null;
    cancelAllNotificationsOverride = null;
    onNotificationTapped = null;
    onForegroundMessage = null;
    _currentUserId = null;
  }

  @visibleForTesting
  Future<bool> getSoundEnabledForTest() => _getSoundEnabled();

  @visibleForTesting
  Future<bool> getVibrationEnabledForTest() => _getVibrationEnabled();

  @visibleForTesting
  void setCurrentUserIdForTest(String? userId) {
    _currentUserId = userId;
  }

  @visibleForTesting
  Future<void> checkInitialMessageForTest() => _checkInitialMessage();

  @visibleForTesting
  void handleForegroundMessageForTest(RemoteMessage message) {
    _handleForegroundMessage(message);
  }

  @visibleForTesting
  void handleMessageOpenedAppForTest(RemoteMessage message) {
    _handleMessageOpenedApp(message);
  }

  @visibleForTesting
  void handleNotificationResponseForTest(NotificationResponse response) {
    _onNotificationResponse(response);
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.debug('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_highImportanceChannel);
    }
  }

  /// Set up Firebase message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When app is opened from notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification (terminated state)
    _checkInitialMessage();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.debug('Foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);

    // Notify callback
    onForegroundMessage?.call(message);
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.debug('App opened from notification: ${message.messageId}');

    final payload = jsonEncode(message.data);
    onNotificationTapped?.call(payload);
  }

  /// Check if app was opened from notification (terminated state)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await (initialMessageProviderOverride != null
        ? initialMessageProviderOverride!()
        : _messaging.getInitialMessage());
    if (initialMessage != null) {
      AppLogger.debug('App opened from terminated: ${initialMessage.messageId}');
      final payload = jsonEncode(initialMessage.data);
      onNotificationTapped?.call(payload);
    }
  }

  /// Get user's sound preference from SharedPreferences
  Future<bool> _getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  /// Get user's vibration preference from SharedPreferences
  Future<bool> _getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  /// Show a local notification respecting user's sound/vibration preferences
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Read user preferences for sound and vibration
    final soundEnabled = await _getSoundEnabled();
    final vibrationEnabled = await _getVibrationEnabled();

    if (showLocalNotificationOverride != null) {
      await showLocalNotificationOverride!(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        payload: jsonEncode(message.data),
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap response
  void _onNotificationResponse(NotificationResponse response) {
    AppLogger.debug('Notification tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (tokenProviderOverride != null) {
      return await tokenProviderOverride!();
    }
    return await _messaging.getToken();
  }

  /// Print FCM token for testing (redacted for security)
  Future<void> _printFCMToken() async {
    final token = await getToken();
    // SECURITY: Never log full FCM tokens - use SecureLogger
    SecureLogger.logToken(type: 'FCM', token: token);
  }

  /// Register FCM token for a user (call after login)
  Future<void> registerForUser(String userId) async {
    _currentUserId = userId;
    final token = await getToken();
    if (token != null) {
      if (saveTokenOverride != null) {
        await saveTokenOverride!(userId, token);
      } else {
        await _saveTokenToFirestore(userId, token);
      }
    }

    // Listen for token refresh
    final tokenRefreshStream =
        tokenRefreshOverride ?? _messaging.onTokenRefresh;
    tokenRefreshStream.listen((newToken) {
      if (_currentUserId != null) {
        if (saveTokenOverride != null) {
          saveTokenOverride!(_currentUserId!, newToken);
        } else {
          _saveTokenToFirestore(_currentUserId!, newToken);
        }
      }
    });
  }

  /// Unregister FCM token (call on logout)
  Future<void> unregisterForUser() async {
    final userId = _currentUserId;
    final token = await getToken();
    if (userId != null && token != null) {
      if (deleteTokenOverride != null) {
        await deleteTokenOverride!(userId, token);
      } else {
        await _deleteTokenFromFirestore(userId, token);
      }
    }
    _currentUserId = null;
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'createdAt': Timestamp.now(),
            'platform': Platform.isIOS ? 'ios' : 'android',
          });
      AppLogger.debug('FCM token saved for user: $userId');
    } catch (e) {
      AppLogger.error('Error saving FCM token: $e');
    }
  }

  /// Delete FCM token from Firestore
  Future<void> _deleteTokenFromFirestore(String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();
      AppLogger.debug('FCM token deleted for user: $userId');
    } catch (e) {
      AppLogger.error('Error deleting FCM token: $e');
    }
  }

  /// Update notification preferences in Firestore (backend uses these to filter notifications)
  Future<void> updateNotificationPreferences({
    bool? push,
    bool? email,
    bool? sound,
    bool? vibration,
    bool? messages,
    bool? matches,
    bool? subscriptions,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final prefs = buildNotificationPrefs(
        push: push,
        email: email,
        sound: sound,
        vibration: vibration,
        messages: messages,
        matches: matches,
        subscriptions: subscriptions,
      );

      if (prefs.isNotEmpty) {
        if (saveNotificationPrefsOverride != null) {
          await saveNotificationPrefsOverride!(userId, prefs);
        } else {
          await _firestore.collection('users').doc(userId).set({
            'notificationPrefs': prefs,
          }, SetOptions(merge: true));
        }
        AppLogger.debug('Notification preferences updated for user: $userId');
      }
    } catch (e) {
      AppLogger.error('Error updating notification preferences: $e');
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildNotificationPrefs({
    bool? push,
    bool? email,
    bool? sound,
    bool? vibration,
    bool? messages,
    bool? matches,
    bool? subscriptions,
  }) {
    final prefs = <String, dynamic>{};
    if (push != null) prefs['push'] = push;
    if (email != null) prefs['email'] = email;
    if (sound != null) prefs['sound'] = sound;
    if (vibration != null) prefs['vibration'] = vibration;
    if (messages != null) prefs['messages'] = messages;
    if (matches != null) prefs['matches'] = matches;
    if (subscriptions != null) prefs['subscriptions'] = subscriptions;
    return prefs;
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    if (subscribeToTopicOverride != null) {
      await subscribeToTopicOverride!(topic);
    } else {
      await _messaging.subscribeToTopic(topic);
    }
    AppLogger.debug('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (unsubscribeFromTopicOverride != null) {
      await unsubscribeFromTopicOverride!(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
    AppLogger.debug('Unsubscribed from topic: $topic');
  }

  /// Show a custom local notification respecting user's sound/vibration preferences
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Read user preferences for sound and vibration
    final soundEnabled = await _getSoundEnabled();
    final vibrationEnabled = await _getVibrationEnabled();

    if (showLocalNotificationOverride != null) {
      await showLocalNotificationOverride!(
        id: id,
        title: title,
        body: body,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        payload: payload,
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    if (cancelNotificationOverride != null) {
      await cancelNotificationOverride!(id);
    } else {
      await _localNotifications.cancel(id: id);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (cancelAllNotificationsOverride != null) {
      await cancelAllNotificationsOverride!();
    } else {
      await _localNotifications.cancelAll();
    }
  }
}
