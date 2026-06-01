import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';

enum ProfileCompletionActionType { photos, bio, interests, location, prompts }

class ProfileCompletionAction {
  const ProfileCompletionAction({
    required this.type,
    required this.title,
    required this.description,
    required this.isRequired,
  });

  final ProfileCompletionActionType type;
  final String title;
  final String description;
  final bool isRequired;
}

class ProfileCompletionGuidance {
  const ProfileCompletionGuidance({
    required this.percent,
    required this.canStartMatching,
    required this.requiredActions,
    required this.recommendedActions,
  });

  final int percent;
  final bool canStartMatching;
  final List<ProfileCompletionAction> requiredActions;
  final List<ProfileCompletionAction> recommendedActions;

  bool get isComplete => requiredActions.isEmpty;
  List<ProfileCompletionAction> get nextActions => [
    ...requiredActions,
    ...recommendedActions,
  ];

  factory ProfileCompletionGuidance.fromProfile(Profile? profile) {
    final summary = evaluateProfileCompleteness(profile);
    return ProfileCompletionGuidance.fromSummary(summary);
  }

  factory ProfileCompletionGuidance.fromSummary(
    ProfileCompletenessSummary summary,
  ) {
    return ProfileCompletionGuidance(
      percent: (summary.score * 100).round(),
      canStartMatching: summary.meetsRequiredFields,
      requiredActions: _requiredActionsFor(summary),
      recommendedActions: _recommendedActionsFor(summary),
    );
  }

  static List<ProfileCompletionAction> _requiredActionsFor(
    ProfileCompletenessSummary summary,
  ) {
    final actions = <ProfileCompletionAction>[];
    final missing = summary.requiredMissing.join(' ').toLowerCase();

    if (missing.contains('photo')) {
      actions.add(
        const ProfileCompletionAction(
          type: ProfileCompletionActionType.photos,
          title: 'Add 1 clear profile photo',
          description:
              'A visible photo is required before your profile can appear in matching.',
          isRequired: true,
        ),
      );
    }

    if (missing.contains('bio')) {
      actions.add(
        const ProfileCompletionAction(
          type: ProfileCompletionActionType.bio,
          title: 'Write a short bio',
          description:
              'Use at least 10 characters so matches have a real conversation starter.',
          isRequired: true,
        ),
      );
    }

    if (missing.contains('interest')) {
      actions.add(
        const ProfileCompletionAction(
          type: ProfileCompletionActionType.interests,
          title: 'Pick 3 interests',
          description:
              'Interests help the app explain compatibility and improve match quality.',
          isRequired: true,
        ),
      );
    }

    if (missing.contains('city') || missing.contains('country')) {
      actions.add(
        const ProfileCompletionAction(
          type: ProfileCompletionActionType.location,
          title: 'Add city and country',
          description:
              'Location lets nearby discovery and distance labels work predictably.',
          isRequired: true,
        ),
      );
    }

    return actions;
  }

  static List<ProfileCompletionAction> _recommendedActionsFor(
    ProfileCompletenessSummary summary,
  ) {
    if (summary.recommended.isEmpty) {
      return const <ProfileCompletionAction>[];
    }

    return const [
      ProfileCompletionAction(
        type: ProfileCompletionActionType.prompts,
        title: 'Answer 2 profile prompts',
        description:
            'Prompts are optional, but they give people an easier first message.',
        isRequired: false,
      ),
    ];
  }
}
