import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/match.dart';
import '../chat_repository.dart';

/// Mock implementation of ChatRepository with local storage.
/// Stores messages locally and provides simulated real-time updates.
class StubChatRepository implements ChatRepository {
  static const _messagesKeyPrefix = 'mock_messages_';
  static const _blockedKeyPrefix = 'mock_blocked_';
  static const _matchesKey = 'mock_matches_';
  static const _deletedMessagesKeyPrefix = 'mock_deleted_';

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, StreamController<Set<String>>> _typingControllers = {};
  final Map<String, StreamController<bool>> _presenceControllers = {};
  final Map<String, StreamController<bool>> _mediaEnabledControllers = {};

  // Local state
  final Map<String, Set<String>> _typingUsers = {};
  final Map<String, bool> _userPresence = {};
  final Map<String, bool> _mediaEnabled = {};

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    _messageControllers[matchId] ??= StreamController<List<Message>>.broadcast();

    // Load initial messages
    _loadMessages(matchId).then((messages) {
      if (!_messageControllers[matchId]!.isClosed) {
        _messageControllers[matchId]!.add(messages);
      }
    });

    return _messageControllers[matchId]!.stream;
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      matchId: matchId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
      reactions: const {},
    );

    await _saveMessage(matchId, message);
    await _notifyMessageUpdate(matchId);

    // Simulate auto-reply after 2-3 seconds (50% chance)
    if (DateTime.now().millisecond % 2 == 0) {
      Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecond % 1000)), () async {
        // Show typing indicator
        await setTyping(matchId: matchId, userId: toUserId, isTyping: true);

        await Future.delayed(const Duration(milliseconds: 1500));

        // Stop typing and send reply
        await setTyping(matchId: matchId, userId: toUserId, isTyping: false);

        final replies = [
          'Hey! How are you? 😊',
          'That sounds great!',
          'I\'d love to hear more about that',
          'Interesting! Tell me more',
          'Haha, that\'s funny 😄',
          '👍',
          'What are you up to today?',
          'That\'s awesome!',
        ];
        final reply = replies[DateTime.now().millisecond % replies.length];

        final autoReply = Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          matchId: matchId,
          fromUserId: toUserId,
          toUserId: fromUserId,
          content: reply,
          type: MessageType.text,
          sentAt: DateTime.now(),
          isRead: false,
          isDeletedForSender: false,
          reactions: const {},
        );

        await _saveMessage(matchId, autoReply);
        await _notifyMessageUpdate(matchId);
      });
    }
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Return the local file path as the URL for demo purposes
    // In a real app, this would upload to cloud storage
    return filePath;
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final messages = await _loadMessages(matchId);
    final updatedMessages = messages.map((m) {
      if (m.toUserId == userId && !m.isRead) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    await _saveAllMessages(matchId, updatedMessages);
    await _notifyMessageUpdate(matchId);
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    final messages = await _loadMessages(matchId);
    final updatedMessages = messages.where((m) => m.id != messageId).toList();
    await _saveAllMessages(matchId, updatedMessages);
    await _notifyMessageUpdate(matchId);
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_deletedMessagesKeyPrefix${userId}_$matchId';
    final deletedJson = prefs.getString(key);
    final deleted = deletedJson != null
        ? Set<String>.from(jsonDecode(deletedJson))
        : <String>{};
    deleted.add(messageId);
    await prefs.setString(key, jsonEncode(deleted.toList()));
    await _notifyMessageUpdate(matchId);
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
    // Store report locally (in real app, send to backend)
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('mock_reports') ?? [];
    reports.add(jsonEncode({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'matchId': matchId,
      'messageId': messageId,
      'source': source,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('mock_reports', reports);
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final messages = await _loadMessages(matchId);
    final updatedMessages = messages.map((m) {
      if (m.id == messageId) {
        final newReactions = Map<String, String>.from(m.reactions);
        newReactions[userId] = emoji;
        return m.copyWith(reactions: newReactions);
      }
      return m;
    }).toList();

    await _saveAllMessages(matchId, updatedMessages);
    await _notifyMessageUpdate(matchId);
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final messages = await _loadMessages(matchId);
    final updatedMessages = messages.map((m) {
      if (m.id == messageId) {
        final newReactions = Map<String, String>.from(m.reactions);
        newReactions.remove(userId);
        return m.copyWith(reactions: newReactions);
      }
      return m;
    }).toList();

    await _saveAllMessages(matchId, updatedMessages);
    await _notifyMessageUpdate(matchId);
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    // Store appeal locally
    final prefs = await SharedPreferences.getInstance();
    final appeals = prefs.getStringList('mock_appeals') ?? [];
    appeals.add(jsonEncode({
      'userId': userId,
      'reason': reason,
      'targetType': targetType,
      'targetId': targetId,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('mock_appeals', appeals);
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) {
    _typingControllers[matchId] ??= StreamController<Set<String>>.broadcast();
    _typingUsers[matchId] ??= {};

    // Emit current state
    _typingControllers[matchId]!.add(_typingUsers[matchId]!);

    return _typingControllers[matchId]!.stream;
  }

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    _typingUsers[matchId] ??= {};

    if (isTyping) {
      _typingUsers[matchId]!.add(userId);
    } else {
      _typingUsers[matchId]!.remove(userId);
    }

    if (_typingControllers[matchId] != null &&
        !_typingControllers[matchId]!.isClosed) {
      _typingControllers[matchId]!.add(Set.from(_typingUsers[matchId]!));
    }
  }

  @override
  Stream<bool> watchPresence(String userId) {
    _presenceControllers[userId] ??= StreamController<bool>.broadcast();

    // For demo, mock users are always "online"
    final isOnline = _userPresence[userId] ?? true;
    _presenceControllers[userId]!.add(isOnline);

    return _presenceControllers[userId]!.stream;
  }

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    _userPresence[userId] = isOnline;

    if (_presenceControllers[userId] != null &&
        !_presenceControllers[userId]!.isClosed) {
      _presenceControllers[userId]!.add(isOnline);
    }
  }

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) {
    _mediaEnabledControllers[matchId] ??= StreamController<bool>.broadcast();

    final enabled = _mediaEnabled[matchId] ?? true;
    _mediaEnabledControllers[matchId]!.add(enabled);

    return _mediaEnabledControllers[matchId]!.stream;
  }

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    _mediaEnabled[matchId] = enabled;

    if (_mediaEnabledControllers[matchId] != null &&
        !_mediaEnabledControllers[matchId]!.isClosed) {
      _mediaEnabledControllers[matchId]!.add(enabled);
    }
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_blockedKeyPrefix$blockerId';
    final blockedJson = prefs.getString(key);
    final blocked = blockedJson != null
        ? Set<String>.from(jsonDecode(blockedJson))
        : <String>{};
    blocked.add(blockedId);
    await prefs.setString(key, jsonEncode(blocked.toList()));
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_blockedKeyPrefix$blockerId';
    final blockedJson = prefs.getString(key);
    if (blockedJson != null) {
      final blocked = Set<String>.from(jsonDecode(blockedJson));
      blocked.remove(blockedId);
      await prefs.setString(key, jsonEncode(blocked.toList()));
    }
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('$_matchesKey$userId');
    if (matchesJson != null) {
      final matches = List<Map<String, dynamic>>.from(jsonDecode(matchesJson));
      matches.removeWhere((m) => m['id'] == matchId);
      await prefs.setString('$_matchesKey$userId', jsonEncode(matches));
    }

    // Also clear messages for this match
    await prefs.remove('$_messagesKeyPrefix$matchId');
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('mock_matches_$userId');
    if (matchesJson == null) return [];

    final matchesList = List<Map<String, dynamic>>.from(jsonDecode(matchesJson));
    return matchesList.map((m) => CrushMatch(
      id: m['id'],
      userId: m['userId'],
      otherUserId: m['otherUserId'],
      status: MatchStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => MatchStatus.mutual,
      ),
      preMatchMessageRequestsCount: m['preMatchMessageRequestsCount'] ?? 0,
      pinnedForUser: m['pinnedForUser'] ?? false,
      otherUserName: m['otherUserName'],
      otherUserPhotoUrl: m['otherUserPhotoUrl'],
    )).toList();
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    final allMatches = await fetchUserMatches(userId);
    final total = allMatches.length;
    final end = (offset + limit).clamp(0, total);
    final items = offset < total ? allMatches.sublist(offset, end) : <CrushMatch>[];
    return PaginatedResult(
      items: items,
      total: total,
      hasMore: end < total,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Message>> _loadMessages(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('$_messagesKeyPrefix$matchId');
    if (messagesJson == null) return [];

    final messagesList = List<Map<String, dynamic>>.from(jsonDecode(messagesJson));
    return messagesList.map((m) => Message(
      id: m['id'],
      matchId: m['matchId'],
      fromUserId: m['fromUserId'],
      toUserId: m['toUserId'],
      content: m['content'],
      type: MessageType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => MessageType.text,
      ),
      sentAt: DateTime.parse(m['sentAt']),
      isRead: m['isRead'] ?? false,
      isDeletedForSender: m['isDeletedForSender'] ?? false,
      reactions: Map<String, String>.from(m['reactions'] ?? {}),
      moderationStatus: m['moderationStatus'],
      moderationReason: m['moderationReason'],
      moderationAction: m['moderationAction'],
      isFlagged: m['isFlagged'] ?? false,
    )).toList();
  }

  Future<void> _saveMessage(String matchId, Message message) async {
    final messages = await _loadMessages(matchId);
    messages.add(message);
    await _saveAllMessages(matchId, messages);
  }

  Future<void> _saveAllMessages(String matchId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesList = messages.map((m) => {
      'id': m.id,
      'matchId': m.matchId,
      'fromUserId': m.fromUserId,
      'toUserId': m.toUserId,
      'content': m.content,
      'type': m.type.name,
      'sentAt': m.sentAt.toIso8601String(),
      'isRead': m.isRead,
      'isDeletedForSender': m.isDeletedForSender,
      'reactions': m.reactions,
      'moderationStatus': m.moderationStatus,
      'moderationReason': m.moderationReason,
      'moderationAction': m.moderationAction,
      'isFlagged': m.isFlagged,
    }).toList();
    await prefs.setString('$_messagesKeyPrefix$matchId', jsonEncode(messagesList));
  }

  Future<void> _notifyMessageUpdate(String matchId) async {
    if (_messageControllers[matchId] != null &&
        !_messageControllers[matchId]!.isClosed) {
      final messages = await _loadMessages(matchId);
      _messageControllers[matchId]!.add(messages);
    }
  }

  /// Clean up stream controllers when done
  void dispose() {
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    for (final controller in _presenceControllers.values) {
      controller.close();
    }
    for (final controller in _mediaEnabledControllers.values) {
      controller.close();
    }
  }
}
