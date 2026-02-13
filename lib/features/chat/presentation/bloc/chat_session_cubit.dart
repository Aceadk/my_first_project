import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';

/// State for chat session lifecycle: unmatch status, E2EE toggle, other user photo.
class ChatSessionState extends Equatable {
  final bool isUnmatching;
  final bool isUnmatched;
  final String? otherUserPhotoUrl;
  final bool isE2eeEnabled;
  final String? errorMessage;

  const ChatSessionState({
    this.isUnmatching = false,
    this.isUnmatched = false,
    this.otherUserPhotoUrl,
    this.isE2eeEnabled = true,
    this.errorMessage,
  });

  ChatSessionState copyWith({
    bool? isUnmatching,
    bool? isUnmatched,
    String? otherUserPhotoUrl,
    bool? isE2eeEnabled,
    String? errorMessage,
  }) {
    return ChatSessionState(
      isUnmatching: isUnmatching ?? this.isUnmatching,
      isUnmatched: isUnmatched ?? this.isUnmatched,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      isE2eeEnabled: isE2eeEnabled ?? this.isE2eeEnabled,
      // errorMessage intentionally uses direct value (null clears it)
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isUnmatching,
        isUnmatched,
        otherUserPhotoUrl,
        isE2eeEnabled,
        errorMessage,
      ];
}

/// Cubit managing chat session lifecycle:
/// - Unmatch flow
/// - E2EE toggle
/// - Other user photo URL
class ChatSessionCubit extends Cubit<ChatSessionState> {
  final ChatRepository chatRepository;

  // E2EE is enabled by default (recommended for privacy)
  static const bool _e2eeEnabledDefault =
      bool.fromEnvironment('ENABLE_CHAT_E2EE', defaultValue: true);

  bool _e2eeEnabled = _e2eeEnabledDefault;

  ChatSessionCubit({required this.chatRepository})
      : super(const ChatSessionState()) {
    chatRepository.setE2eeEnabled(_e2eeEnabled);
  }

  /// Initialize session state when chat opens.
  void openSession({String? otherUserPhotoUrl}) {
    emit(state.copyWith(
      isUnmatching: false,
      isUnmatched: false,
      otherUserPhotoUrl: otherUserPhotoUrl,
      isE2eeEnabled: _e2eeEnabled,
      errorMessage: null,
    ));
  }

  /// Request to unmatch from a user.
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    emit(state.copyWith(isUnmatching: true, errorMessage: null));
    final result = await Result.guard(
      () => chatRepository.unmatch(matchId: matchId, userId: userId),
      logLabel: 'ChatRepository.unmatch',
      fallbackError: 'Could not unmatch right now.',
    );

    if (result.isSuccess) {
      AnalyticsService.instance.logUnmatch(matchId: matchId);
    }

    emit(state.copyWith(
      isUnmatching: false,
      isUnmatched: result.isSuccess ? true : state.isUnmatched,
      errorMessage: result.errorMessage,
    ));
  }

  /// Toggle end-to-end encryption for chat messages.
  void toggleE2ee(bool enabled) {
    _e2eeEnabled = enabled;
    chatRepository.setE2eeEnabled(enabled);
    AppLogger.debug('ChatSessionCubit: E2EE ${enabled ? "enabled" : "disabled"}');
    emit(state.copyWith(isE2eeEnabled: enabled));
  }

  /// Whether E2EE is currently enabled (for use by MessageHandlingBloc).
  bool get isE2eeEnabled => _e2eeEnabled;

  /// Reset to initial state (used on logout).
  void reset() {
    emit(const ChatSessionState());
  }
}
