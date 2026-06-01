import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:crushhour/core/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a pending action that should be executed when online.
class PendingAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final int maxRetries;

  /// Logical identity used to de-duplicate enqueues (CHAT-RT-003). Two actions
  /// with the same [dedupeKey] are the same logical operation — re-enqueuing
  /// one while it is still pending is a no-op, which prevents double-sends from
  /// double taps, replayed offline mutations, or re-hydration after restart.
  /// Defaults to [id] when not supplied (every action is at least unique).
  final String dedupeKey;

  const PendingAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    String? dedupeKey,
  }) : dedupeKey = dedupeKey ?? id;

  bool get canRetry => retryCount < maxRetries;

  PendingAction incrementRetry() => PendingAction(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    maxRetries: maxRetries,
    dedupeKey: dedupeKey,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'maxRetries': maxRetries,
    'dedupeKey': dedupeKey,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    maxRetries: json['maxRetries'] as int? ?? 3,
    // Back-compat: actions persisted before dedupeKey existed fall back to id.
    dedupeKey: json['dedupeKey'] as String?,
  );
}

/// Result of processing a pending action.
enum ActionResult {
  /// Action succeeded, remove from queue.
  success,

  /// Action failed but can retry. Counts toward [PendingAction.maxRetries];
  /// when the budget is exhausted the action is dead-lettered (dropped).
  retryable,

  /// Action failed permanently, remove from queue.
  failed,
}

/// Handler signature for processing pending actions.
typedef ActionHandler = Future<ActionResult> Function(PendingAction action);

/// Queue for offline actions that need to be synced when online.
///
/// Persists actions to [SharedPreferences] and replays them, in order, when
/// connectivity is restored (callers invoke [processAll] on reconnect).
///
/// Ordering & recovery policy (CHAT-RT-003):
/// * **Strict FIFO, head-blocking.** Actions are replayed oldest-first and the
///   head is never reordered. A transiently-failing action stays at the head
///   and is retried in place, so action _N+1_ can never overtake action _N_
///   (critical for message ordering — see `MessageReconciler`).
/// * **Transient vs. bounded failure.** A thrown error (network/outage) is
///   treated as transient: the head is preserved and retried with exponential
///   backoff indefinitely, so a real send is never lost to a flaky connection.
///   A handler that returns [ActionResult.retryable] consumes the retry budget
///   and is dead-lettered once [PendingAction.maxRetries] is reached;
///   [ActionResult.failed] drops immediately (permanent error).
/// * **Idempotent enqueue.** [enqueue] ignores an action whose [PendingAction
///   .dedupeKey] is already queued.
/// * **Observable eviction.** At capacity the oldest action is evicted to bound
///   growth; the drop is counted in [QueueStatus.droppedCount] and logged, so
///   silent data loss is surfaced rather than hidden.
class OfflineActionQueue {
  OfflineActionQueue({
    Duration retryBaseDelay = const Duration(seconds: 5),
    Duration maxRetryDelay = const Duration(seconds: 60),
  }) : _retryBaseDelay = retryBaseDelay,
       _maxRetryDelay = maxRetryDelay;

  static const _storageKey = 'offline_action_queue';
  // DB-001: Limit queue size to prevent unbounded growth.
  static const _maxQueueSize = 500;

  final Duration _retryBaseDelay;
  final Duration _maxRetryDelay;

  final Queue<PendingAction> _queue = Queue();
  final Map<String, ActionHandler> _handlers = {};
  bool _isProcessing = false;
  Timer? _retryTimer;

  /// Number of consecutive head failures, used to grow the backoff during a
  /// sustained outage without consuming any action's retry budget. Reset to 0
  /// whenever the queue makes forward progress.
  int _consecutiveFailures = 0;

  /// Count of actions evicted for capacity reasons (data-loss signal).
  int _droppedCount = 0;

  /// Stream controller for queue status updates.
  final _statusController = StreamController<QueueStatus>.broadcast();

  /// Stream of queue status changes.
  Stream<QueueStatus> get statusStream => _statusController.stream;

  /// Current queue status.
  QueueStatus get status => QueueStatus(
    pendingCount: _queue.length,
    isProcessing: _isProcessing,
    droppedCount: _droppedCount,
  );

  /// Register a handler for a specific action type.
  void registerHandler(String type, ActionHandler handler) {
    _handlers[type] = handler;
  }

  /// Add an action to the queue.
  ///
  /// Idempotent: if an action with the same [PendingAction.dedupeKey] is
  /// already queued, this is a no-op (prevents duplicate side effects).
  Future<void> enqueue(PendingAction action) async {
    if (_queue.any((a) => a.dedupeKey == action.dedupeKey)) {
      AppLogger.debug(
        'OfflineQueue: Skipping duplicate enqueue (dedupeKey=${action.dedupeKey})',
      );
      return;
    }

    // DB-001: Evict the oldest entries if at capacity, and surface the drop.
    while (_queue.length >= _maxQueueSize) {
      final evicted = _queue.removeFirst();
      _droppedCount++;
      AppLogger.warning(
        'OfflineQueue: At capacity ($_maxQueueSize); evicted oldest action '
        '${evicted.type} (id=${evicted.id}). Total dropped=$_droppedCount',
      );
    }
    _queue.add(action);
    await _persist();
    _emitStatus();
  }

