import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/features/profile/data/repositories/impl/profile_prompt_migration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile prompt migration helpers', () {
    test('parseLegacyPromptAnswers trims and filters empty values', () {
      final parsed = parseLegacyPromptAnswers(<dynamic>[
        '  one  ',
        '',
        '   ',
        'two',
        3,
      ]);

      expect(parsed, equals(const <String>['one', 'two']));
      expect(parseLegacyPromptAnswers('not-a-list'), isEmpty);
    });

    test(
      'parseProfilePrompts prefers structured profile prompts when present',
      () {
        final parsed = parseProfilePrompts(
          <dynamic>[
            <String, dynamic>{'questionId': 'fun_fact', 'answer': 'I climb'},
            '  legacy-inline-answer  ',
          ],
          legacyPromptAnswers: const <String>['fallback one'],
        );

        expect(parsed.length, 2);
        expect(parsed.first.questionId, 'fun_fact');
        expect(parsed.first.answer, 'I climb');
        expect(parsed.last.answer, 'legacy-inline-answer');
      },
    );

    test(
      'parseProfilePrompts falls back to legacy prompt answers when needed',
      () {
        final parsed = parseProfilePrompts(
          null,
          legacyPromptAnswers: const <String>['legacy one', 'legacy two'],
        );

        expect(parsed.length, 2);
        expect(parsed.first.questionId, 'unknown');
        expect(parsed.first.answer, 'legacy one');
        expect(parsed.last.answer, 'legacy two');
      },
    );

    test('prompt answer/profile prompt conversion stays normalized', () {
      const prompts = <ProfilePrompt>[
        ProfilePrompt(questionId: 'q1', answer: '  Hello  '),
        ProfilePrompt(questionId: 'q2', answer: ''),
        ProfilePrompt(questionId: 'q3', answer: 'World'),
      ];

      final answers = promptAnswersFromProfilePrompts(prompts);
      expect(answers, equals(const <String>['Hello', 'World']));

      final rebuilt = profilePromptsFromLegacyAnswers(answers);
      expect(
        rebuilt,
        equals(const <ProfilePrompt>[
          ProfilePrompt(questionId: 'unknown', answer: 'Hello'),
          ProfilePrompt(questionId: 'unknown', answer: 'World'),
        ]),
      );
    });
  });
}
