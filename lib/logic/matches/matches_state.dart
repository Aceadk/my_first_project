import 'package:equatable/equatable.dart';
import '../../data/models/match.dart';

class MatchesState extends Equatable {
  final List<CrushMatch> matches;
  final bool isLoading;
  final String? errorMessage;

  const MatchesState({
    this.matches = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MatchesState copyWith({
    List<CrushMatch>? matches,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [matches, isLoading, errorMessage];
}
