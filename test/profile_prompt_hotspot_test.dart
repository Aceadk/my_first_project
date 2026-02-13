import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfilePrompt', () {
    test(
      'exposes mapped question metadata and supports copy/json roundtrip',
      () {
        final createdAt = DateTime(2026, 2, 13, 12, 0, 0);
        final prompt = ProfilePrompt(
          questionId: 'simple_pleasure',
          answer: 'Run a marathon',
          createdAt: createdAt,
        );

        expect(prompt.question, isNotEmpty);
        expect(prompt.category, PromptQuestions.categoryAboutMe);
        expect(prompt.emoji, '🎯');

        final updated = prompt.copyWith(answer: 'Run two marathons');
        expect(updated.answer, 'Run two marathons');
        expect(updated.questionId, prompt.questionId);
        expect(updated.createdAt, createdAt);

        final json = prompt.toJson();
        expect(json['questionId'], 'simple_pleasure');
        expect(json['answer'], 'Run a marathon');
        expect(json['createdAt'], createdAt.toIso8601String());

        final decoded = ProfilePrompt.fromJson(json);
        expect(decoded, prompt);
      },
    );

    test('fromJson handles invalid createdAt safely', () {
      final prompt = ProfilePrompt.fromJson({
        'questionId': 'looking_for',
        'answer': 'Something real',
        'createdAt': 'not-a-date',
      });

      expect(prompt.createdAt, isNull);
      expect(prompt.question, isNotEmpty);
      expect(prompt.category, PromptQuestions.categoryDating);
    });
  });

  group('PromptQuestions', () {
    test('returns categories and filters by category', () {
      expect(
        PromptQuestions.categories,
        containsAll([
          PromptQuestions.categoryAboutMe,
          PromptQuestions.categoryDating,
          PromptQuestions.categoryPersonality,
          PromptQuestions.categoryLifestyle,
          PromptQuestions.categoryConversation,
          PromptQuestions.categoryFun,
        ]),
      );

      final aboutMe = PromptQuestions.getByCategory(
        PromptQuestions.categoryAboutMe,
      );
      expect(aboutMe, isNotEmpty);
      expect(
        aboutMe.every((q) => q.category == PromptQuestions.categoryAboutMe),
        isTrue,
      );
    });

    test('maps category display names and unknown fallback', () {
      expect(
        PromptQuestions.getCategoryDisplayName(PromptQuestions.categoryAboutMe),
        'About Me',
      );
      expect(
        PromptQuestions.getCategoryDisplayName(
          PromptQuestions.categoryConversation,
        ),
        'Conversation Starters',
      );
      expect(PromptQuestions.getCategoryDisplayName('custom'), 'custom');
    });

    test(
      'question/category/emoji lookups use default fallback for unknown ids',
      () {
        expect(PromptQuestions.getQuestion('missing_id'), 'Tell us something');
        expect(
          PromptQuestions.getCategory('missing_id'),
          PromptQuestions.categoryAboutMe,
        );
        expect(PromptQuestions.getEmoji('missing_id'), '💭');
      },
    );

    test('getById returns question when found and null when missing', () {
      final found = PromptQuestions.getById('simple_pleasure');
      expect(found, isNotNull);
      expect(found!.id, 'simple_pleasure');

      final missing = PromptQuestions.getById('does_not_exist');
      expect(missing, isNull);
    });
  });
}
