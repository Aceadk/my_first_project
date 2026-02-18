import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database_platform_interface/firebase_database_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';
import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeMatchService', () {
    late DatabasePlatform originalDatabasePlatform;

    setUpAll(() async {
      setupFirebaseAnalyticsMocks();
      await Firebase.initializeApp();
      originalDatabasePlatform = DatabasePlatform.instance;
    });

    tearDown(() {
      RealtimeMatchService.instance.stopListening();
    });

    tearDownAll(() {
      DatabasePlatform.instance = originalDatabasePlatform;
    });

    test('singleton instance is available', () {
      expect(RealtimeMatchService.instance, isA<RealtimeMatchService>());
    });

    test('fromRtdb maps defaults when fields are missing', () {
      final notification = RealtimeMatchNotification.fromRtdb('match-default', {
        'otherUserId': 'user-2',
      });

      expect(notification.matchId, 'match-default');
      expect(notification.otherUserId, 'user-2');
      expect(notification.otherUserName, 'Someone');
      expect(notification.otherUserPhotoUrl, isNull);
      expect(notification.createdAt, 0);
    });

    test(
      'default Firebase stream factory maps child events and remove callback',
      () async {
        final platformEvents =
            StreamController<DatabaseEventPlatform>.broadcast();
        final observedPaths = <String>[];
        final removedKeys = <String>[];
        final notifications = <RealtimeMatchNotification>[];

        DatabasePlatform.instance = _FakeDatabasePlatform(
          eventStreamFactory: (path) {
            observedPaths.add(path);
            return platformEvents.stream;
          },
          onRemove: removedKeys.add,
        );

        final sub = RealtimeMatchService.instance.onNewMatch.listen(
          notifications.add,
        );

        RealtimeMatchService.instance.startListening('default-user');

        platformEvents.add(
          _FakeDatabaseEventPlatform(
            snapshot: _FakeDataSnapshotPlatform(
              ref: _FakeDatabaseReferencePlatform(
                database: DatabasePlatform.instance,
                pathValue: 'users/default-user/newMatches/match-default',
                eventStreamFactory: (_) =>
                    const Stream<DatabaseEventPlatform>.empty(),
                onRemove: removedKeys.add,
              ),
              key: 'match-default',
              value: <String, dynamic>{
                'otherUserId': 'other-1',
                'otherUserName': 'Morgan',
                'otherUserPhotoUrl': 'https://example.com/morgan.jpg',
                'createdAt': 123,
              },
            ),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(observedPaths, ['users/default-user/newMatches']);
        expect(notifications, hasLength(1));
        expect(notifications.first.matchId, 'match-default');
        expect(notifications.first.otherUserName, 'Morgan');
        expect(removedKeys, ['match-default']);

        await sub.cancel();
        await platformEvents.close();
      },
    );

    test(
      'startListening emits notification and clears source record',
      () async {
        final events = StreamController<RealtimeChildAddedEvent>.broadcast();
        final notifications = <RealtimeMatchNotification>[];
        final removed = <String>[];
        String? listenedPath;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (path) {
            listenedPath = path;
            return events.stream;
          },
        );

        final sub = service.onNewMatch.listen(notifications.add);

        service.startListening('user-1');
        expect(listenedPath, 'users/user-1/newMatches');

        events.add(
          RealtimeChildAddedEvent(
            key: 'match-1',
            value: {
              'otherUserId': 'user-2',
              'otherUserName': 'Alex',
              'otherUserPhotoUrl': 'https://example.com/alex.jpg',
              'createdAt': 42,
            },
            remove: () async {
              removed.add('match-1');
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(notifications, hasLength(1));
        expect(notifications.first.matchId, 'match-1');
        expect(notifications.first.otherUserId, 'user-2');
        expect(notifications.first.otherUserName, 'Alex');
        expect(
          notifications.first.otherUserPhotoUrl,
          'https://example.com/alex.jpg',
        );
        expect(notifications.first.createdAt, 42);
        expect(removed, ['match-1']);

        await sub.cancel();
        await events.close();
        service.dispose();
      },
    );

    test(
      'ignores malformed events and handles remove failures safely',
      () async {
        final events = StreamController<RealtimeChildAddedEvent>.broadcast();
        final notifications = <RealtimeMatchNotification>[];
        var removeAttempts = 0;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (_) => events.stream,
        );

        final sub = service.onNewMatch.listen(notifications.add);
        service.startListening('user-1');

        events.add(
          RealtimeChildAddedEvent(
            key: null,
            value: {'otherUserId': 'user-2'},
            remove: () async {},
          ),
        );
        events.add(
          RealtimeChildAddedEvent(
            key: 'match-bad',
            value: 'not-a-map',
            remove: () async {},
          ),
        );
        events.add(
          RealtimeChildAddedEvent(
            key: 'match-2',
            value: {
              'otherUserId': 'user-9',
              'otherUserName': 'Jamie',
              'createdAt': 100,
            },
            remove: () async {
              removeAttempts++;
              throw Exception('remove failed');
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(notifications, hasLength(1));
        expect(notifications.first.matchId, 'match-2');
        expect(removeAttempts, 1);

        await sub.cancel();
        await events.close();
        service.dispose();
      },
    );

    test(
      'startListening is idempotent for same user and switches cleanly',
      () async {
        var firstCancelCalls = 0;
        final firstController =
            StreamController<RealtimeChildAddedEvent>.broadcast(
              onCancel: () {
                firstCancelCalls++;
              },
            );
        final secondController =
            StreamController<RealtimeChildAddedEvent>.broadcast();
        var listenCalls = 0;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (path) {
            listenCalls++;
            if (path.contains('user-1')) {
              return firstController.stream;
            }
            return secondController.stream;
          },
        );

        service.startListening('user-1');
        service.startListening('user-1');
        expect(listenCalls, 1);

        service.startListening('user-2');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(listenCalls, 2);
        expect(firstCancelCalls, 1);

        service.stopListening();

        await firstController.close();
        await secondController.close();
        service.dispose();
      },
    );

    test('listening state is observable and dispose is idempotent', () async {
      final events = StreamController<RealtimeChildAddedEvent>.broadcast();
      final service = RealtimeMatchService.test(
        childAddedStreamFactory: (_) => events.stream,
      );

      expect(service.isListening, isFalse);
      expect(service.currentUserId, isNull);
      expect(service.isDisposed, isFalse);

      service.startListening('user-1');
      expect(service.isListening, isTrue);
      expect(service.currentUserId, 'user-1');

      service.stopListening();
      expect(service.isListening, isFalse);
      expect(service.currentUserId, isNull);

      service.dispose();
      expect(service.isDisposed, isTrue);
      expect(service.isListening, isFalse);

      // Must stay safe on repeated dispose calls.
      service.dispose();
      expect(service.isDisposed, isTrue);

      await events.close();
    });

    test('startListening after dispose is ignored safely', () async {
      final events = StreamController<RealtimeChildAddedEvent>.broadcast();
      var listenCalls = 0;

      final service = RealtimeMatchService.test(
        childAddedStreamFactory: (_) {
          listenCalls++;
          return events.stream;
        },
      );

      service.dispose();
      service.startListening('user-1');

      expect(service.isDisposed, isTrue);
      expect(service.isListening, isFalse);
      expect(service.currentUserId, isNull);
      expect(listenCalls, 0);

      await events.close();
    });

    test('onError callback consumes stream errors without crashing', () async {
      final events = StreamController<RealtimeChildAddedEvent>.broadcast();
      final notifications = <RealtimeMatchNotification>[];

      final service = RealtimeMatchService.test(
        childAddedStreamFactory: (_) => events.stream,
      );
      final sub = service.onNewMatch.listen(notifications.add);

      service.startListening('user-1');
      events.addError(Exception('listener failure'));
      events.add(
        RealtimeChildAddedEvent(
          key: 'match-3',
          value: {
            'otherUserId': 'user-3',
            'otherUserName': 'Taylor',
            'createdAt': 111,
          },
          remove: () async {},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifications, hasLength(1));
      expect(notifications.first.matchId, 'match-3');

      await sub.cancel();
      await events.close();
      service.dispose();
    });
  });
}

class _FakeDatabasePlatform
    with MockPlatformInterfaceMixin
    implements DatabasePlatform {
  _FakeDatabasePlatform({
    required this.eventStreamFactory,
    required this.onRemove,
  });

  final Stream<DatabaseEventPlatform> Function(String path) eventStreamFactory;
  final void Function(String key) onRemove;

  @override
  FirebaseApp? get app => Firebase.app();

  @override
  String? get databaseURL => 'https://example.com';

  @override
  DatabasePlatform delegateFor({
    required FirebaseApp app,
    String? databaseURL,
  }) {
    return this;
  }

  @override
  Map<String, Object?> getChannelArguments([Map<String, Object?>? other]) {
    return <String, Object?>{};
  }

  @override
  void useDatabaseEmulator(String host, int port) {}

  @override
  DatabaseReferencePlatform ref([String? path]) {
    return _FakeDatabaseReferencePlatform(
      database: this,
      pathValue: path ?? '',
      eventStreamFactory: eventStreamFactory,
      onRemove: onRemove,
    );
  }

  @override
  void setPersistenceEnabled(bool enabled) {}

  @override
  void setPersistenceCacheSizeBytes(int cacheSize) {}

  @override
  void setLoggingEnabled(bool enabled) {}

  @override
  Future<void> goOnline() async {}

  @override
  Future<void> goOffline() async {}

  @override
  Future<void> purgeOutstandingWrites() async {}
}

class _FakeDatabaseReferencePlatform
    with MockPlatformInterfaceMixin
    implements DatabaseReferencePlatform {
  _FakeDatabaseReferencePlatform({
    required this.database,
    required this.pathValue,
    required this.eventStreamFactory,
    required this.onRemove,
  });

  @override
  final DatabasePlatform database;

  final String pathValue;
  final Stream<DatabaseEventPlatform> Function(String path) eventStreamFactory;
  final void Function(String key) onRemove;

  @override
  String get path => pathValue;

  @override
  DatabaseReferencePlatform get ref => this;

  @override
  Stream<DatabaseEventPlatform> observe(
    QueryModifiers modifiers,
    DatabaseEventType eventType,
  ) {
    if (eventType == DatabaseEventType.childAdded) {
      return eventStreamFactory(pathValue);
    }
    return const Stream<DatabaseEventPlatform>.empty();
  }

  @override
  Stream<DatabaseEventPlatform> onChildAdded(QueryModifiers modifiers) {
    return observe(modifiers, DatabaseEventType.childAdded);
  }

  @override
  Stream<DatabaseEventPlatform> onChildRemoved(QueryModifiers modifiers) {
    return observe(modifiers, DatabaseEventType.childRemoved);
  }

  @override
  Stream<DatabaseEventPlatform> onChildChanged(QueryModifiers modifiers) {
    return observe(modifiers, DatabaseEventType.childChanged);
  }

  @override
  Stream<DatabaseEventPlatform> onChildMoved(QueryModifiers modifiers) {
    return observe(modifiers, DatabaseEventType.childMoved);
  }

  @override
  Stream<DatabaseEventPlatform> onValue(QueryModifiers modifiers) {
    return observe(modifiers, DatabaseEventType.value);
  }

  @override
  Future<DataSnapshotPlatform> get(QueryModifiers modifiers) async {
    return _FakeDataSnapshotPlatform(ref: this, key: key, value: null);
  }

  @override
  Future<void> keepSynced(QueryModifiers modifiers, bool value) async {}

  @override
  DatabaseReferencePlatform child(String path) {
    final nextPath = pathValue.isEmpty ? path : '$pathValue/$path';
    return _FakeDatabaseReferencePlatform(
      database: database,
      pathValue: nextPath,
      eventStreamFactory: eventStreamFactory,
      onRemove: onRemove,
    );
  }

  @override
  DatabaseReferencePlatform? get parent {
    if (pathValue.isEmpty || !pathValue.contains('/')) {
      return null;
    }
    final segments = pathValue.split('/')..removeLast();
    return _FakeDatabaseReferencePlatform(
      database: database,
      pathValue: segments.join('/'),
      eventStreamFactory: eventStreamFactory,
      onRemove: onRemove,
    );
  }

  @override
  DatabaseReferencePlatform root() {
    return _FakeDatabaseReferencePlatform(
      database: database,
      pathValue: '',
      eventStreamFactory: eventStreamFactory,
      onRemove: onRemove,
    );
  }

  @override
  String? get key => pathValue.isEmpty ? null : pathValue.split('/').last;

  @override
  DatabaseReferencePlatform push() {
    return child('auto-id');
  }

  @override
  Future<void> set(Object? value) async {
    if (value == null) {
      final currentKey = key;
      if (currentKey != null) {
        onRemove(currentKey);
      }
    }
  }

  @override
  Future<void> setWithPriority(Object? value, Object? priority) async {}

  @override
  Future<void> update(Map<String, Object?> value) async {}

  @override
  Future<void> setPriority(Object? priority) async {}

  @override
  Future<void> remove() async {
    final currentKey = key;
    if (currentKey != null) {
      onRemove(currentKey);
    }
  }

  @override
  Future<TransactionResultPlatform> runTransaction(
    TransactionHandler transactionHandler, {
    bool applyLocally = true,
  }) async {
    return _FakeTransactionResultPlatform(
      snapshot: _FakeDataSnapshotPlatform(ref: this, key: key, value: null),
    );
  }

  @override
  OnDisconnectPlatform onDisconnect() {
    return _FakeOnDisconnectPlatform(database: database, ref: this);
  }
}

class _FakeDataSnapshotPlatform extends DataSnapshotPlatform {
  _FakeDataSnapshotPlatform({
    required DatabaseReferencePlatform ref,
    String? key,
    Object? value,
  }) : super(ref, <String, dynamic>{'key': key, 'value': value});

  @override
  DataSnapshotPlatform child(String childPath) {
    return _FakeDataSnapshotPlatform(ref: ref, key: childPath, value: null);
  }

  @override
  Iterable<DataSnapshotPlatform> get children => const <DataSnapshotPlatform>[];
}

class _FakeDatabaseEventPlatform extends DatabaseEventPlatform {
  _FakeDatabaseEventPlatform({required DataSnapshotPlatform snapshot})
    : _snapshot = snapshot,
      super(<String, dynamic>{'eventType': 'childAdded'});

  final DataSnapshotPlatform _snapshot;

  @override
  DataSnapshotPlatform get snapshot => _snapshot;
}

class _FakeOnDisconnectPlatform extends OnDisconnectPlatform {
  _FakeOnDisconnectPlatform({required super.database, required super.ref});

  @override
  Future<void> set(Object? value) async {}

  @override
  Future<void> setWithPriority(Object? value, Object? priority) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> update(Map<String, Object?> value) async {}
}

class _FakeTransactionResultPlatform extends TransactionResultPlatform {
  _FakeTransactionResultPlatform({required DataSnapshotPlatform snapshot})
    : _snapshot = snapshot,
      super(true);

  final DataSnapshotPlatform _snapshot;

  @override
  DataSnapshotPlatform get snapshot => _snapshot;
}
