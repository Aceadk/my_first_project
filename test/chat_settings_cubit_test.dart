import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/features/chat/presentation/bloc/match_chat_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/chat_settings_cubit.dart';

void main() {
  group('ChatSettingsState', () {
    test('retentionDisplay reflects premium and free settings', () {
      const freeDefault = ChatSettingsState(
        settings: ChatSettings(extendedRetention: false),
        isPremium: false,
      );
      const freeExtended = ChatSettingsState(
        settings: ChatSettings(extendedRetention: true),
        isPremium: false,
      );
      const premium = ChatSettingsState(
        settings: ChatSettings(extendedRetention: false),
        isPremium: true,
      );

      expect(freeDefault.retentionDisplay, '1 hour');
      expect(freeExtended.retentionDisplay, '24 hours');
      expect(premium.retentionDisplay, '7 days');
    });

    test('copyWith updates fields', () {
      const state = ChatSettingsState(
        settings: ChatSettings(extendedRetention: false),
        isPremium: false,
      );

      final updated = state.copyWith(
        settings: const ChatSettings(extendedRetention: true),
        isLoading: true,
        errorMessage: 'error',
      );

      expect(updated.settings.extendedRetention, isTrue);
      expect(updated.isLoading, isTrue);
      expect(updated.errorMessage, 'error');
      expect(updated.isPremium, isFalse);
    });
  });

  group('ChatSettingsCubit', () {
    test('toggleExtendedRetention surfaces error when backend call fails', () async {
      final cubit = ChatSettingsCubit(
        initialSettings: const ChatSettings(extendedRetention: false),
        isPremium: false,
      );

      await cubit.toggleExtendedRetention(true);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.settings.extendedRetention, isFalse);

      await cubit.close();
    });

    test('clearError removes error message', () async {
      final cubit = ChatSettingsCubit(
        initialSettings: const ChatSettings(extendedRetention: false),
        isPremium: false,
      );

      await cubit.toggleExtendedRetention(true);
      expect(cubit.state.errorMessage, isNotNull);

      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });
  });

  group('MatchChatSettingsState', () {
    test('retentionDisplay reflects premium and free settings', () {
      const freeDefault = MatchChatSettingsState(
        matchId: 'match-1',
        settings: ChatSettings(extendedRetention: false),
        isPremium: false,
      );
      const freeExtended = MatchChatSettingsState(
        matchId: 'match-1',
        settings: ChatSettings(extendedRetention: true),
        isPremium: false,
      );
      const premium = MatchChatSettingsState(
        matchId: 'match-1',
        settings: ChatSettings(extendedRetention: false),
        isPremium: true,
      );

      expect(freeDefault.retentionDisplay, '1 hour');
      expect(freeExtended.retentionDisplay, '24 hours');
      expect(premium.retentionDisplay, '7 days');
    });
  });

  group('MatchChatSettingsCubit', () {
    test('toggleExtendedRetention surfaces error when backend call fails', () async {
      final cubit = MatchChatSettingsCubit(
        matchId: 'match-1',
        initialSettings: const ChatSettings(extendedRetention: false),
        isPremium: false,
      );

      await cubit.toggleExtendedRetention(true);

      expect(cubit.state.matchId, 'match-1');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.settings.extendedRetention, isFalse);

      await cubit.close();
    });

    test('clearError removes error message', () async {
      final cubit = MatchChatSettingsCubit(
        matchId: 'match-1',
        initialSettings: const ChatSettings(extendedRetention: false),
        isPremium: false,
      );

      await cubit.toggleExtendedRetention(true);
      expect(cubit.state.errorMessage, isNotNull);

      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });
  });
}
