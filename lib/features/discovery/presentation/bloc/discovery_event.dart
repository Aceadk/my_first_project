import 'package:equatable/equatable.dart';

abstract class DiscoveryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoveryDeckRequested extends DiscoveryEvent {
  final String userId;
  DiscoveryDeckRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DiscoverySwipedRight extends DiscoveryEvent {
  final String userId;
  final String targetUserId;
  final String? attachedMessage;
  DiscoverySwipedRight({
    required this.userId,
    required this.targetUserId,
    this.attachedMessage,
  });

  @override
  List<Object?> get props => [userId, targetUserId, attachedMessage];
}

class DiscoverySwipedLeft extends DiscoveryEvent {
  final String userId;
  final String targetUserId;
  DiscoverySwipedLeft({required this.userId, required this.targetUserId});

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Request to load more profiles when approaching end of deck.
class DiscoveryLoadMoreRequested extends DiscoveryEvent {
  final String userId;
  DiscoveryLoadMoreRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Clear the new match after showing celebration modal.
class DiscoveryMatchCelebrationShown extends DiscoveryEvent {}

/// Super Like a profile (higher priority, limited daily uses).
class DiscoverySuperLiked extends DiscoveryEvent {
  final String userId;
  final String targetUserId;
  DiscoverySuperLiked({required this.userId, required this.targetUserId});

  @override
  List<Object?> get props => [userId, targetUserId];
}

/// Request to undo/rewind the last swipe (premium only).
class DiscoveryRewindRequested extends DiscoveryEvent {
  final String userId;
  DiscoveryRewindRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Reset discovery state on logout.
/// CRITICAL: Prevents data leakage to next user.
class DiscoveryResetRequested extends DiscoveryEvent {}
