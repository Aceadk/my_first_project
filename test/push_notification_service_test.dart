import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/core/services/push_notification_service.dart';
import 'core/services/firebase_mocks.dart';

void main() {
  group('PushNotificationService', () {
    late PushNotificationService service;

    setUpAll(() async {
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
      service = PushNotificationService.instance;
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service.clearTestOverrides();
    });

    tearDown(() {
      service.clearTestOverrides();
    });

    test('singleton instance is accessible', () {
      final a = PushNotificationService.instance;
      final b = PushNotificationService.instance;

      expect(identical(a, b), isTrue);
    });

    test('background handler completes without throwing', () async {
      const message = RemoteMessage(messageId: 'msg-1', data: {'type': 'chat'});

      await firebaseMessagingBackgroundHandler(message);
    });

    test('buildNotificationPrefs includes only non-null values', () {
      final prefs = PushNotificationService.buildNotificationPrefs(
        push: true,
        sound: false,
        matches: true,
      );

      expect(prefs, <String, dynamic>{
        'push': true,
        'sound': false,
        'matches': true,
      });
    });

    test('buildNotificationPrefs includes all supported values', () {
      final prefs = PushNotificationService.buildNotificationPrefs(
        push: true,
        email: false,
        sound: true,
        vibration: false,
        messages: true,
        matches: false,
        subscriptions: true,
      );

      expect(prefs, <String, dynamic>{
        'push': true,
        'email': false,
        'sound': true,
        'vibration': false,
        'messages': true,
        'matches': false,
        'subscriptions': true,
      });
    });

    test(
      'notification preference defaults are sound/vibration enabled',
      () async {
        final sound = await service.getSoundEnabledForTest();
        final vibration = await service.getVibrationEnabledForTest();

        expect(sound, isTrue);
        expect(vibration, isTrue);
      },
    );

    test(
      'notification preference reads persisted sound/vibration values',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications_sound': false,
          'notifications_vibration': false,
        });

        final sound = await service.getSoundEnabledForTest();
        final vibration = await service.getVibrationEnabledForTest();

        expect(sound, isFalse);
        expect(vibration, isFalse);
      },
    );

    test('handleMessageOpenedAppForTest forwards encoded payload', () {
      String? received;
      service.onNotificationTapped = (payload) => received = payload;

      service.handleMessageOpenedAppForTest(
        const RemoteMessage(
          messageId: 'msg-opened',
          data: {'type': 'chat', 'matchId': 'm-1'},
        ),
      );

      expect(received, '{"type":"chat","matchId":"m-1"}');
    });

    test('handleNotificationResponseForTest forwards payload', () {
      String? received;
      service.onNotificationTapped = (payload) => received = payload;

      service.handleNotificationResponseForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{"route":"messages"}',
        ),
      );

      expect(received, '{"route":"messages"}');
    });

    test(
      'handleForegroundMessageForTest triggers foreground callback',
      () async {
        RemoteMessage? received;
        service.onForegroundMessage = (message) => received = message;

        service.handleForegroundMessageForTest(
          const RemoteMessage(messageId: 'fg-1', data: {'type': 'presence'}),
        );
        await Future<void>.delayed(Duration.zero);

        expect(received?.messageId, 'fg-1');
      },
    );

    test(
      'checkInitialMessageForTest forwards payload when initial message exists',
      () async {
        String? received;
        service.onNotificationTapped = (payload) => received = payload;
        service.initialMessageProviderOverride = () async =>
            const RemoteMessage(
              messageId: 'initial-1',
              data: {'type': 'initial', 'deepLink': '/matches'},
            );

        await service.checkInitialMessageForTest();

        expect(received, '{"type":"initial","deepLink":"/matches"}');
      },
    );

    test('registerForUser persists initial token and refresh token', () async {
      final saved = <String>[];
      final refreshController = StreamController<String>();
      addTearDown(refreshController.close);

      service.tokenProviderOverride = () async => 'tok-initial';
      service.tokenRefreshOverride = refreshController.stream;
      service.saveTokenOverride = (userId, token) async =>
          saved.add('$userId:$token');

      await service.registerForUser('user-1');
      refreshController.add('tok-refresh');
      await Future<void>.delayed(Duration.zero);

      expect(saved, contains('user-1:tok-initial'));
      expect(saved, contains('user-1:tok-refresh'));
    });

    test('unregisterForUser deletes token and clears current user', () async {
      String? deleted;
      var prefsSaveCalled = false;
      service.setCurrentUserIdForTest('user-2');
      service.tokenProviderOverride = () async => 'tok-delete';
      service.deleteTokenOverride = (userId, token) async =>
          deleted = '$userId:$token';
      service.saveNotificationPrefsOverride = (userId, prefs) async {
        prefsSaveCalled = true;
      };

      await service.unregisterForUser();
      await service.updateNotificationPreferences(push: true);

      expect(deleted, 'user-2:tok-delete');
      expect(prefsSaveCalled, isFalse);
    });

    test(
      'updateNotificationPreferences is a no-op when user is null',
      () async {
        var called = false;
        service.setCurrentUserIdForTest(null);
        service.saveNotificationPrefsOverride = (userId, prefs) async =>
            called = true;

        await service.updateNotificationPreferences(push: true, email: false);

        expect(called, isFalse);
      },
    );

    test(
      'updateNotificationPreferences persists merged non-null fields',
      () async {
        String? savedUserId;
        Map<String, dynamic>? savedPrefs;
        service.setCurrentUserIdForTest('user-3');
        service.saveNotificationPrefsOverride = (userId, prefs) async {
          savedUserId = userId;
          savedPrefs = prefs;
        };

        await service.updateNotificationPreferences(
          push: true,
          email: false,
          sound: true,
          matches: true,
        );

        expect(savedUserId, 'user-3');
        expect(savedPrefs, {
          'push': true,
          'email': false,
          'sound': true,
          'matches': true,
        });
      },
    );

    test(
      'updateNotificationPreferences skips persistence when all fields null',
      () async {
        var called = false;
        service.setCurrentUserIdForTest('user-4');
        service.saveNotificationPrefsOverride = (userId, prefs) async =>
            called = true;

        await service.updateNotificationPreferences();

        expect(called, isFalse);
      },
    );

    test(
      'showNotification uses override and respects sound/vibration prefs',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications_sound': false,
          'notifications_vibration': true,
        });

        Map<String, Object?>? captured;
        service.showLocalNotificationOverride =
            ({
              required int id,
              String? title,
              String? body,
              required bool soundEnabled,
              required bool vibrationEnabled,
              String? payload,
            }) async {
              captured = {
                'id': id,
                'title': title,
                'body': body,
                'soundEnabled': soundEnabled,
                'vibrationEnabled': vibrationEnabled,
                'payload': payload,
              };
            };

        await service.showNotification(
          id: 99,
          title: 'Hello',
          body: 'World',
          payload: '{"route":"discover"}',
        );

        expect(captured?['id'], 99);
        expect(captured?['title'], 'Hello');
        expect(captured?['body'], 'World');
        expect(captured?['soundEnabled'], isFalse);
        expect(captured?['vibrationEnabled'], isTrue);
        expect(captured?['payload'], '{"route":"discover"}');
      },
    );

    test(
      'initialize executes all setup stages in order via overrides',
      () async {
        final calls = <String>[];
        service.requestPermissionOverride = () async => calls.add('permission');
        service.initializeLocalNotificationsOverride = () async =>
            calls.add('local');
        service.createNotificationChannelOverride = () async =>
            calls.add('channel');
        service.setupMessageHandlersOverride = () => calls.add('handlers');
        service.printFcmTokenOverride = () async => calls.add('token');

        await service.initialize();

        expect(calls, ['permission', 'local', 'channel', 'handlers', 'token']);
      },
    );

    test(
      'checkInitialMessageForTest no-ops when there is no initial message',
      () async {
        String? received;
        service.onNotificationTapped = (payload) => received = payload;
        service.initialMessageProviderOverride = () async => null;

        await service.checkInitialMessageForTest();

        expect(received, isNull);
      },
    );

    test(
      'handleForegroundMessageForTest sends local notification when present',
      () async {
        Map<String, Object?>? shown;
        String? receivedPayload;
        service.showLocalNotificationOverride =
            ({
              required int id,
              String? title,
              String? body,
              required bool soundEnabled,
              required bool vibrationEnabled,
              String? payload,
            }) async {
              shown = {
                'id': id,
                'title': title,
                'body': body,
                'soundEnabled': soundEnabled,
                'vibrationEnabled': vibrationEnabled,
                'payload': payload,
              };
            };
        service.onForegroundMessage = (message) {
          receivedPayload = message.data['type'] as String?;
        };

        service.handleForegroundMessageForTest(
          const RemoteMessage(
            messageId: 'fg-with-notification',
            data: {'type': 'message', 'matchId': 'm-2'},
            notification: RemoteNotification(title: 'New message', body: 'Hi'),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(receivedPayload, 'message');
        expect(shown?['title'], 'New message');
        expect(shown?['body'], 'Hi');
        expect(shown?['payload'], '{"type":"message","matchId":"m-2"}');
      },
    );

    test('registerForUser with null token does not persist token', () async {
      var saved = false;
      service.tokenProviderOverride = () async => null;
      service.saveTokenOverride = (userId, token) async => saved = true;
      service.tokenRefreshOverride = const Stream<String>.empty();

      await service.registerForUser('user-null');

      expect(saved, isFalse);
    });

    test(
      'registerForUser falls back to Firestore token persistence path',
      () async {
        final refreshController = StreamController<String>();
        addTearDown(refreshController.close);

        service.tokenProviderOverride = () async => 'tok-firestore';
        service.tokenRefreshOverride = refreshController.stream;

        await service.registerForUser('user-fs');
        refreshController.add('tok-firestore-refresh');
        await Future<void>.delayed(Duration.zero);
      },
    );

    test('unregisterForUser with null user/token is a no-op', () async {
      var deleted = false;
      service.setCurrentUserIdForTest(null);
      service.tokenProviderOverride = () async => null;
      service.deleteTokenOverride = (userId, token) async => deleted = true;

      await service.unregisterForUser();

      expect(deleted, isFalse);
    });

    test('unregisterForUser falls back to Firestore delete path', () async {
      service.setCurrentUserIdForTest('user-fs');
      service.tokenProviderOverride = () async => 'tok-firestore';

      await service.unregisterForUser();
    });

    test('updateNotificationPreferences swallows persistence errors', () async {
      service.setCurrentUserIdForTest('user-5');
      service.saveNotificationPrefsOverride = (userId, prefs) async {
        throw Exception('save failed');
      };

      await service.updateNotificationPreferences(push: true, messages: true);
    });

    test(
      'updateNotificationPreferences falls back to Firestore persistence path',
      () async {
        service.setCurrentUserIdForTest('user-fs');
        await service.updateNotificationPreferences(
          push: true,
          vibration: true,
          subscriptions: false,
        );
      },
    );

    test('subscribe/unsubscribe topic routes through overrides', () async {
      final calls = <String>[];
      service.subscribeToTopicOverride = (topic) async =>
          calls.add('sub:$topic');
      service.unsubscribeFromTopicOverride = (topic) async =>
          calls.add('unsub:$topic');

      await service.subscribeToTopic('weekly_picks');
      await service.unsubscribeFromTopic('weekly_picks');

      expect(calls, ['sub:weekly_picks', 'unsub:weekly_picks']);
    });

    test('cancel notification paths route through overrides', () async {
      final calls = <String>[];
      service.cancelNotificationOverride = (id) async =>
          calls.add('cancel:$id');
      service.cancelAllNotificationsOverride = () async =>
          calls.add('cancelAll');

      await service.cancelNotification(7);
      await service.cancelAllNotifications();

      expect(calls, ['cancel:7', 'cancelAll']);
    });
  });
}
