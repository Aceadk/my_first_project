import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message_request.dart';

class MessageRequestsState extends Equatable {
  final List<MessageRequest> requests;
  final bool isLoading;
  final String? errorMessage;

  const MessageRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MessageRequestsState copyWith({
    List<MessageRequest>? requests,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MessageRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [requests, isLoading, errorMessage];
}
