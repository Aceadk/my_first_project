import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for real-time indicators: typing, presence, and media permissions.
class RealtimeState extends Equatable {
  final Set<String> typingUserIds;
  final bool otherUserOnline;
  final bool mediaSendingEnabled;

  const RealtimeState({
    this.typingUserIds = const {},
    this.otherUserOnline = false,
    this.mediaSendingEnabled = true,
  });

  RealtimeState copyWith({
    Set<String>? typingUserIds,
    bool? otherUserOnline,
    bool? mediaSendingEnabled,
  }) {
    return RealtimeState(
      typingUserIds: typingUserIds ?? this.typingUserIds,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      mediaSendingEnabled: mediaSendingEnabled ?? this.mediaSendingEnabled,
    );
  }

  @override
  List<Object?> get props => [typingUserIds, otherUserOnline, mediaSendingEnabled];
}

/// Cubit managing real-time chat indicators:
/// - Typing indicators (which users are currently typing)
/// - Presence status (whether the other user is online)
/// - Media sending permissions
class RealtimeStateCubit extends Cubit<RealtimeState> {
  RealtimeStateCubit() : super(const RealtimeState());

  /// Update the set of currently typing user IDs.
  void updateTyping(Set<String> typingUserIds) {
    emit(state.copyWith(typingUserIds: typingUserIds));
  }

  /// Update whether the other user is online.
  void updatePresence(bool isOnline) {
    emit(state.copyWith(otherUserOnline: isOnline));
  }

  /// Update whether media sending is enabled for this chat.
  void updateMediaEnabled(bool enabled) {
    emit(state.copyWith(mediaSendingEnabled: enabled));
  }

  /// Reset to initial state (used on logout / chat close).
  void reset() {
    emit(const RealtimeState());
  }
}
