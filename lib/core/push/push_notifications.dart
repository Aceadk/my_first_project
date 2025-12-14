import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../app_logger.dart';

class PushNotifications {
  PushNotifications({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenSub;
  String? _cachedToken;
  String? _currentUserId;

  Future<void> initializeHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Push message received';
      AppLogger.logError(
        'PushNotifications.onMessage',
        title,
        message.notification?.body == null ? null : StackTrace.current,
      );
    });
  }

  Future<void> registerDeviceToken(String userId) async {
    if (userId.isEmpty) throw Exception('Missing user id');
    _currentUserId = userId;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      throw Exception('Notifications permission not granted.');
    }

    final token = await _messaging.getToken();
    if (token == null) throw Exception('Could not obtain FCM token.');

    await _persistToken(userId, token);
    _listenForRefreshes();
  }

  Future<void> unregisterDeviceToken(String userId) async {
    final token = _cachedToken ?? await _messaging.getToken();
    if (token != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete()
          .catchError((_) {});
    }
    await _messaging.deleteToken();
    _cachedToken = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  Future<void> _persistToken(String userId, String token) async {
    _cachedToken = token;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
      'subscriptionPlan': null,
    });
  }

  void _listenForRefreshes() {
    _tokenSub ??= _messaging.onTokenRefresh.listen((newToken) async {
      final uid = _currentUserId;
      if (uid == null) return;
      try {
        await _persistToken(uid, newToken);
      } catch (e, stack) {
        AppLogger.logError('PushNotifications.onTokenRefresh', e, stack);
      }
    });
  }
}
