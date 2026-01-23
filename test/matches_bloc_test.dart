import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';

void main() {
  test('emits error state when fetching matches fails', () async {
    final bloc = MatchesBloc(
      chatRepository: _ThrowingChatRepository(),
      authRepository: _StubAuthRepository(),
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
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
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

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<MessageRequest?> sendMessageRequest({
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserName,
    String? toUserPhotoUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) {
    throw UnimplementedError();
  }
}

// Helper extension for the tests
extension on PaginatedResult<CrushMatch> {
  // Can be used if we need helpers
}

/// Stub AuthRepository for testing - emits no auth state changes.
class _StubAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  Stream<CrushUser?> authStateChanges() => const Stream.empty();

  @override
  Future<void> bootstrapSession() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> acceptTermsAndConditions() {
    throw UnimplementedError();
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
