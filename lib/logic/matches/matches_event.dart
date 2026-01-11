import 'package:equatable/equatable.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object?> get props => [];
}

/// Load matches, using cache if available and fresh.
class MatchesLoadRequested extends MatchesEvent {
  const MatchesLoadRequested();
}

/// Force refresh matches, ignoring cache.
class MatchesRefreshRequested extends MatchesEvent {
  const MatchesRefreshRequested();
}

/// Load more matches for pagination.
class MatchesLoadMoreRequested extends MatchesEvent {
  const MatchesLoadMoreRequested();
}
