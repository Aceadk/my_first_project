import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_project/data/models/match.dart';
import 'package:my_first_project/data/models/message.dart';
import 'package:my_first_project/data/repositories/chat_repository.dart';
import 'package:my_first_project/logic/matches/matches_bloc.dart';
import 'package:my_first_project/logic/matches/matches_event.dart';
import 'package:my_first_project/logic/matches/matches_state.dart';

void main() {
  test('emits error state when fetching matches fails', () async {
    final bloc = MatchesBloc(
      chatRepository: _ThrowingChatRepository(),
      userId: 'u1',
    );

    bloc.add(const MatchesLoadRequested());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MatchesState>().having((s) => s.isLoading, 'isLoading', true),
        isA<MatchesState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'error', 'Could not load matches.'),
      ]),
    );

    await bloc.close();
  });
}

class _ThrowingChatRepository implements ChatRepository {
  @override
  Future<void> blockUser({required String blockerId, required String blockedId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) {
    throw Exception('network failed');
  }

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}