  /// Load queue from persistent storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json == null) return;

    try {
      final list = jsonDecode(json) as List;
      _queue.clear();
      for (final item in list) {
        _queue.add(PendingAction.fromJson(item as Map<String, dynamic>));
      }
      _emitStatus();
    } catch (e) {
      // Corrupted data, clear it
      AppLogger.error('OfflineQueue: Corrupted queue data, clearing: $e');
      await prefs.remove(_storageKey);
    }
  }

  /// Process pending actions in strict FIFO order.
  ///
  /// Drains the queue from the head, stopping at the first action that needs to
  /// be retried (it is left at the head and a backoff retry is scheduled). This
  /// guarantees a failing action never lets a later one overtake it.
  Future<void> processAll() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _emitStatus();

    // DB-003: try-finally ensures _isProcessing is always reset.
    try {
      while (_queue.isNotEmpty) {
        final action = _queue.first;
        final handler = _handlers[action.type];

        if (handler == null) {
          // No handler registered, skip (forward progress).
          _queue.removeFirst();
          _consecutiveFailures = 0;
          await _persist();
          _emitStatus();
          continue;
        }

        final ActionResult result;
        try {
          result = await handler(action);
        } catch (e) {
          // Transient (network/outage): keep the head in place and back off.
          // Does NOT consume the retry budget, so a genuine send survives an
          // arbitrarily long outage.
          AppLogger.error(
            'OfflineQueue: Transient error on ${action.type} (id=${action.id}); '
            'preserving head and scheduling retry: $e',
          );
          _scheduleRetry();
          break;
        }

        switch (result) {
          case ActionResult.success:
            _queue.removeFirst();
            _consecutiveFailures = 0;
            await _persist();
            _emitStatus();
            continue;

          case ActionResult.failed:
            // Permanent error: drop and move on.
            _queue.removeFirst();
            _consecutiveFailures = 0;
            await _persist();
            _emitStatus();
            continue;

          case ActionResult.retryable:
            if (action.canRetry) {
              // Replace the head in place with an incremented retry count so
              // ordering is preserved, then back off before re-attempting.
              _queue.removeFirst();
              _queue.addFirst(action.incrementRetry());
              await _persist();
              _emitStatus();
              _scheduleRetry();
              return;
            }
            // Budget exhausted: dead-letter (drop) and continue draining.
            AppLogger.warning(
              'OfflineQueue: Dead-lettering ${action.type} (id=${action.id}) '
              'after ${action.retryCount} retries',
            );
            _queue.removeFirst();
            _consecutiveFailures = 0;
            await _persist();
            _emitStatus();
            continue;
        }
      }
    } finally {
      _isProcessing = false;
      _emitStatus();
    }
  }

  void _scheduleRetry() {
    _consecutiveFailures++;
    final delay = _backoffDelay(_consecutiveFailures);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, processAll);
  }

  /// Exponential backoff capped at [_maxRetryDelay], with ±20% jitter to avoid
  /// synchronized retry storms across clients.
  Duration _backoffDelay(int failureCount) {
    final exponent = (failureCount - 1).clamp(0, 16);
    final base = _retryBaseDelay.inMilliseconds * (1 << exponent);
    final capped = base.clamp(0, _maxRetryDelay.inMilliseconds);
    final jitter = (capped * 0.4 * (Random().nextDouble() - 0.5)).round();
    return Duration(milliseconds: max(0, capped + jitter));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _queue.map((a) => a.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  void _emitStatus() {
    if (_statusController.isClosed) return;
    _statusController.add(status);
  }

  /// Clear all pending actions and reset the dropped counter.
  Future<void> clear() async {
    _queue.clear();
    _consecutiveFailures = 0;
    _droppedCount = 0;
    _retryTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _emitStatus();
  }

  /// Dispose resources.
  void dispose() {
    _retryTimer?.cancel();
    _statusController.close();
  }
}

/// Status of the offline action queue.
class QueueStatus {
  final int pendingCount;
  final bool isProcessing;

  /// Cumulative count of actions dropped due to capacity eviction.
  final int droppedCount;

  const QueueStatus({
    required this.pendingCount,
    required this.isProcessing,
    this.droppedCount = 0,
  });

  bool get hasPending => pendingCount > 0;

  /// Whether any actions have been dropped (a data-loss signal worth surfacing
  /// to the user, e.g. "some messages couldn't be queued").
  bool get hasDropped => droppedCount > 0;
}

/// Common action types for the offline queue.
class ActionTypes {
  static const sendMessage = 'send_message';
  static const swipeRight = 'swipe_right';
  static const swipeLeft = 'swipe_left';
  static const addReaction = 'add_reaction';
  static const removeReaction = 'remove_reaction';
  static const markRead = 'mark_read';
  static const updateProfile = 'update_profile';
  static const reportUser = 'report_user';
  static const blockUser = 'block_user';
}
