import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// State for badge counts across the app.
class BadgeCountState extends Equatable {
  const BadgeCountState({
    this.unreadChats = 0,
    this.newMatches = 0,
  });

  /// Total unread chat messages.
  final int unreadChats;

  /// New matches that haven't been viewed.
  final int newMatches;

  /// Total badge count for app icon.
  int get totalCount => unreadChats + newMatches;

  BadgeCountState copyWith({
    int? unreadChats,
    int? newMatches,
  }) {
    return BadgeCountState(
      unreadChats: unreadChats ?? this.unreadChats,
      newMatches: newMatches ?? this.newMatches,
    );
  }

  @override
  List<Object?> get props => [unreadChats, newMatches];
}

/// Cubit that tracks unread message and match counts for badges.
///
/// This is updated by the screens that have access to the data:
/// - [ChatListScreen] updates [unreadChats]
/// - [MatchesScreen] updates [newMatches]
class BadgeCounterCubit extends Cubit<BadgeCountState> {
  BadgeCounterCubit() : super(const BadgeCountState());

  /// Update the unread chat count.
  void updateUnreadChats(int count) {
    if (count != state.unreadChats) {
      emit(state.copyWith(unreadChats: count));
    }
  }

  /// Update the new matches count.
  void updateNewMatches(int count) {
    if (count != state.newMatches) {
      emit(state.copyWith(newMatches: count));
    }
  }

  /// Clear all badge counts.
  void clear() {
    emit(const BadgeCountState());
  }
}
