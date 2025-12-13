import 'package:equatable/equatable.dart';
import '../../data/models/match.dart';

class MatchesState extends Equatable {
  final List<CrushMatch> matches;
  final bool isLoading;
  final String? errorMessage;
  static const _unset = Object();

  const MatchesState({
    this.matches = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MatchesState copyWith({
    List<CrushMatch>? matches,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [matches, isLoading, errorMessage];
}
