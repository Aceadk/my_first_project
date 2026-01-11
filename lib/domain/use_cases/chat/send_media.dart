import '../../../core/result.dart';
import '../../../data/models/message.dart';
import '../../../data/models/subscription.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../use_case.dart';

/// Parameters for sending media.
class SendMediaParams {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String filePath;
  final MessageType type;
  final int currentMediaCount;
  final bool isMediaEnabled;

  const SendMediaParams({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.filePath,
    required this.type,
    required this.currentMediaCount,
    required this.isMediaEnabled,
  });
}

/// Result of a media send operation.
class SendMediaResult {
  final bool success;
  final String? errorMessage;
  final bool limitReached;

  const SendMediaResult({
    required this.success,
    this.errorMessage,
    this.limitReached = false,
  });
}

/// Use case for sending media (images, voice notes).
///
/// Business logic:
/// - Checks if media sending is enabled for this match
/// - Enforces media limits for free users (8 max)
/// - Uploads media and sends message
class SendMediaUseCase extends UseCase<SendMediaResult, SendMediaParams> {
  static const int _freeUserMediaLimit = 8;

  final ChatRepository _chatRepository;
  final SubscriptionRepository _subscriptionRepository;

  SendMediaUseCase(this._chatRepository, this._subscriptionRepository);

  @override
  Future<Result<SendMediaResult>> call(SendMediaParams params) async {
    // Check if media sending is enabled
    if (!params.isMediaEnabled) {
      return const Result.success(SendMediaResult(
        success: false,
        errorMessage: 'Media sharing is disabled for this chat.',
      ));
    }

    // Check subscription plan for media limits
    final planResult = await Result.guard(
      () => _subscriptionRepository.getCurrentPlan(),
      logLabel: 'SendMediaUseCase.getPlan',
    );

    final plan = planResult.data ?? SubscriptionPlan.free;

    // Enforce limit for free users
    if (plan.isFree && params.currentMediaCount >= _freeUserMediaLimit) {
      return const Result.success(SendMediaResult(
        success: false,
        errorMessage: 'Free users can send up to 8 media messages. Upgrade to Plus for unlimited.',
        limitReached: true,
      ));
    }

    // Upload media
    final uploadResult = await Result.guard(
      () => _chatRepository.uploadMedia(
        matchId: params.matchId,
        filePath: params.filePath,
        type: params.type,
      ),
      logLabel: 'SendMediaUseCase.upload',
      fallbackError: 'Could not upload media. Please try again.',
    );

    if (!uploadResult.isSuccess) {
      return Result.success(SendMediaResult(
        success: false,
        errorMessage: uploadResult.errorMessage,
      ));
    }

    final mediaUrl = uploadResult.data!;

    // Send the message with media URL
    final sendResult = await Result.guard(
      () => _chatRepository.sendMessage(
        matchId: params.matchId,
        fromUserId: params.fromUserId,
        toUserId: params.toUserId,
        content: mediaUrl,
        type: params.type,
      ),
      logLabel: 'SendMediaUseCase.send',
      fallbackError: 'Could not send media. Please try again.',
    );

    if (!sendResult.isSuccess) {
      return Result.success(SendMediaResult(
        success: false,
        errorMessage: sendResult.errorMessage,
      ));
    }

    return const Result.success(SendMediaResult(success: true));
  }
}
