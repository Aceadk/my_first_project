import 'package:crushhour/data/models/message.dart';

/// Pure, deterministic helpers for merging chat message streams (CHAT-RT-001).
///
/// Real-time chat has to stay correct under conditions that a naive
/// "append the new messages to the end of the list" approach gets wrong:
///
/// * **Duplicate delivery** — the same message is replayed after a WebSocket /
///   Firestore reconnect, redelivered on multiple tabs/devices, or echoed back
///   to the sender. We must collapse duplicates by id.
/// * **Out-of-order arrival** — a message authored earlier (queued offline,
///   slow fan-out, clock skew) can be delivered *after* a newer one. Appending
///   would render it at the bottom; it has to land at its chronological slot.
/// * **Optimistic / server reconciliation** — the sender shows an optimistic
///   bubble with a temporary id; the server later persists the same message
///   under a different id. Both must not appear at once.
/// * **Non-deterministic ordering** — sorting by timestamp alone is unstable
///   when two messages share a `sentAt` (common for batched writes), so the
///   list can visibly reshuffle between rebuilds. We add a stable tie-break.
///
/// Every method here is a pure function over its inputs: no I/O, no clocks, no
/// singletons. That makes the delivery guarantees exhaustively testable.
class MessageReconciler {
  const MessageReconciler._();

  /// Window within which an optimistic (client-temp-id) message and a server
  /// message that share a content signature are treated as the same logical
  /// message. The server timestamp can drift from the optimistic one by the
  /// round-trip plus clock skew, so the window is generous but bounded.
  static const Duration optimisticMatchWindow = Duration(seconds: 30);

  /// Deterministic total ordering: chronological by [Message.sentAt], then by
  /// [Message.id] as a stable tie-break so equal timestamps never reorder
  /// across rebuilds or between devices.
  static int compareMessages(Message a, Message b) {
    final byTime = a.sentAt.compareTo(b.sentAt);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }

  /// Merge confirmed server messages into the existing list, de-duplicating by
  /// id (the incoming copy wins, as it carries the authoritative
  /// read/moderation/reaction state) and returning a new,
  /// deterministically-ordered list.
  ///
  /// Properties relied on by callers and asserted by tests:
  /// * **Idempotent** — merging the same [incoming] batch repeatedly yields an
  ///   equal result, so reconnect replays cannot create duplicates.
  /// * **Order-restoring** — a late message with an earlier timestamp is placed
  ///   at its chronological position, never merely appended.
  /// * **Pure** — neither input list is mutated.
  static List<Message> mergeServerMessages({
    required List<Message> existing,
    required List<Message> incoming,
  }) {
    if (incoming.isEmpty) {
      if (existing.isEmpty) return const <Message>[];
      final ordered = List<Message>.of(existing)..sort(compareMessages);
      return ordered;
    }

    final byId = <String, Message>{};
    for (final message in existing) {
      byId[message.id] = message;
    }
    for (final message in incoming) {
      // Server copy wins on id collision.
      byId[message.id] = message;
    }

    return byId.values.toList()..sort(compareMessages);
  }

  /// Keep at most [maxRetained] of the *newest* messages. Used when appending
  /// live messages: the user is anchored at the bottom, so the oldest entries
  /// are the cheapest to evict (they can be re-fetched via pagination).
  static List<Message> capKeepingNewest(
    List<Message> messages,
    int maxRetained,
  ) {
    if (messages.length <= maxRetained) return messages;
    return messages.sublist(messages.length - maxRetained);
  }

  /// Keep at most [maxRetained] of the *oldest* messages in the list. Used when
  /// the user scrolls up and loads history: the freshly-loaded older context
  /// is what they are looking at, so the newest entries are evicted instead.
  static List<Message> capKeepingOldest(
    List<Message> messages,
    int maxRetained,
  ) {
    if (messages.length <= maxRetained) return messages;
    return messages.sublist(0, maxRetained);
  }

  /// Content signature used to reconcile an optimistic message with the server
  /// echo of the same send (the server assigns a different id). Uses a control
  /// character as a separator so it cannot collide with field contents.
  static String signatureOf(Message message) =>
      '${message.fromUserId}${message.type.name}${message.content}';

  /// Returns the set of pending temp-ids that are now confirmed by a
  /// [confirmed] server message — either because the server reused the temp id,
  /// or because a confirmed message shares the optimistic message's signature
  /// within [optimisticMatchWindow]. These should be dropped from the pending
  /// map once their authoritative copy is present.
  static Set<String> resolvedPendingIds({
    required Map<String, Message> pending,
    required List<Message> confirmed,
  }) {
    if (pending.isEmpty || confirmed.isEmpty) return const <String>{};

    final confirmedIds = <String>{};
    final confirmedBySignature = <String, List<Message>>{};
    for (final message in confirmed) {
      confirmedIds.add(message.id);
      (confirmedBySignature[signatureOf(message)] ??= <Message>[]).add(message);
    }

    final resolved = <String>{};
    pending.forEach((tempId, optimistic) {
      if (confirmedIds.contains(tempId)) {
        resolved.add(tempId);
        return;
      }
      final candidates = confirmedBySignature[signatureOf(optimistic)];
      if (candidates == null) return;
      for (final server in candidates) {
        final delta = server.sentAt.difference(optimistic.sentAt).abs();
        if (delta <= optimisticMatchWindow) {
          resolved.add(tempId);
          break;
        }
      }
    });
    return resolved;
  }

  /// Drop every pending entry that a [confirmed] server message has resolved,
  /// returning a new map. The original is not mutated.
  static Map<String, Message> prunePending({
    required Map<String, Message> pending,
    required List<Message> confirmed,
  }) {
    final resolved = resolvedPendingIds(pending: pending, confirmed: confirmed);
    if (resolved.isEmpty) return pending;
    final next = Map<String, Message>.of(pending)
      ..removeWhere((tempId, _) => resolved.contains(tempId));
    return next;
  }

  /// Build the list the UI renders: confirmed server messages plus any
  /// still-unconfirmed optimistic/pending messages, de-duplicated against the
  /// confirmed set and ordered deterministically.
  ///
  /// When there are no pending messages this returns [confirmed] unchanged (it
  /// is already maintained in order by [mergeServerMessages]), keeping the
  /// common read path allocation-free.
  static List<Message> combineForDisplay({
    required List<Message> confirmed,
    required Map<String, Message> pending,
  }) {
    if (pending.isEmpty) return confirmed;

    final resolved = resolvedPendingIds(pending: pending, confirmed: confirmed);
    final combined = List<Message>.of(confirmed);
    pending.forEach((tempId, message) {
      if (!resolved.contains(tempId)) combined.add(message);
    });
    combined.sort(compareMessages);
    return combined;
  }
}
