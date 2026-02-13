import 'package:crushhour/core/security/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};
  final manager = SessionManager.instance;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final args = _mapArgs(call.arguments);
          final key = args['key'] as String?;
          final value = args['value'] as String?;

          switch (call.method) {
            case 'read':
              return key == null ? null : storage[key];
            case 'write':
              if (key != null && value != null) {
                storage[key] = value;
              }
              return null;
            case 'delete':
              if (key != null) {
                storage.remove(key);
              }
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'containsKey':
              return key != null && storage.containsKey(key);
          }
          return null;
        });
  });

  tearDown(() async {
    manager.pause();
    manager.onSessionExpired = null;
    manager.timeoutDuration = const Duration(minutes: 30);
    await manager.clearSession();
    storage.remove('session_timeout_enabled');
  });

  tearDownAll(() async {
    manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('SessionManager', () {
    test('initialize records activity and session remains valid', () async {
      await manager.initialize(
        timeout: const Duration(seconds: 1),
        enabled: true,
      );

      expect(manager.isEnabled, isTrue);
      expect(storage['last_activity_timestamp'], isNotNull);
      expect(await manager.isSessionValid(), isTrue);
      expect(manager.remainingTime, isNotNull);
    });

    test(
      'initialize triggers onExpired when stored session already expired',
      () async {
        storage['last_activity_timestamp'] = DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String();

        var expiredCalled = false;
        await manager.initialize(
          timeout: const Duration(seconds: 1),
          onExpired: () => expiredCalled = true,
        );

        expect(expiredCalled, isTrue);
      },
    );

    test(
      'pause prevents timeout and resume can expire based on elapsed time',
      () async {
        var expiredCount = 0;
        await manager.initialize(
          timeout: const Duration(milliseconds: 80),
          onExpired: () => expiredCount++,
        );

        manager.pause();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(expiredCount, 0);

        manager.resume();
        expect(expiredCount, 1);
      },
    );

    test('setEnabled(false) disables timeout and stores preference', () async {
      await manager.initialize(timeout: const Duration(milliseconds: 50));
      await manager.setEnabled(false);

      expect(manager.isEnabled, isFalse);
      expect(storage['session_timeout_enabled'], 'false');
      expect(await manager.isSessionValid(), isTrue);
      expect(manager.remainingTime, isNull);
    });

    test('clearSession deletes persisted last activity timestamp', () async {
      await manager.initialize(timeout: const Duration(seconds: 1));
      expect(storage['last_activity_timestamp'], isNotNull);

      await manager.clearSession();

      expect(storage.containsKey('last_activity_timestamp'), isFalse);
    });

    testWidgets(
      'ActivityTrackingMixin records activity on init and user action',
      (tester) async {
        await manager.setEnabled(true);
        storage.clear();

        await tester.pumpWidget(const MaterialApp(home: _TrackedWidget()));

        final firstTimestamp = storage['last_activity_timestamp'];
        expect(firstTimestamp, isNotNull);

        await tester.pump(const Duration(milliseconds: 2));
        final state = tester.state<_TrackedWidgetState>(
          find.byType(_TrackedWidget),
        );
        state.recordUserActivity();
        await tester.pump();

        final secondTimestamp = storage['last_activity_timestamp'];
        expect(secondTimestamp, isNotNull);
        expect(secondTimestamp, isNot(equals(firstTimestamp)));

        // testWidgets checks pending timers before tearDown hooks execute.
        manager.pause();
      },
    );
  });
}

Map<String, dynamic> _mapArgs(dynamic args) {
  if (args is Map) {
    return args.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

class _TrackedWidget extends StatefulWidget {
  const _TrackedWidget();

  @override
  State<_TrackedWidget> createState() => _TrackedWidgetState();
}

class _TrackedWidgetState extends State<_TrackedWidget>
    with ActivityTrackingMixin<_TrackedWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: recordUserActivity,
      child: const SizedBox(width: 40, height: 40),
    );
  }
}
