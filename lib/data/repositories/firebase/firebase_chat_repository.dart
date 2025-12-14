import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/message.dart';
import '../../models/match.dart';
import '../chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    return _matches
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          matchId: matchId,
          fromUserId: data['fromUserId'] as String,
          toUserId: data['toUserId'] as String,
          content: data['content'] as String,
          type: _typeFromString(data['type'] as String? ?? 'text'),
          sentAt: (data['sentAt'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
          isDeletedForSender: data['isDeletedForSender'] ?? false,
        );
      }).toList();
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
    final msgRef =
        _matches.doc(matchId).collection('messages').doc();
    await msgRef.set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'content': content,
      'type': _typeToString(type),
      'sentAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'isDeletedForSender': false,
    });
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    final ext = filePath.split('.').last;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'chat_media/$matchId/${ts}_$type.$ext';
    final ref = FirebaseStorage.instance.ref().child(path);
    final file = File(filePath);
    UploadTask uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(ext, type),
      ),
    );
    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final snapshot = await _matches
        .doc(matchId)
        .collection('messages')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    final callable = _functions.httpsCallable('unsendMessage');
    await callable.call(<String, dynamic>{
      'matchId': matchId,
      'messageId': messageId,
    });
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final docRef =
        _matches.doc(matchId).collection('messages').doc(messageId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data();
    if (data == null) return;
    if (data['fromUserId'] != userId) {
      throw Exception('Only the sender can delete this message for themselves.');
    }
    await docRef.update({'isDeletedForSender': true});
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _firestore.collection('blocks').add({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final query = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    if (query.docs.isEmpty) return;
    await batch.commit();
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    await _matches.doc(matchId).update({
      'status': 'unmatched',
    });
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    final snapshot = await _matches
        .where('userIds', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final userIds = List<String>.from(data['userIds'] ?? []);
      final otherUserId =
          userIds.firstWhere((id) => id != userId, orElse: () => '');
      final statusStr = data['status'] as String? ?? 'pending';
      final status = _statusFromString(statusStr);
      final preMap =
          (data['preMatchRequests'] as Map<String, dynamic>? ?? {});
      final preCount = (preMap[userId] as num?)?.toInt() ?? 0;
      final pinnedMap =
          (data['pinnedForUser'] as Map<String, dynamic>? ?? {});
      final pinned = pinnedMap[userId] ?? false;

      return CrushMatch(
        id: doc.id,
        userId: userId,
        otherUserId: otherUserId,
        status: status,
        preMatchMessageRequestsCount: preCount,
        pinnedForUser: pinned,
      );
    }).toList();
  }

  MessageType _typeFromString(String s) {
    switch (s) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  String _typeToString(MessageType t) {
    switch (t) {
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.voice:
        return 'voice';
      case MessageType.text:
        return 'text';
    }
  }

  String _contentType(String ext, MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image/$ext';
      case MessageType.video:
        return 'video/$ext';
      case MessageType.voice:
        return 'audio/$ext';
      case MessageType.text:
        return 'text/plain';
    }
  }

  MatchStatus _statusFromString(String s) {
    switch (s) {
      case 'mutual':
        return MatchStatus.mutual;
      case 'rejected':
        return MatchStatus.rejected;
      case 'unmatched':
        return MatchStatus.unmatched;
      default:
        return MatchStatus.pending;
    }
  }
}
