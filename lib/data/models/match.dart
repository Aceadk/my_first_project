import 'package:equatable/equatable.dart';

enum MatchStatus { pending, mutual, rejected, unmatched }

class CrushMatch extends Equatable {
  final String id;
  final String userId;
  final String otherUserId;
  final MatchStatus status;
  final int preMatchMessageRequestsCount;
  final bool pinnedForUser;

  const CrushMatch({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.status,
    required this.preMatchMessageRequestsCount,
    required this.pinnedForUser,
  });

  bool get isMutual => status == MatchStatus.mutual;

  CrushMatch copyWith({
    MatchStatus? status,
    int? preMatchMessageRequestsCount,
    bool? pinnedForUser,
  }) {
    return CrushMatch(
      id: id,
      userId: userId,
      otherUserId: otherUserId,
      status: status ?? this.status,
      preMatchMessageRequestsCount:
          preMatchMessageRequestsCount ?? this.preMatchMessageRequestsCount,
      pinnedForUser: pinnedForUser ?? this.pinnedForUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        otherUserId,
        status,
        preMatchMessageRequestsCount,
        pinnedForUser,
      ];
}
