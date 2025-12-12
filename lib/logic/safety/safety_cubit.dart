import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafetyState {
  const SafetyState({
    required this.blockedUsers,
    required this.mutedMessages,
    required this.mutedCalls,
  });

  final Set<String> blockedUsers;
  final Set<String> mutedMessages;
  final Set<String> mutedCalls;

  SafetyState copyWith({
    Set<String>? blockedUsers,
    Set<String>? mutedMessages,
    Set<String>? mutedCalls,
  }) {
    return SafetyState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedMessages: mutedMessages ?? this.mutedMessages,
      mutedCalls: mutedCalls ?? this.mutedCalls,
    );
  }
}

class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;

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

  Future<void> toggleBlock(String userId, {required bool block}) async {
    final updated = Set<String>.from(state.blockedUsers);
    if (block) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    await _persist(state.copyWith(blockedUsers: updated));
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
    // Placeholder hook: send report to backend in a real app.
    // Here we simply log it in memory to keep UI responsive.
    // You can integrate analytics or API call here.
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
