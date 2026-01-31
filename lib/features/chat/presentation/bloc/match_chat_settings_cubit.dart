import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/core/services/analytics_service.dart';

/// State for per-match chat settings
class MatchChatSettingsState {
  const MatchChatSettingsState({
    required this.matchId,
    required this.settings,
    required this.isPremium,
    this.isLoading = false,
    this.errorMessage,
  });

  final String matchId;
  final ChatSettings settings;
  final bool isPremium;
  final bool isLoading;
  final String? errorMessage;

  /// Get the display string for current retention
  String get retentionDisplay {
    if (isPremium) {
      return '7 days';
    }
    return settings.extendedRetention ? '24 hours' : '1 hour';
  }

  MatchChatSettingsState copyWith({
    ChatSettings? settings,
    bool? isPremium,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MatchChatSettingsState(
      matchId: matchId,
      settings: settings ?? this.settings,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Cubit for managing per-match chat settings.
///
/// Unlike [ChatSettingsCubit] which manages global user settings,
/// this cubit manages settings for a specific chat/match, allowing
/// users to customize retention per conversation.
class MatchChatSettingsCubit extends Cubit<MatchChatSettingsState> {
  MatchChatSettingsCubit({
    required String matchId,
    required ChatSettings initialSettings,
    required bool isPremium,
  }) : super(MatchChatSettingsState(
          matchId: matchId,
          settings: initialSettings,
          isPremium: isPremium,
        ));

  /// Toggle extended retention (24 hours instead of 1 hour) for this specific match.
  Future<void> toggleExtendedRetention(bool value) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Update via Cloud Function for this specific match
      final callable =
          FirebaseFunctions.instance.httpsCallable('updateMatchChatSettings');
      await callable.call<void>({
        'matchId': state.matchId,
        'extendedRetention': value,
      });

      // Update local state
      final newSettings = state.settings.copyWith(extendedRetention: value);
      emit(state.copyWith(settings: newSettings, isLoading: false));

      // Log analytics
      await AnalyticsService.instance.logNotificationSettingsChanged(
        type: 'match_chat_retention',
        enabled: value,
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update settings. Please try again.',
      ));
    }
  }

  /// Clear any error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
