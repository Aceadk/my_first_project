import 'package:crushhour/features/profile/presentation/widgets/profile_completion_guidance.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileCompletionGuidance', () {
    test('maps required missing fields into actionable copy', () {
      const summary = ProfileCompletenessSummary(
        score: 0.2,
        breakdown: <String, double>{'photos': 0, 'bio': 0.2},
        missing: <String>[
          'Add at least 1 photo',
          'Write a bio (at least 10 characters)',
          'Add at least 3 interests',
          'Add your city and country',
        ],
        requiredMissing: <String>[
          'Add at least 1 photo',
          'Write a bio (at least 10 characters)',
          'Add at least 3 interests',
          'Add your city and country',
        ],
        recommended: <String>['Answer prompts to stand out'],
      );

      final guidance = ProfileCompletionGuidance.fromSummary(summary);

      expect(guidance.percent, 20);
      expect(guidance.canStartMatching, isFalse);
      expect(
        guidance.requiredActions.map((action) => action.type),
        <ProfileCompletionActionType>[
          ProfileCompletionActionType.photos,
          ProfileCompletionActionType.bio,
          ProfileCompletionActionType.interests,
          ProfileCompletionActionType.location,
        ],
      );
      expect(
        guidance.recommendedActions.single.type,
        ProfileCompletionActionType.prompts,
      );
    });

    test(
      'keeps optional prompts separate when required fields are complete',
      () {
        const summary = ProfileCompletenessSummary(
          score: 1,
          breakdown: <String, double>{
            'photos': 0.3,
            'bio': 0.25,
            'interests': 0.25,
            'location': 0.2,
            'prompts': 0,
          },
          missing: <String>[],
          requiredMissing: <String>[],
          recommended: <String>['Answer prompts to stand out'],
        );

        final guidance = ProfileCompletionGuidance.fromSummary(summary);

        expect(guidance.isComplete, isTrue);
        expect(guidance.canStartMatching, isTrue);
        expect(guidance.requiredActions, isEmpty);
        expect(guidance.recommendedActions.single.isRequired, isFalse);
        expect(guidance.nextActions.single.title, 'Answer 2 profile prompts');
      },
    );
  });
}
