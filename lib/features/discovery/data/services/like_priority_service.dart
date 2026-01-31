import 'dart:async';
import 'dart:math';
import '../models/like_priority.dart';

/// Service for managing priority likes and queue position.
class LikePriorityService {
  LikePriorityService._();
  static final LikePriorityService instance = LikePriorityService._();

  final _likeController = StreamController<LikePriority>.broadcast();
  Stream<LikePriority> get priorityLikeStream => _likeController.stream;

  final Map<String, LikePriority> _sentLikes = {};
  final Map<String, LikePriority> _receivedLikes = {};

  /// Send a priority like.
  Future<LikePriority> sendPriorityLike({
    required String fromUserId,
    required String toUserId,
    required LikePriorityLevel priority,
    bool superLike = false,
    bool boosted = false,
    Duration? priorityDuration,
  }) async {
    final like = LikePriority(
      likeId: _generateId(),
      fromUserId: fromUserId,
      toUserId: toUserId,
      priority: priority,
      createdAt: DateTime.now(),
      superLike: superLike,
      boosted: boosted,
      expiresAt: priorityDuration != null
          ? DateTime.now().add(priorityDuration)
          : null,
    );

    _sentLikes[like.likeId] = like;
    _likeController.add(like);

    // In production, sync with backend
    await _syncLike(like);

    return like;
  }

  /// Get received likes sorted by display score.
  Future<List<LikePriority>> getReceivedLikes(String userId) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 300));

    final likes = _receivedLikes.values
        .where((like) => like.toUserId == userId && like.isActive)
        .toList()
      ..sort((a, b) => b.displayScore.compareTo(a.displayScore));

    return likes;
  }

  /// Get sent likes.
  Future<List<LikePriority>> getSentLikes(String userId) async {
    return _sentLikes.values
        .where((like) => like.fromUserId == userId)
        .toList();
  }

  /// Check if user has been priority liked.
  bool hasPriorityLikeFrom(String fromUserId, String toUserId) {
    return _sentLikes.values.any(
      (like) =>
          like.fromUserId == fromUserId &&
          like.toUserId == toUserId &&
          like.isActive,
    );
  }

  /// Simulate receiving a like (for demo).
  void simulateReceivedLike(LikePriority like) {
    _receivedLikes[like.likeId] = like;
    _likeController.add(like);
  }

  /// Calculate the cost of a priority like.
  int calculateCost(LikePriorityLevel level, {bool superLike = false}) {
    int cost = 0;

    switch (level) {
      case LikePriorityLevel.standard:
        cost = 0;
        break;
      case LikePriorityLevel.premium:
        cost = 5;
        break;
      case LikePriorityLevel.platinum:
        cost = 15;
        break;
      case LikePriorityLevel.spotlight:
        cost = 30;
        break;
    }

    if (superLike) cost += 10;

    return cost;
  }

  Future<void> _syncLike(LikePriority like) async {
    // In production, sync with backend
  }

  String _generateId() {
    return 'like_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void dispose() {
    _likeController.close();
  }
}
