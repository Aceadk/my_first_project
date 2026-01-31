import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/security/secure_logger.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
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
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create Android notification channel
    await _createNotificationChannel();

    // Set up message handlers
    _setupMessageHandlers();

    // Get and print FCM token (for testing)
    await _printFCMToken();
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

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
    debugPrint('Foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);

    // Notify callback
    onForegroundMessage?.call(message);
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.messageId}');

    final payload = jsonEncode(message.data);
    onNotificationTapped?.call(payload);
  }

  /// Check if app was opened from notification (terminated state)
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated: ${initialMessage.messageId}');
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
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap response
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }

  /// Get FCM token
  Future<String?> getToken() async {
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
      await _saveTokenToFirestore(userId, token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (_currentUserId != null) {
        _saveTokenToFirestore(_currentUserId!, newToken);
      }
    });
  }

  /// Unregister FCM token (call on logout)
  Future<void> unregisterForUser() async {
    final userId = _currentUserId;
    final token = await getToken();
    if (userId != null && token != null) {
      await _deleteTokenFromFirestore(userId, token);
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
      debugPrint('FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
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
      debugPrint('FCM token deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
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
      final prefs = <String, dynamic>{};
      if (push != null) prefs['push'] = push;
      if (email != null) prefs['email'] = email;
      if (sound != null) prefs['sound'] = sound;
      if (vibration != null) prefs['vibration'] = vibration;
      if (messages != null) prefs['messages'] = messages;
      if (matches != null) prefs['matches'] = matches;
      if (subscriptions != null) prefs['subscriptions'] = subscriptions;

      if (prefs.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set(
          {'notificationPrefs': prefs},
          SetOptions(merge: true),
        );
        debugPrint('Notification preferences updated for user: $userId');
      }
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
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

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
