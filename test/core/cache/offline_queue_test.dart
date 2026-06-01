import 'package:crushhour/core/cache/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CHAT-RT-003 — offline queue / sync-recovery policy: strict FIFO ordering,
/// transient-vs-bounded failure handling, idempotent enqueue, and observable
/// capacity eviction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  OfflineActionQueue newQueue() => OfflineActionQueue(
    // Tiny delays keep the retry-driven tests fast.
    retryBaseDelay: const Duration(milliseconds: 5),
    maxRetryDelay: const Duration(milliseconds: 20),
  );

  PendingAction action(
    String id, {
    String type = ActionTypes.sendMessage,
    String? dedupeKey,
    int maxRetries = 3,
  }) {
    return PendingAction(
      id: id,
      type: type,
      payload: {'id': id},
      createdAt: DateTime(2026, 6, 1, 10, 0),
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
    );
  }

  test('processes actions in strict FIFO order on success', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    final processed = <String>[];
    queue.registerHandler(ActionTypes.sendMessage, (a) async {
      processed.add(a.id);
      return ActionResult.success;
    });

    await queue.enqueue(action('m1'));
    await queue.enqueue(action('m2'));
    await queue.enqueue(action('m3'));
    await queue.processAll();

    expect(processed, ['m1', 'm2', 'm3']);
    expect(queue.status.pendingCount, 0);
  });

  test('a transiently failing head blocks later actions until it succeeds',
      () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    final processed = <String>[];
    var m1Attempts = 0;
    queue.registerHandler(ActionTypes.sendMessage, (a) async {
      if (a.id == 'm1') {
        m1Attempts++;
        if (m1Attempts < 3) {
          throw Exception('network down'); // transient
        }
      }
      processed.add(a.id);
      return ActionResult.success;
    });

    await queue.enqueue(action('m1'));
    await queue.enqueue(action('m2'));
    await queue.processAll();

    // Wait out the backoff-driven retries.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // m1 must be delivered before m2 despite failing twice first.
    expect(processed, ['m1', 'm2']);
    expect(m1Attempts, 3);
    expect(queue.status.pendingCount, 0);
  });

  test('transient failures do not consume the retry budget', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    var attempts = 0;
    queue.registerHandler(ActionTypes.sendMessage, (a) async {
      attempts++;
      if (attempts < 6) throw Exception('still offline');
      return ActionResult.success;
    });

    // maxRetries is 3, but transient throws should be retried well past that.
    await queue.enqueue(action('m1', maxRetries: 3));
    await queue.processAll();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(attempts, 6);
    expect(queue.status.pendingCount, 0);
  });

  test('retryable result dead-letters after exhausting maxRetries, then '
      'continues', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    final processed = <String>[];
    var m1Attempts = 0;
    queue.registerHandler(ActionTypes.sendMessage, (a) async {
      if (a.id == 'm1') {
        m1Attempts++;
        return ActionResult.retryable; // always asks to retry
      }
      processed.add(a.id);
      return ActionResult.success;
    });

    await queue.enqueue(action('m1', maxRetries: 2));
    await queue.enqueue(action('m2'));
    await queue.processAll();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // m1 attempted at retryCount 0,1,2 (3 total) then dead-lettered; m2 follows.
    expect(m1Attempts, 3);
    expect(processed, ['m2']);
    expect(queue.status.pendingCount, 0);
  });

  test('failed result drops immediately without retrying', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    final processed = <String>[];
    var m1Attempts = 0;
    queue.registerHandler(ActionTypes.sendMessage, (a) async {
      if (a.id == 'm1') {
        m1Attempts++;
        return ActionResult.failed;
      }
      processed.add(a.id);
      return ActionResult.success;
    });

    await queue.enqueue(action('m1'));
    await queue.enqueue(action('m2'));
    await queue.processAll();

    expect(m1Attempts, 1);
    expect(processed, ['m2']);
    expect(queue.status.pendingCount, 0);
  });

  test('enqueue is idempotent on dedupeKey', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);

    await queue.enqueue(action('first', dedupeKey: 'send:match-1:hello'));
    await queue.enqueue(action('second', dedupeKey: 'send:match-1:hello'));

    expect(queue.status.pendingCount, 1);
  });

  test('capacity eviction is observable via droppedCount', () async {
    final queue = newQueue();
    addTearDown(queue.dispose);

    // Fill beyond the 500-entry cap; the oldest is evicted and counted.
    for (var i = 0; i < 501; i++) {
      await queue.enqueue(action('m$i', dedupeKey: 'k$i'));
    }

    expect(queue.status.pendingCount, 500);
    expect(queue.status.droppedCount, 1);
    expect(queue.status.hasDropped, isTrue);
  });

  test('persists and reloads actions (including dedupeKey) across restart',
      () async {
    final queue = newQueue();
    addTearDown(queue.dispose);
    await queue.enqueue(action('m1', dedupeKey: 'k1'));
    await queue.enqueue(action('m2', dedupeKey: 'k2'));

    final reloaded = newQueue();
    addTearDown(reloaded.dispose);
    await reloaded.load();

    expect(reloaded.status.pendingCount, 2);
    // Re-enqueuing a persisted dedupeKey is still a no-op after reload.
    await reloaded.enqueue(action('m1-dup', dedupeKey: 'k1'));
    expect(reloaded.status.pendingCount, 2);
  });

  test('PendingAction.fromJson backfills dedupeKey from id for legacy data',
      () {
    final legacy = {
      'id': 'legacy-1',
      'type': ActionTypes.sendMessage,
      'payload': {'x': 1},
      'createdAt': DateTime(2026, 6, 1).toIso8601String(),
      'retryCount': 0,
      'maxRetries': 3,
      // no dedupeKey
    };
    final parsed = PendingAction.fromJson(legacy);
    expect(parsed.dedupeKey, 'legacy-1');
  });
}
