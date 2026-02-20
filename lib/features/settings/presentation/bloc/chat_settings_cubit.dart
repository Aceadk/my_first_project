import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/error_messages.dart';

/// State for chat settings
class ChatSettingsState {
  const ChatSettingsState({
    required this.settings,
    required this.isPremium,
    this.isLoading = false,
    this.errorMessage,
  });

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

  ChatSettingsState copyWith({
    ChatSettings? settings,
    bool? isPremium,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatSettingsState(
      settings: settings ?? this.settings,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Cubit for managing chat settings
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit({
    required ChatSettings initialSettings,
    required bool isPremium,
  }) : super(
         ChatSettingsState(settings: initialSettings, isPremium: isPremium),
       );

  /// Toggle extended retention (24 hours instead of 1 hour)
  Future<void> toggleExtendedRetention(bool value) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Update via Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable(
        'updateChatSettings',
      );
      await callable.call<void>({'extendedRetention': value});

      // Update local state
      final newSettings = state.settings.copyWith(extendedRetention: value);
      emit(state.copyWith(settings: newSettings, isLoading: false));

      // Log analytics
      await AnalyticsService.instance.logNotificationSettingsChanged(
        type: 'chat_retention',
        enabled: value,
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: ErrorMessages.generic),
      );
    }
  }

  /// Clear any error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
