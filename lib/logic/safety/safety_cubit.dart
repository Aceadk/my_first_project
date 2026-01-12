import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/utils/result.dart';
import '../../data/repositories/chat_repository.dart';

class SafetyState {
  const SafetyState({
    required this.blockedUsers,
    required this.mutedMessages,
    required this.mutedCalls,
    this.errorMessage,
  });

  final Set<String> blockedUsers;
  final Set<String> mutedMessages;
  final Set<String> mutedCalls;
  final String? errorMessage;

  SafetyState copyWith({
    Set<String>? blockedUsers,
    Set<String>? mutedMessages,
    Set<String>? mutedCalls,
    Object? errorMessage = _unset,
  }) {
    return SafetyState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedMessages: mutedMessages ?? this.mutedMessages,
      mutedCalls: mutedCalls ?? this.mutedCalls,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _unset = Object();
}

class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit({
    required SharedPreferences preferences,
    required ChatRepository chatRepository,
  })
      : _preferences = preferences,
        _chatRepository = chatRepository,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;
  final ChatRepository _chatRepository;

  static const _blockedKey = 'safety_blocked';
  static const _mutedMessagesKey = 'safety_muted_messages';
  static const _mutedCallsKey = 'safety_muted_calls';

  static SafetyState _readInitial(SharedPreferences prefs) {
    return SafetyState(
      blockedUsers: prefs.getStringList(_blockedKey)?.toSet() ?? <String>{},
      mutedMessages:
          prefs.getStringList(_mutedMessagesKey)?.toSet() ?? <String>{},
      mutedCalls: prefs.getStringList(_mutedCallsKey)?.toSet() ?? <String>{},
    );
  }

  bool isBlocked(String userId) => state.blockedUsers.contains(userId);
  bool isMessagesMuted(String userId) => state.mutedMessages.contains(userId);
  bool isCallsMuted(String userId) => state.mutedCalls.contains(userId);

  Future<void> toggleBlock(
    String userId, {
    required bool block,
    required String currentUserId,
  }) async {
    if (currentUserId.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Sign in again to manage safety actions.',
      ));
      return;
    }
    final updated = Set<String>.from(state.blockedUsers);
    if (block) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }

    final result = await Result.guard(
      () async {
        if (block) {
          await _chatRepository.blockUser(
            blockerId: currentUserId,
            blockedId: userId,
          );
        } else {
          await _chatRepository.unblockUser(
            blockerId: currentUserId,
            blockedId: userId,
          );
        }
        await _persist(
          state.copyWith(blockedUsers: updated, errorMessage: null),
        );
      },
      logLabel: 'SafetyCubit.toggleBlock',
      fallbackError:
          'Could not ${block ? 'block' : 'unblock'} this user. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    }
  }

  Future<void> toggleMuteMessages(String userId, {required bool mute}) async {
    final updated = Set<String>.from(state.mutedMessages);
    if (mute) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    await _persist(state.copyWith(mutedMessages: updated));
  }

  Future<void> toggleMuteCalls(String userId, {required bool mute}) async {
    final updated = Set<String>.from(state.mutedCalls);
    if (mute) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    await _persist(state.copyWith(mutedCalls: updated));
  }

  Future<void> reportUser(String userId, String reason) async {
    // This is a convenience wrapper for UI that only needs reportedId.
    // For full context (with reporter ID), see reportWithContext below.
    await reportWithContext(
      reporterId: 'anonymous',
      reportedId: userId,
      reason: reason,
    );
  }

  Future<void> reportWithContext({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {
    final result = await Result.guard(
      () => _chatRepository.reportUser(
        reporterId: reporterId,
        reportedId: reportedId,
        reason: reason,
        matchId: matchId,
        messageId: messageId,
        source: source,
        description: description,
      ),
      logLabel: 'SafetyCubit.reportUser',
      fallbackError: 'Could not submit report. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    } else {
      emit(state.copyWith(errorMessage: null));
    }
  }

  Future<void> submitAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    final result = await Result.guard(
      () => _chatRepository.submitSafetyAppeal(
        userId: userId,
        reason: reason,
        targetType: targetType,
        targetId: targetId,
      ),
      logLabel: 'SafetyCubit.submitAppeal',
      fallbackError: 'Could not submit appeal. Please try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    } else {
      emit(state.copyWith(errorMessage: null));
    }
  }

  Future<void> _persist(SafetyState next) async {
    emit(next);
    await _preferences.setStringList(
      _blockedKey,
      next.blockedUsers.toList(),
    );
    await _preferences.setStringList(
      _mutedMessagesKey,
      next.mutedMessages.toList(),
    );
    await _preferences.setStringList(
      _mutedCallsKey,
      next.mutedCalls.toList(),
    );
  }
}
