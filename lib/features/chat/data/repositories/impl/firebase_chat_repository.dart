import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/match.dart';
import '../chat_repository.dart';

/// Firebase implementation of ChatRepository.
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final userId = _currentUserId;
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final msg = _messageFromFirestore(doc.id, data);
        // Filter out messages deleted for the current user
        if (userId != null && msg.fromUserId == userId && msg.isDeletedForSender) {
          return false;
        }
        final deletedFor = (data['deletedFor'] as List<dynamic>?) ?? [];
        return !deletedFor.contains(userId);
      }).map((doc) => _messageFromFirestore(doc.id, doc.data())).toList();
    });
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    final userId = _currentUserId;

    // Build query - newest messages first
    Query<Map<String, dynamic>> query = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: true);

    // Apply cursor for pagination (fetch older messages)
    if (beforeTimestamp != null) {
      query = query.where('sentAt', isLessThan: Timestamp.fromDate(beforeTimestamp));
    }

    // Limit results
    query = query.limit(limit + 1); // Fetch one extra to check if there's more

    final snapshot = await query.get();

    // Check if there are more messages
    final hasMore = snapshot.docs.length > limit;
    final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

    // Parse messages and filter deleted ones
    final messages = docs.where((doc) {
      final data = doc.data();
      final msg = _messageFromFirestore(doc.id, data);
      // Filter out messages deleted for the current user
      if (userId != null && msg.fromUserId == userId && msg.isDeletedForSender) {
        return false;
      }
      final deletedFor = (data['deletedFor'] as List<dynamic>?) ?? [];
      return !deletedFor.contains(userId);
    }).map((doc) => _messageFromFirestore(doc.id, doc.data())).toList();

    // Reverse to get chronological order (oldest first) for UI
    return PaginatedResult(
      items: messages.reversed.toList(),
      total: -1, // Total count is expensive for large collections
      hasMore: hasMore,
    );
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) {
    final userId = _currentUserId;

    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .where('sentAt', isGreaterThan: Timestamp.fromDate(afterTimestamp))
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final msg = _messageFromFirestore(doc.id, data);
        // Filter out messages deleted for the current user
        if (userId != null && msg.fromUserId == userId && msg.isDeletedForSender) {
          return false;
        }
        final deletedFor = (data['deletedFor'] as List<dynamic>?) ?? [];
        return !deletedFor.contains(userId);
      }).map((doc) => _messageFromFirestore(doc.id, doc.data())).toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    final callable = _functions.httpsCallable('sendMessage');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'toUserId': toUserId,
      'content': content,
      'type': type.name,
    });
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref('chat_media/$matchId/$userId/$fileName');

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final callable = _functions.httpsCallable('markMessagesRead');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
    });
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    final callable = _functions.httpsCallable('unsendMessage');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'messageId': messageId,
    });
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    final callable = _functions.httpsCallable('editMessage');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'messageId': messageId,
      'content': newContent,
    });
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    // Add current user to the deletedFor array
    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {
    final callable = _functions.httpsCallable('reportUser');
    await callable.call<Map<String, dynamic>>({
      'reportedId': reportedId,
      'reason': reason,
      if (matchId != null) 'matchId': matchId,
      if (messageId != null) 'messageId': messageId,
      if (source != null) 'source': source,
      if (description != null) 'description': description,
    });
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$userId': emoji,
    });
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$userId': FieldValue.delete(),
    });
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    final callable = _functions.httpsCallable('submitSafetyAppeal');
    await callable.call<Map<String, dynamic>>({
      'reason': reason,
      if (targetType != null) 'targetType': targetType,
      if (targetId != null) 'targetId': targetId,
    });
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .where((doc) {
            final timestamp = doc.data()['timestamp'] as Timestamp?;
            if (timestamp == null) return false;
            // Only show typing if updated within last 5 seconds
            return now.difference(timestamp.toDate()).inSeconds < 5;
          })
          .map((doc) => doc.id)
          .toSet();
    });
  }

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    final ref = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('typing')
        .doc(userId);

    if (isTyping) {
      await ref.set({'timestamp': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  @override
  Stream<bool> watchPresence(String userId) {
    return _firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      final isOnline = data?['isOnline'] as bool? ?? false;
      final lastSeen = data?['lastSeen'] as Timestamp?;

      // Consider online if explicitly online or seen within last 2 minutes
      if (isOnline) return true;
      if (lastSeen != null) {
        return DateTime.now().difference(lastSeen.toDate()).inMinutes < 2;
      }
      return false;
    });
  }

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    await _firestore.collection('presence').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      return doc.data()?['mediaSendingEnabled'] as bool? ?? false;
    });
  }

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    final callable = _functions.httpsCallable('setMediaSendingEnabled');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'enabled': enabled,
    });
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final callable = _functions.httpsCallable('blockUser');
    await callable.call<Map<String, dynamic>>({
      'blockedId': blockedId,
    });
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final callable = _functions.httpsCallable('unblockUser');
    await callable.call<Map<String, dynamic>>({
      'blockedId': blockedId,
    });
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    final callable = _functions.httpsCallable('unmatch');
    await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
    });
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    final matchesQuery = await _firestore
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('matchedAt', descending: true)
        .get();

    return matchesQuery.docs.map((doc) {
      return _matchFromFirestore(userId, doc.id, doc.data());
    }).toList();
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    // Get total count
    final countQuery = await _firestore
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    final total = countQuery.count ?? 0;

    // Get paginated results
    var query = _firestore
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('matchedAt', descending: true)
        .limit(limit);

    // Handle offset via skip (not ideal for large datasets, but works for reasonable pagination)
    if (offset > 0) {
      final skipQuery = await _firestore
          .collection('matches')
          .where('userIds', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('matchedAt', descending: true)
          .limit(offset)
          .get();

      if (skipQuery.docs.isNotEmpty) {
        query = query.startAfterDocument(skipQuery.docs.last);
      }
    }

    final matchesQuery = await query.get();

    final items = matchesQuery.docs.map((doc) {
      return _matchFromFirestore(userId, doc.id, doc.data());
    }).toList();

    return PaginatedResult(
      items: items,
      total: total,
      hasMore: offset + items.length < total,
    );
  }

  @override
  Future<MessageRequest?> sendMessageRequest({
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserName,
    String? toUserPhotoUrl,
  }) async {
    final now = DateTime.now();
    final pairKey = _pairKey(fromUserId, toUserId);
    final docRef = _firestore.collection('message_requests').doc(pairKey);
    final existingDoc = await docRef.get();

    if (existingDoc.exists) {
      final existing = _messageRequestFromFirestore(
        existingDoc.id,
        existingDoc.data() ?? {},
      );
      if (!existing.isExpired) {
        return null;
      }
      await docRef.delete();
    }

    final request = MessageRequest(
      id: pairKey,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: now,
      expiresAt: now.add(const Duration(hours: 48)),
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
      toUserName: toUserName,
      toUserPhotoUrl: toUserPhotoUrl,
    );

    await docRef.set(_messageRequestToFirestore(request));
    return request;
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    final fromQuery = await _firestore
        .collection('message_requests')
        .where('fromUserId', isEqualTo: userId)
        .get();
    final toQuery = await _firestore
        .collection('message_requests')
        .where('toUserId', isEqualTo: userId)
        .get();

    final docs = [...fromQuery.docs, ...toQuery.docs];
    final requests = docs
        .map((doc) => _messageRequestFromFirestore(doc.id, doc.data()))
        .toList();

    final activeRequests = requests.where((r) => !r.isExpired).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

    final expiredDocs = docs.where((doc) {
      final req = _messageRequestFromFirestore(doc.id, doc.data());
      return req.isExpired;
    }).toList();

    if (expiredDocs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in expiredDocs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    return activeRequests;
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async {
    final pairKey = _pairKey(userId, otherUserId);
    final docRef = _firestore.collection('message_requests').doc(pairKey);
    final doc = await docRef.get();
    if (!doc.exists) return false;

    final request = _messageRequestFromFirestore(doc.id, doc.data() ?? {});
    if (request.isExpired) {
      await docRef.delete();
      return false;
    }
    return true;
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async {
    if (matches.isEmpty) return 0;

    final requests = await fetchMessageRequests(userId);
    if (requests.isEmpty) return 0;

    var migrated = 0;

    for (final match in matches) {
      final pairKey = _pairKey(userId, match.otherUserId);
      MessageRequest? request;
      for (final candidate in requests) {
        if (_pairKey(candidate.fromUserId, candidate.toUserId) == pairKey) {
          request = candidate;
          break;
        }
      }
      if (request == null) continue;

      // Only migrate when current user is the sender (auth constraints).
      if (request.fromUserId != userId) continue;

      try {
        await sendMessage(
          matchId: match.id,
          fromUserId: request.fromUserId,
          toUserId: request.toUserId,
          content: request.content,
          type: request.type,
        );
        await _firestore.collection('message_requests').doc(pairKey).delete();
        migrated++;
      } catch (e) {
        // Ignore failures; keep request for retry.
        debugPrint('FirebaseChatRepository: Message request migration failed (will retry): $e');
      }
    }

    return migrated;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Message _messageFromFirestore(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      matchId: data['matchId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      sentAt: _parseTimestamp(data['sentAt']) ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: _parseTimestamp(data['readAt']),
      isDeletedForSender: data['isDeletedForSender'] ?? false,
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      moderationStatus: data['moderationStatus'],
      moderationReason: data['moderationReason'],
      moderationAction: data['moderationAction'],
      isFlagged: data['isFlagged'] ?? false,
    );
  }

  MessageType _parseMessageType(dynamic value) {
    if (value == null) return MessageType.text;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }

  CrushMatch _matchFromFirestore(
    String userId,
    String docId,
    Map<String, dynamic> data,
  ) {
    final userIds = List<String>.from(data['userIds'] ?? []);
    final otherUserId = userIds.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );

    return CrushMatch(
      id: docId,
      userId: userId,
      otherUserId: otherUserId,
      status: MatchStatus.mutual,
      preMatchMessageRequestsCount:
          data['preMatchMessageRequestsCount'] as int? ?? 0,
      pinnedForUser: (data['pinnedBy'] as List<dynamic>?)?.contains(userId) ?? false,
      otherUserName: data['otherUserName'] as String?,
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
    );
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  String _pairKey(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA|$userB' : '$userB|$userA';
  }

  MessageRequest _messageRequestFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return MessageRequest(
      id: id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      sentAt: _parseTimestamp(data['sentAt']) ?? DateTime.now(),
      expiresAt: _parseTimestamp(data['expiresAt']) ??
          DateTime.now().add(const Duration(hours: 48)),
      fromUserName: data['fromUserName'] as String?,
      fromUserPhotoUrl: data['fromUserPhotoUrl'] as String?,
      toUserName: data['toUserName'] as String?,
      toUserPhotoUrl: data['toUserPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> _messageRequestToFirestore(MessageRequest request) {
    return {
      'fromUserId': request.fromUserId,
      'toUserId': request.toUserId,
      'content': request.content,
      'type': request.type.name,
      'sentAt': Timestamp.fromDate(request.sentAt),
      'expiresAt': Timestamp.fromDate(request.expiresAt),
      if (request.fromUserName != null) 'fromUserName': request.fromUserName,
      if (request.fromUserPhotoUrl != null)
        'fromUserPhotoUrl': request.fromUserPhotoUrl,
      if (request.toUserName != null) 'toUserName': request.toUserName,
      if (request.toUserPhotoUrl != null)
        'toUserPhotoUrl': request.toUserPhotoUrl,
    };
  }
}
