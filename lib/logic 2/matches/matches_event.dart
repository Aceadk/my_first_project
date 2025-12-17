import 'package:equatable/equatable.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object?> get props => [];
}

class MatchesLoadRequested extends MatchesEvent {
  const MatchesLoadRequested();
}
