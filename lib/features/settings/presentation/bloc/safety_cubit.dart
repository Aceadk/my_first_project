import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';

/// Minimal profile info for safety displays (blocked users, etc.)
class SafetyProfileInfo {
  const SafetyProfileInfo({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? photoUrl;

  factory SafetyProfileInfo.fromProfile(Profile profile) {
    return SafetyProfileInfo(
      id: profile.id,
      name: profile.publicDisplayName,
      photoUrl: profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null,
    );
  }

  factory SafetyProfileInfo.placeholder(String id) {
    return SafetyProfileInfo(
      id: id,
      name: 'User $id',
      photoUrl: null,
    );
  }
}

class SafetyState {
  const SafetyState({
    required this.blockedUsers,
    required this.mutedMessages,
    required this.mutedCalls,
    this.reportedUsers = const {},
    this.profileCache = const {},
    this.isLoadingProfiles = false,
    this.errorMessage,
  });

  final Set<String> blockedUsers;
  final Set<String> mutedMessages;
  final Set<String> mutedCalls;
  /// Map of reported user IDs to the timestamp when they were reported.
  final Map<String, DateTime> reportedUsers;
  final Map<String, SafetyProfileInfo> profileCache;
  final bool isLoadingProfiles;
  final String? errorMessage;

  SafetyState copyWith({
    Set<String>? blockedUsers,
    Set<String>? mutedMessages,
    Set<String>? mutedCalls,
    Map<String, DateTime>? reportedUsers,
    Map<String, SafetyProfileInfo>? profileCache,
    bool? isLoadingProfiles,
    Object? errorMessage = _unset,
  }) {
    return SafetyState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedMessages: mutedMessages ?? this.mutedMessages,
      mutedCalls: mutedCalls ?? this.mutedCalls,
      reportedUsers: reportedUsers ?? this.reportedUsers,
      profileCache: profileCache ?? this.profileCache,
      isLoadingProfiles: isLoadingProfiles ?? this.isLoadingProfiles,
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
    required DiscoveryRepository discoveryRepository,
  })
      : _preferences = preferences,
        _chatRepository = chatRepository,
        _discoveryRepository = discoveryRepository,
        super(_readInitial(preferences));

  final SharedPreferences _preferences;
  final ChatRepository _chatRepository;
  final DiscoveryRepository _discoveryRepository;

  static const _blockedKey = 'safety_blocked';
  static const _mutedMessagesKey = 'safety_muted_messages';
  static const _mutedCallsKey = 'safety_muted_calls';
  static const _reportedUsersKey = 'safety_reported_users';
  static const _reportHideDays = 10;

  static SafetyState _readInitial(SharedPreferences prefs) {
    // Parse reported users from stored string format: "userId:timestamp"
    final reportedList = prefs.getStringList(_reportedUsersKey) ?? [];
    final reportedUsers = <String, DateTime>{};
    for (final entry in reportedList) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final userId = parts[0];
        final timestamp = DateTime.tryParse(parts[1]);
        if (timestamp != null) {
          reportedUsers[userId] = timestamp;
        }
      }
    }

    return SafetyState(
      blockedUsers: prefs.getStringList(_blockedKey)?.toSet() ?? <String>{},
      mutedMessages:
          prefs.getStringList(_mutedMessagesKey)?.toSet() ?? <String>{},
      mutedCalls: prefs.getStringList(_mutedCallsKey)?.toSet() ?? <String>{},
      reportedUsers: reportedUsers,
    );
  }

  bool isBlocked(String userId) => state.blockedUsers.contains(userId);
  bool isMessagesMuted(String userId) => state.mutedMessages.contains(userId);
  bool isCallsMuted(String userId) => state.mutedCalls.contains(userId);

  /// Check if a user was reported within the last 10 days.
  bool isReportedRecently(String userId) {
    final reportedAt = state.reportedUsers[userId];
    if (reportedAt == null) return false;
    final daysSinceReport = DateTime.now().difference(reportedAt).inDays;
    return daysSinceReport < _reportHideDays;
  }

  /// Check if a user should be hidden from the feed (blocked or recently reported).
  bool shouldHideFromFeed(String userId) {
    return isBlocked(userId) || isReportedRecently(userId);
  }

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
          await AnalyticsService.instance.logUserBlocked();
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
      await AnalyticsService.instance.logUserReported(reason: reason);
      // Add user to reported list to hide them for 10 days
      final updatedReported = Map<String, DateTime>.from(state.reportedUsers);
      updatedReported[reportedId] = DateTime.now();
      await _persist(state.copyWith(
        reportedUsers: updatedReported,
        errorMessage: null,
      ));
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

  /// Fetch profile data for all blocked/muted users.
  /// Call this when entering the safety screen.
  Future<void> loadProfilesForSafetyUsers() async {
    // Collect all user IDs that need profile info
    final allIds = <String>{
      ...state.blockedUsers,
      ...state.mutedMessages,
      ...state.mutedCalls,
    };

    // Filter out already cached profiles
    final idsToFetch = allIds.where((id) => !state.profileCache.containsKey(id)).toList();

    if (idsToFetch.isEmpty) return;

    emit(state.copyWith(isLoadingProfiles: true));

    final newCache = Map<String, SafetyProfileInfo>.from(state.profileCache);

    for (final userId in idsToFetch) {
      try {
        final profile = await _discoveryRepository.fetchProfileById(userId);
        if (profile != null) {
          newCache[userId] = SafetyProfileInfo.fromProfile(profile);
        } else {
          // Use placeholder if profile not found
          newCache[userId] = SafetyProfileInfo.placeholder(userId);
        }
      } catch (_) {
        // Use placeholder on error
        newCache[userId] = SafetyProfileInfo.placeholder(userId);
      }
    }

    emit(state.copyWith(
      profileCache: newCache,
      isLoadingProfiles: false,
    ));
  }

  /// Get profile info for a user, with fallback to ID
  SafetyProfileInfo? getProfileInfo(String userId) {
    return state.profileCache[userId];
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
    // Store reported users as "userId:timestamp" format
    await _preferences.setStringList(
      _reportedUsersKey,
      next.reportedUsers.entries
          .map((e) => '${e.key}:${e.value.toIso8601String()}')
          .toList(),
    );
  }
}
