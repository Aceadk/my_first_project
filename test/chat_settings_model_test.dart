import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/shared/dto/chat_settings.dart';

void main() {
  group('ChatSettings', () {
    test('default settings use one-hour retention', () {
      final settings = ChatSettings.defaultSettings();

      expect(settings.extendedRetention, isFalse);
      expect(settings.retentionDuration, MessageRetention.oneHour);
      expect(settings.retentionHours, 1);
    });

    test('extended settings use twenty-four-hour retention', () {
      final settings = ChatSettings.extended();

      expect(settings.extendedRetention, isTrue);
      expect(settings.retentionDuration, MessageRetention.twentyFourHours);
      expect(settings.retentionHours, 24);
    });

    test('copyWith updates only provided value', () {
      const initial = ChatSettings(extendedRetention: false);
      final next = initial.copyWith(extendedRetention: true);

      expect(next.extendedRetention, isTrue);
      expect(initial.extendedRetention, isFalse);
    });

    test('json serialization supports null and explicit values', () {
      expect(ChatSettings.fromJson(null), const ChatSettings());
      expect(
        ChatSettings.fromJson(const {'extendedRetention': true}),
        const ChatSettings(extendedRetention: true),
      );
      expect(
        ChatSettings.fromJson(const {'extendedRetention': false}),
        const ChatSettings(extendedRetention: false),
      );
      expect(const ChatSettings(extendedRetention: true).toJson(), {
        'extendedRetention': true,
      });
    });

    test('equatable compares by extendedRetention', () {
      expect(
        const ChatSettings(extendedRetention: true),
        const ChatSettings(extendedRetention: true),
      );
      expect(
        const ChatSettings(extendedRetention: true),
        isNot(const ChatSettings(extendedRetention: false)),
      );
    });
  });
}
