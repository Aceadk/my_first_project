import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';

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
  Future<void> blockUser(
      {required String blockerId, required String blockedId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) {
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
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) {
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
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) => const Stream.empty();

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {}

  @override
  Stream<bool> watchPresence(String userId) => const Stream.empty();

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {}

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) => const Stream.empty();

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {}

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

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) {
    throw UnimplementedError();
  }
}

// Helper extension for the tests
extension on PaginatedResult<CrushMatch> {
  // Can be used if we need helpers
}
