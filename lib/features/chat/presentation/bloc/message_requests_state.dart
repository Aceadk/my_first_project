import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message_request.dart';

/// Represents the status of an action on a message request.
enum RequestActionStatus { idle, loading, success, error }

class MessageRequestsState extends Equatable {
  final List<MessageRequest> requests;
  final bool isLoading;
  final String? errorMessage;

  /// Track which request is being acted on (accept/decline).
  final String? actionRequestId;
  final RequestActionStatus actionStatus;
  final String? actionErrorMessage;

  /// For showing match notification after successful accept.
  final bool showMatchNotification;
  final String? matchedUserName;

  const MessageRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.errorMessage,
    this.actionRequestId,
    this.actionStatus = RequestActionStatus.idle,
    this.actionErrorMessage,
    this.showMatchNotification = false,
    this.matchedUserName,
  });

  /// Check if a specific request is currently being processed.
  bool isProcessing(String requestId) =>
      actionRequestId == requestId && actionStatus == RequestActionStatus.loading;

  MessageRequestsState copyWith({
    List<MessageRequest>? requests,
    bool? isLoading,
    String? errorMessage,
    String? actionRequestId,
    RequestActionStatus? actionStatus,
    String? actionErrorMessage,
    bool? showMatchNotification,
    String? matchedUserName,
  }) {
    return MessageRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      actionRequestId: actionRequestId,
      actionStatus: actionStatus ?? this.actionStatus,
      actionErrorMessage: actionErrorMessage,
      showMatchNotification: showMatchNotification ?? this.showMatchNotification,
      matchedUserName: matchedUserName,
    );
  }

  /// Reset action state.
  MessageRequestsState clearAction() {
    return MessageRequestsState(
      requests: requests,
      isLoading: isLoading,
      errorMessage: errorMessage,
      actionRequestId: null,
      actionStatus: RequestActionStatus.idle,
      actionErrorMessage: null,
      showMatchNotification: false,
      matchedUserName: null,
    );
  }

  @override
  List<Object?> get props => [
        requests,
        isLoading,
        errorMessage,
        actionRequestId,
        actionStatus,
        actionErrorMessage,
        showMatchNotification,
        matchedUserName,
      ];
}
