import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/domain/usecases/message_reconciler.dart';
import 'package:flutter_test/flutter_test.dart';

/// CHAT-RT-001 — delivery guarantees for the pure message reconciler:
/// dedupe, deterministic ordering, out-of-order repair, optimistic/server
/// reconciliation, and memory-cap eviction. All cases are pure (no clock/IO).
void main() {
  group('MessageReconciler.mergeServerMessages', () {
    test('orders chronologically and de-duplicates by id (server wins)',
        () {
      final existing = [
        _msg('b', sentAt: DateTime(2026, 6, 1, 10, 1)),
        _msg('a', sentAt: DateTime(2026, 6, 1, 10, 0)),
      ];
      final incoming = [
        // Duplicate id 'b' with updated read state — must replace, not append.
        _msg('b', sentAt: DateTime(2026, 6, 1, 10, 1), isRead: true),
        _msg('c', sentAt: DateTime(2026, 6, 1, 10, 2)),
      ];

      final merged = MessageReconciler.mergeServerMessages(
        existing: existing,
        incoming: incoming,
      );

      expect(merged.map((m) => m.id), ['a', 'b', 'c']);
      expect(merged.firstWhere((m) => m.id == 'b').isRead, isTrue);
    });

    test('inserts an out-of-order late message at its chronological slot', () {
      final existing = [
        _msg('m1', sentAt: DateTime(2026, 6, 1, 10, 0)),
        _msg('m3', sentAt: DateTime(2026, 6, 1, 10, 2)),
      ];
      // A message authored between m1 and m3 but delivered last.
      final incoming = [_msg('m2', sentAt: DateTime(2026, 6, 1, 10, 1))];

      final merged = MessageReconciler.mergeServerMessages(
        existing: existing,
        incoming: incoming,
      );

      expect(merged.map((m) => m.id), ['m1', 'm2', 'm3']);
    });

    test('is idempotent under replayed batches (reconnect replay)', () {
      final batch = [
        _msg('a', sentAt: DateTime(2026, 6, 1, 10, 0)),
        _msg('b', sentAt: DateTime(2026, 6, 1, 10, 1)),
      ];

      final once = MessageReconciler.mergeServerMessages(
        existing: const [],
        incoming: batch,
      );
      final twice = MessageReconciler.mergeServerMessages(
        existing: once,
        incoming: batch,
      );

      expect(twice.map((m) => m.id), ['a', 'b']);
      expect(twice.length, 2);
    });

    test('breaks equal-timestamp ties deterministically by id', () {
      final t = DateTime(2026, 6, 1, 10, 0);
      final merged = MessageReconciler.mergeServerMessages(
        existing: [_msg('z', sentAt: t), _msg('a', sentAt: t)],
        incoming: [_msg('m', sentAt: t)],
      );
      expect(merged.map((m) => m.id), ['a', 'm', 'z']);
    });

    test('does not mutate the input lists', () {
      final existing = [_msg('a', sentAt: DateTime(2026, 6, 1, 10, 1))];
      final incoming = [_msg('b', sentAt: DateTime(2026, 6, 1, 10, 0))];

      MessageReconciler.mergeServerMessages(
        existing: existing,
        incoming: incoming,
      );

      expect(existing.single.id, 'a');
      expect(incoming.single.id, 'b');
    });
  });

  group('MessageReconciler memory caps', () {
    test('capKeepingNewest drops the oldest beyond the cap', () {
      final messages = List.generate(
        5,
        (i) => _msg('m$i', sentAt: DateTime(2026, 6, 1, 10, i)),
      );
      final capped = MessageReconciler.capKeepingNewest(messages, 3);
      expect(capped.map((m) => m.id), ['m2', 'm3', 'm4']);
    });

    test('capKeepingOldest drops the newest beyond the cap', () {
      final messages = List.generate(
        5,
        (i) => _msg('m$i', sentAt: DateTime(2026, 6, 1, 10, i)),
      );
      final capped = MessageReconciler.capKeepingOldest(messages, 3);
      expect(capped.map((m) => m.id), ['m0', 'm1', 'm2']);
    });

    test('caps are no-ops when under the limit', () {
      final messages = [_msg('only', sentAt: DateTime(2026, 6, 1, 10, 0))];
      expect(MessageReconciler.capKeepingNewest(messages, 10), messages);
      expect(MessageReconciler.capKeepingOldest(messages, 10), messages);
    });
  });

  group('MessageReconciler optimistic reconciliation', () {
    test('resolves a pending message by matching server signature in window',
        () {
      final optimistic = _msg(
        'temp_1',
        fromUserId: 'me',
        content: 'hello there',
        sentAt: DateTime(2026, 6, 1, 10, 0, 0),
      );
      final serverEcho = _msg(
        'server-9',
        fromUserId: 'me',
        content: 'hello there',
        sentAt: DateTime(2026, 6, 1, 10, 0, 5), // 5s later — within window
      );

      final resolved = MessageReconciler.resolvedPendingIds(
        pending: {'temp_1': optimistic},
        confirmed: [serverEcho],
      );

      expect(resolved, {'temp_1'});
    });

    test('does not resolve when the signature match is outside the window', () {
      final optimistic = _msg(
        'temp_1',
        fromUserId: 'me',
        content: 'hello there',
        sentAt: DateTime(2026, 6, 1, 10, 0, 0),
      );
      final unrelated = _msg(
        'server-9',
        fromUserId: 'me',
        content: 'hello there',
        sentAt: DateTime(2026, 6, 1, 10, 5, 0), // 5 min later — too far
      );

      final resolved = MessageReconciler.resolvedPendingIds(
        pending: {'temp_1': optimistic},
        confirmed: [unrelated],
      );

      expect(resolved, isEmpty);
    });

    test('combineForDisplay hides the optimistic copy once confirmed', () {
      final optimistic = _msg(
        'temp_1',
        fromUserId: 'me',
        content: 'hi',
        sentAt: DateTime(2026, 6, 1, 10, 0, 0),
        sendStatus: MessageSendStatus.sending,
      );
      final serverEcho = _msg(
        'server-1',
        fromUserId: 'me',
        content: 'hi',
        sentAt: DateTime(2026, 6, 1, 10, 0, 2),
      );

      final display = MessageReconciler.combineForDisplay(
        confirmed: [serverEcho],
        pending: {'temp_1': optimistic},
      );

      expect(display.map((m) => m.id), ['server-1']);
    });

    test('combineForDisplay keeps an unconfirmed failed message visible', () {
      final failed = _msg(
        'temp_2',
        fromUserId: 'me',
        content: 'did not send',
        sentAt: DateTime(2026, 6, 1, 10, 0, 30),
        sendStatus: MessageSendStatus.failed,
      );
      final other = _msg(
        'server-1',
        fromUserId: 'them',
        content: 'unrelated',
        sentAt: DateTime(2026, 6, 1, 10, 0, 0),
      );

      final display = MessageReconciler.combineForDisplay(
        confirmed: [other],
        pending: {'temp_2': failed},
      );

      expect(display.map((m) => m.id), ['server-1', 'temp_2']);
    });

    test('combineForDisplay returns the confirmed list unchanged when empty',
        () {
      final confirmed = [_msg('a', sentAt: DateTime(2026, 6, 1, 10, 0))];
      final display = MessageReconciler.combineForDisplay(
        confirmed: confirmed,
        pending: const {},
      );
      expect(identical(display, confirmed), isTrue);
    });

    test('prunePending removes only the resolved entries', () {
      final pending = {
        'temp_keep': _msg(
          'temp_keep',
          fromUserId: 'me',
          content: 'still failing',
          sentAt: DateTime(2026, 6, 1, 10, 0, 0),
        ),
        'temp_drop': _msg(
          'temp_drop',
          fromUserId: 'me',
          content: 'delivered',
          sentAt: DateTime(2026, 6, 1, 10, 0, 0),
        ),
      };
      final confirmed = [
        _msg(
          'server-1',
          fromUserId: 'me',
          content: 'delivered',
          sentAt: DateTime(2026, 6, 1, 10, 0, 3),
        ),
      ];

      final pruned = MessageReconciler.prunePending(
        pending: pending,
        confirmed: confirmed,
      );

      expect(pruned.keys, ['temp_keep']);
    });
  });
}

Message _msg(
  String id, {
  String matchId = 'match-1',
  String fromUserId = 'me',
  String toUserId = 'them',
  String content = 'hello',
  MessageType type = MessageType.text,
  DateTime? sentAt,
  bool isRead = false,
  MessageSendStatus sendStatus = MessageSendStatus.sent,
}) {
  return Message(
    id: id,
    matchId: matchId,
    fromUserId: fromUserId,
    toUserId: toUserId,
    content: content,
    type: type,
    sentAt: sentAt ?? DateTime(2026, 6, 1, 10, 0),
    isRead: isRead,
    isDeletedForSender: false,
    sendStatus: sendStatus,
  );
}
