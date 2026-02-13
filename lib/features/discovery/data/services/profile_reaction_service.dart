import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:uuid/uuid.dart';

/// Service for managing profile reactions (likes on specific photos/prompts).
class ProfileReactionService {
  ProfileReactionService._();

  static final ProfileReactionService instance = ProfileReactionService._();

  final _uuid = const Uuid();

  /// In-memory storage of reactions (in production, backed by Firebase).
  final Map<String, List<ProfileReaction>> _sentReactions = {};
  final Map<String, List<ProfileReaction>> _receivedReactions = {};

  /// Stream controller for reaction updates.
  final _reactionUpdatesController =
      StreamController<ProfileReactionUpdate>.broadcast();

  /// Stream of reaction updates.
  Stream<ProfileReactionUpdate> get reactionUpdates =>
      _reactionUpdatesController.stream;

  /// Send a reaction to a profile's content.
  Future<ProfileReaction> sendReaction({
    required String fromUserId,
    required String toUserId,
    required ReactionContentType contentType,
    required int contentIndex,
    required String reactionType,
    String? comment,
    String? contentPreview,
  }) async {
    final reaction = ProfileReaction(
      id: _uuid.v4(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      contentType: contentType,
      contentIndex: contentIndex,
      reactionType: reactionType,
      createdAt: DateTime.now(),
      comment: comment,
      contentPreview: contentPreview,
    );

    // Store in sent reactions
    _sentReactions.putIfAbsent(fromUserId, () => []);
    _sentReactions[fromUserId]!.add(reaction);

    // Store in received reactions
    _receivedReactions.putIfAbsent(toUserId, () => []);
    _receivedReactions[toUserId]!.add(reaction);

    // Notify listeners
    _reactionUpdatesController.add(ProfileReactionUpdate(
      type: ReactionUpdateType.sent,
      reaction: reaction,
    ));

    return reaction;
  }

  /// Get all reactions sent by a user.
  List<ProfileReaction> getSentReactions(String userId) {
    return List.of(_sentReactions[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all reactions received by a user.
  List<ProfileReaction> getReceivedReactions(String userId) {
    return List.of(_receivedReactions[userId] ?? [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unread reactions for a user.
  List<ProfileReaction> getUnreadReactions(String userId) {
    return getReceivedReactions(userId).where((r) => !r.isRead).toList();
  }

  /// Get count of unread reactions.
  int getUnreadCount(String userId) {
    return getUnreadReactions(userId).length;
  }

  /// Mark a reaction as read.
  Future<void> markAsRead(String reactionId) async {
    for (final reactions in _receivedReactions.values) {
      final index = reactions.indexWhere((r) => r.id == reactionId);
      if (index != -1) {
        reactions[index] = reactions[index].copyWith(isRead: true);
        _reactionUpdatesController.add(ProfileReactionUpdate(
          type: ReactionUpdateType.read,
          reaction: reactions[index],
        ));
        break;
      }
    }
  }

  /// Mark all reactions as read for a user.
  Future<void> markAllAsRead(String userId) async {
    final reactions = _receivedReactions[userId];
    if (reactions == null) return;

    for (int i = 0; i < reactions.length; i++) {
      if (!reactions[i].isRead) {
        reactions[i] = reactions[i].copyWith(isRead: true);
      }
    }

    _reactionUpdatesController.add(ProfileReactionUpdate(
      type: ReactionUpdateType.allRead,
      reaction: null,
      userId: userId,
    ));
  }

  /// Check if user has already reacted to specific content.
  bool hasReacted({
    required String fromUserId,
    required String toUserId,
    required ReactionContentType contentType,
    required int contentIndex,
  }) {
    final reactions = _sentReactions[fromUserId] ?? [];
    return reactions.any((r) =>
        r.toUserId == toUserId &&
        r.contentType == contentType &&
        r.contentIndex == contentIndex);
  }

  /// Get reaction sent to specific content (if any).
  ProfileReaction? getReaction({
    required String fromUserId,
    required String toUserId,
    required ReactionContentType contentType,
    required int contentIndex,
  }) {
    final reactions = _sentReactions[fromUserId] ?? [];
    try {
      return reactions.firstWhere((r) =>
          r.toUserId == toUserId &&
          r.contentType == contentType &&
          r.contentIndex == contentIndex);
    } catch (e) {
      AppLogger.debug(
          'ProfileReactionService: Reaction not found for user $fromUserId -> $toUserId: $e');
      return null;
    }
  }

  /// Delete a sent reaction.
  Future<void> deleteReaction(String reactionId) async {
    ProfileReaction? deleted;

    for (final entry in _sentReactions.entries) {
      final index = entry.value.indexWhere((r) => r.id == reactionId);
      if (index != -1) {
        deleted = entry.value.removeAt(index);
        break;
      }
    }

    if (deleted != null) {
      // Remove from received too
      final received = _receivedReactions[deleted.toUserId];
      if (received != null) {
        received.removeWhere((r) => r.id == reactionId);
      }

      _reactionUpdatesController.add(ProfileReactionUpdate(
        type: ReactionUpdateType.deleted,
        reaction: deleted,
      ));
    }
  }

  /// Get reactions grouped by profile for a user's received reactions.
  Map<String, List<ProfileReaction>> getReceivedReactionsGroupedByUser(
      String userId) {
    final reactions = getReceivedReactions(userId);
    final grouped = <String, List<ProfileReaction>>{};

    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.fromUserId, () => []);
      grouped[reaction.fromUserId]!.add(reaction);
    }

    return grouped;
  }

  /// Dispose resources.
  void dispose() {
    _reactionUpdatesController.close();
  }
}

/// Types of reaction updates.
enum ReactionUpdateType {
  sent,
  received,
  read,
  allRead,
  deleted,
}

/// A reaction update event.
class ProfileReactionUpdate {
  const ProfileReactionUpdate({
    required this.type,
    this.reaction,
    this.userId,
  });

  final ReactionUpdateType type;
  final ProfileReaction? reaction;
  final String? userId;
}
