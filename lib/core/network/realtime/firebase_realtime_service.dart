import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter/foundation.dart';

/// Firebase Firestore real-time sync service.
///
/// Provides:
/// - Real-time listeners for collections and documents
/// - Subscription management
/// - Offline support with Firestore caching
/// - Query-based listeners
class FirebaseRealtimeService {
  FirebaseRealtimeService._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirebaseRealtimeService instance = FirebaseRealtimeService._();

  @visibleForTesting
  factory FirebaseRealtimeService.test({required FirebaseFirestore firestore}) {
    return FirebaseRealtimeService._(firestore: firestore);
  }

  final FirebaseFirestore _firestore;
  final Map<String, StreamSubscription> _subscriptions = {};

  bool _isInitialized = false;

  /// Initialize the service with optional settings.
  Future<void> initialize({
    bool enableOfflinePersistence = true,
    int cacheSizeBytes = 100 * 1024 * 1024, // 100MB
  }) async {
    if (_isInitialized) return;

    try {
      _firestore.settings = Settings(
        persistenceEnabled: enableOfflinePersistence,
        cacheSizeBytes: cacheSizeBytes,
      );

      _isInitialized = true;
      AppLogger.debug('FirebaseRealtimeService: Initialized');
    } catch (e) {
      AppLogger.error('FirebaseRealtimeService: Initialization failed - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCUMENT LISTENERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Listen to a single document.
  Stream<T?> listenToDocument<T>({
    required String collection,
    required String documentId,
    required T Function(Map<String, dynamic> data, String id) fromJson,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return fromJson(snapshot.data()!, snapshot.id);
    });
  }

  /// Subscribe to a document with a callback.
  String subscribeToDocument({
    required String collection,
    required String documentId,
    required void Function(Map<String, dynamic>? data) onData,
    void Function(dynamic error)? onError,
  }) {
    final subscriptionId = '${collection}_$documentId';

    // Cancel existing subscription if any
    _subscriptions[subscriptionId]?.cancel();

    // ignore: cancel_subscriptions - stored in _subscriptions map, cancelled via dispose()
    final subscription = _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .listen((snapshot) {
          onData(snapshot.data());
        }, onError: onError ?? (e) => AppLogger.error('Firestore error: $e'));

    _subscriptions[subscriptionId] = subscription;
    return subscriptionId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTION LISTENERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Listen to a collection.
  Stream<List<T>> listenToCollection<T>({
    required String collection,
    required T Function(Map<String, dynamic> data, String id) fromJson,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromJson(doc.data(), doc.id)).toList();
    });
  }

  /// Subscribe to a collection with a callback.
  String subscribeToCollection({
    required String collection,
    required void Function(List<DocumentChange<Map<String, dynamic>>> changes)
    onChanges,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
    void Function(dynamic error)? onError,
  }) {
    final subscriptionId =
        '${collection}_${DateTime.now().millisecondsSinceEpoch}';

    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    // ignore: cancel_subscriptions - stored in _subscriptions map, cancelled via dispose()
    final subscription = query.snapshots().listen((snapshot) {
      onChanges(snapshot.docChanges);
    }, onError: onError ?? (e) => AppLogger.error('Firestore error: $e'));

    _subscriptions[subscriptionId] = subscription;
    return subscriptionId;
  }

  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterOperator.notEquals:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterOperator.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterOperator.lessThanOrEqual:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case FilterOperator.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterOperator.greaterThanOrEqual:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case FilterOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterOperator.arrayContainsAny:
        return query.where(
          filter.field,
          arrayContainsAny: filter.value as List,
        );
      case FilterOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value as List);
      case FilterOperator.whereNotIn:
        return query.where(filter.field, whereNotIn: filter.value as List);
    }
  }

  @visibleForTesting
  Query<Map<String, dynamic>> applyFilterForTesting(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    return _applyFilter(query, filter);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT SPECIFIC LISTENERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Listen to messages in a conversation.
  Stream<List<T>> listenToMessages<T>({
    required String conversationId,
    required T Function(Map<String, dynamic> data, String id) fromJson,
    int limit = 50,
    DateTime? afterTimestamp,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (afterTimestamp != null) {
      query = query.where(
        'created_at',
        isGreaterThan: Timestamp.fromDate(afterTimestamp),
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromJson(doc.data(), doc.id)).toList();
    });
  }

  /// Listen to user's conversations.
  Stream<List<T>> listenToConversations<T>({
    required String userId,
    required T Function(Map<String, dynamic> data, String id) fromJson,
    int limit = 50,
  }) {
    return _firestore
        .collection('conversations')
        .where('participant_ids', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// Listen to typing indicators in a conversation.
  Stream<Map<String, bool>> listenToTypingIndicators({
    required String conversationId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
          final typing = <String, bool>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final isTyping = data['is_typing'] as bool? ?? false;
            final timestamp = data['timestamp'] as Timestamp?;

            // Only consider typing if within last 10 seconds
            if (isTyping && timestamp != null) {
              final age = DateTime.now()
                  .difference(timestamp.toDate())
                  .inSeconds;
              typing[doc.id] = age < 10;
            } else {
              typing[doc.id] = false;
            }
          }
          return typing;
        });
  }

  /// Listen to user's matches.
  Stream<List<T>> listenToMatches<T>({
    required String userId,
    required T Function(Map<String, dynamic> data, String id) fromJson,
    int limit = 50,
  }) {
    return _firestore
        .collection('matches')
        .where('user_ids', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// Listen to user's online presence.
  Stream<bool> listenToPresence({required String userId}) {
    return _firestore.collection('presence').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null) return false;

      final isOnline = data['is_online'] as bool? ?? false;
      final lastSeen = data['last_seen'] as Timestamp?;

      // Consider online if marked online and last seen within 5 minutes
      if (isOnline && lastSeen != null) {
        final age = DateTime.now().difference(lastSeen.toDate()).inMinutes;
        return age < 5;
      }
      return false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESENCE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update current user's online presence.
  Future<void> updatePresence({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _firestore.collection('presence').doc(userId).set({
        'is_online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('FirebaseRealtimeService: Update presence failed - $e');
    }
  }

  /// Update typing indicator.
  Future<void> updateTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .set({
            'is_typing': isTyping,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('FirebaseRealtimeService: Update typing failed - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cancel a specific subscription.
  void cancelSubscription(String subscriptionId) {
    _subscriptions[subscriptionId]?.cancel();
    _subscriptions.remove(subscriptionId);
  }

  /// Cancel all subscriptions.
  void cancelAllSubscriptions() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    AppLogger.debug('FirebaseRealtimeService: Cancelled all subscriptions');
  }

  /// Get count of active subscriptions.
  int get activeSubscriptionCount => _subscriptions.length;

  /// Dispose the service.
  void dispose() {
    cancelAllSubscriptions();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUERY FILTER
// ═══════════════════════════════════════════════════════════════════════════

/// Filter operator for queries.
enum FilterOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// Query filter for Firestore queries.
class QueryFilter {
  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final FilterOperator operator;
  final dynamic value;

  /// Create an equals filter.
  factory QueryFilter.equals(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.equals,
      value: value,
    );
  }

  /// Create a not equals filter.
  factory QueryFilter.notEquals(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.notEquals,
      value: value,
    );
  }

  /// Create a less than filter.
  factory QueryFilter.lessThan(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.lessThan,
      value: value,
    );
  }

  /// Create a greater than filter.
  factory QueryFilter.greaterThan(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.greaterThan,
      value: value,
    );
  }

  /// Create an array contains filter.
  factory QueryFilter.arrayContains(String field, dynamic value) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.arrayContains,
      value: value,
    );
  }

  /// Create a whereIn filter.
  factory QueryFilter.whereIn(String field, List<dynamic> values) {
    return QueryFilter(
      field: field,
      operator: FilterOperator.whereIn,
      value: values,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SYNC STATUS
// ═══════════════════════════════════════════════════════════════════════════

/// Sync status for offline-first data.
enum SyncStatus { synced, pending, syncing, failed }

/// Wrapper for data with sync status.
class SyncedData<T> {
  const SyncedData({
    required this.data,
    required this.status,
    this.lastSyncedAt,
    this.error,
  });

  final T data;
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? error;

  bool get isSynced => status == SyncStatus.synced;
  bool get isPending => status == SyncStatus.pending;
  bool get hasFailed => status == SyncStatus.failed;

  SyncedData<T> copyWith({
    T? data,
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? error,
  }) {
    return SyncedData<T>(
      data: data ?? this.data,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error ?? this.error,
    );
  }
}
