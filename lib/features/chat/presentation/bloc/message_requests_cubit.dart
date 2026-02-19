import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'message_requests_state.dart';

/// Cubit for managing message requests with accept/decline functionality.
///
/// Features:
/// - Load and refresh message requests
/// - Accept (like back) → triggers match creation
/// - Decline → removes the request
/// - Real-time countdown display support
class MessageRequestsCubit extends Cubit<MessageRequestsState> {
  final ChatRepository chatRepository;
  final DiscoveryRepository discoveryRepository;
  final String userId;

  MessageRequestsCubit({
    required this.chatRepository,
    required this.discoveryRepository,
    required this.userId,
  }) : super(const MessageRequestsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () => chatRepository.fetchMessageRequests(userId),
      logLabel: 'ChatRepository.fetchMessageRequests',
      fallbackError: 'Could not load message requests.',
    );
    if (result.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        requests: result.data ?? const [],
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  Future<void> refresh() async {
    await load();
  }

  /// Accept a message request by liking the sender back.
  /// This triggers match creation and automatic message migration.
  Future<void> acceptRequest(MessageRequest request) async {
    // Only accept inbound requests
    if (!request.isInboundFor(userId)) return;

    emit(state.copyWith(
      actionRequestId: request.id,
      actionStatus: RequestActionStatus.loading,
    ));

    try {
      // Like the sender back - this will create a match if mutual
      final match = await discoveryRepository.swipeRight(
        userId: userId,
        targetUserId: request.fromUserId,
      );

      // Remove the request from local state
      final updatedRequests =
          state.requests.where((r) => r.id != request.id).toList();

      if (match != null) {
        // Match created! The onMatchCreated Cloud Function will auto-migrate the message.
        emit(state.copyWith(
          requests: updatedRequests,
          actionStatus: RequestActionStatus.success,
          showMatchNotification: true,
          matchedUserName: request.fromUserName ?? 'Someone',
        ));
      } else {
        // Like recorded but no match yet (they haven't liked us back)
        // This shouldn't happen for message requests since sender already liked
        emit(state.copyWith(
          requests: updatedRequests,
          actionStatus: RequestActionStatus.success,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: RequestActionStatus.error,
        actionErrorMessage: 'Could not accept request: $e',
      ));
    }
  }

  /// Decline a message request by removing it.
  Future<void> declineRequest(MessageRequest request) async {
    emit(state.copyWith(
      actionRequestId: request.id,
      actionStatus: RequestActionStatus.loading,
    ));

    try {
      // Delete the message request from Firestore
      final pairKey = _pairKey(request.fromUserId, request.toUserId);
      await FirebaseFirestore.instance
          .collection('message_requests')
          .doc(pairKey)
          .delete();

      // Remove from local state
      final updatedRequests =
          state.requests.where((r) => r.id != request.id).toList();

      emit(state.copyWith(
        requests: updatedRequests,
        actionStatus: RequestActionStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: RequestActionStatus.error,
        actionErrorMessage: 'Could not decline request: $e',
      ));
    }
  }

  /// Clear the match notification flag after showing it.
  void clearMatchNotification() {
    emit(state.clearAction());
  }

  /// Clear any action state.
  void clearAction() {
    emit(state.clearAction());
  }

  /// Generate consistent pair key for two users.
  String _pairKey(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA|$userB' : '$userB|$userA';
  }
}
