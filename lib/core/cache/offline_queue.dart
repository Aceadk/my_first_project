import 'dart:async';
import 'dart:collection';
import 'dart:convert';

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

  const PendingAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  bool get canRetry => retryCount < maxRetries;

  PendingAction incrementRetry() => PendingAction(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    maxRetries: maxRetries,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'maxRetries': maxRetries,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    maxRetries: json['maxRetries'] as int? ?? 3,
  );
}

/// Result of processing a pending action.
enum ActionResult {
  /// Action succeeded, remove from queue.
  success,

  /// Action failed but can retry.
  retryable,

  /// Action failed permanently, remove from queue.
  failed,
}

/// Handler signature for processing pending actions.
typedef ActionHandler = Future<ActionResult> Function(PendingAction action);

/// Queue for offline actions that need to be synced when online.
///
/// Actions are persisted to SharedPreferences and processed
/// in order when connectivity is restored.
class OfflineActionQueue {
  static const _storageKey = 'offline_action_queue';
  // DB-001: Limit queue size to prevent unbounded growth
  static const _maxQueueSize = 500;

  final Queue<PendingAction> _queue = Queue();
  final Map<String, ActionHandler> _handlers = {};
  bool _isProcessing = false;
  Timer? _retryTimer;

  /// Stream controller for queue status updates.
  final _statusController = StreamController<QueueStatus>.broadcast();

  /// Stream of queue status changes.
  Stream<QueueStatus> get statusStream => _statusController.stream;

  /// Current queue status.
  QueueStatus get status =>
      QueueStatus(pendingCount: _queue.length, isProcessing: _isProcessing);

  /// Register a handler for a specific action type.
  void registerHandler(String type, ActionHandler handler) {
    _handlers[type] = handler;
  }

  /// Add an action to the queue.
  Future<void> enqueue(PendingAction action) async {
    // DB-001: Evict oldest entries if at capacity
    while (_queue.length >= _maxQueueSize) {
      _queue.removeFirst();
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

  /// Process all pending actions.
  Future<void> processAll() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _emitStatus();

    // DB-003: try-finally ensures _isProcessing is always reset
    try {
      while (_queue.isNotEmpty) {
        final action = _queue.first;
        final handler = _handlers[action.type];

        if (handler == null) {
          // No handler registered, skip
          _queue.removeFirst();
          continue;
        }

        try {
          final result = await handler(action);

          switch (result) {
            case ActionResult.success:
              _queue.removeFirst();
              break;

            case ActionResult.retryable:
              if (action.canRetry) {
                _queue.removeFirst();
                _queue.add(action.incrementRetry());
              } else {
                _queue.removeFirst();
              }
              break;

            case ActionResult.failed:
              _queue.removeFirst();
              break;
          }
        } catch (e) {
          // Network error, stop processing and schedule retry
          AppLogger.error(
            'OfflineQueue: Network error processing action, scheduling retry: $e',
          );
          _scheduleRetry();
          break;
        }

        await _persist();
        _emitStatus();
      }
    } finally {
      _isProcessing = false;
      _emitStatus();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      processAll();
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _queue.map((a) => a.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  void _emitStatus() {
    _statusController.add(status);
  }

  /// Clear all pending actions.
  Future<void> clear() async {
    _queue.clear();
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

  const QueueStatus({required this.pendingCount, required this.isProcessing});

  bool get hasPending => pendingCount > 0;
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
