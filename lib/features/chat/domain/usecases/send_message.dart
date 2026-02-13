import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';

/// Parameters for sending a text message.
class SendMessageParams {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String content;

  const SendMessageParams({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
  });
}

/// Use case for sending a text message.
///
/// Handles message validation and delivery.
class SendMessageUseCase extends UseCase<void, SendMessageParams>
    with ValidatingUseCase<void, SendMessageParams> {
  final ChatRepository _chatRepository;

  SendMessageUseCase(this._chatRepository);

  @override
  String? validate(SendMessageParams params) {
    if (params.content.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (params.content.length > 5000) {
      return 'Message is too long';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(SendMessageParams params) async {
    // Stop typing indicator before sending
    await _chatRepository.setTyping(
      matchId: params.matchId,
      userId: params.fromUserId,
      isTyping: false,
    );

    return Result.guard(
      () => _chatRepository.sendMessage(
        matchId: params.matchId,
        fromUserId: params.fromUserId,
        toUserId: params.toUserId,
        content: params.content.trim(),
        type: MessageType.text,
      ),
      logLabel: 'SendMessageUseCase',
      fallbackError: 'Could not send message. Please try again.',
    );
  }
}
