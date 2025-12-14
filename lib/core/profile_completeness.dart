import '../data/models/profile.dart';
import 'profile_media_limits.dart';

const double kSwipeMinimumCompleteness = 0.70;
const double kMessagingMinimumCompleteness = 0.70;

class ProfileCompletenessSummary {
  const ProfileCompletenessSummary({
    required this.score,
    required this.breakdown,
    required this.missing,
    required this.requiredMissing,
  });

  final double score; // 0.0 - 1.0
  final Map<String, double> breakdown;
  final List<String> missing;
  final List<String> requiredMissing;

  bool get meetsSwipeMinimum => score >= kSwipeMinimumCompleteness;
  bool get meetsMessagingMinimum => score >= kMessagingMinimumCompleteness;
  bool get meetsRequiredFields => requiredMissing.isEmpty;

  bool get hasMinPhotos =>
      breakdown.containsKey('photos') && (breakdown['photos'] ?? 0) > 0;
  bool get hasBio =>
      breakdown.containsKey('bio') && (breakdown['bio'] ?? 0) > 0;
  bool get hasPrompts =>
      breakdown.containsKey('prompts') && (breakdown['prompts'] ?? 0) > 0;
}

ProfileCompletenessSummary evaluateProfileCompleteness(Profile? profile) {
  if (profile == null) {
    return const ProfileCompletenessSummary(
      score: 0,
      breakdown: {},
      missing: ['Add photos', 'Add a bio'],
      requiredMissing: [
        'Add at least ${ProfileMediaLimits.minPhotos} photos',
        'Write a bio (40+ characters)',
        'Answer 2 prompt questions',
      ],
    );
  }

  double score = 0.0;
  final breakdown = <String, double>{};
  final missing = <String>[];
  final requiredMissing = <String>[];

  void addRule({
    required String key,
    required double weight,
    required bool satisfied,
    required String missingMessage,
    bool requiredForMessaging = false,
  }) {
    if (satisfied) {
      score += weight;
      breakdown[key] = weight;
    } else {
      breakdown[key] = 0.0;
      missing.add(missingMessage);
      if (requiredForMessaging) {
        requiredMissing.add(missingMessage);
      }
    }
  }

  addRule(
    key: 'photos',
    weight: 0.40,
    satisfied: profile.photoUrls.length >= ProfileMediaLimits.minPhotos,
    missingMessage: 'Add at least ${ProfileMediaLimits.minPhotos} photos',
    requiredForMessaging: true,
  );

  addRule(
    key: 'bio',
    weight: 0.20,
    satisfied: profile.bio.trim().length >= 40,
    missingMessage: 'Write a bio (40+ characters)',
    requiredForMessaging: true,
  );

  addRule(
    key: 'prompts',
    weight: 0.15,
    satisfied: profile.prompts.length >= 2,
    missingMessage: 'Answer 2 prompt questions',
    requiredForMessaging: true,
  );

  addRule(
    key: 'interests',
    weight: 0.10,
    satisfied: profile.interests.length >= 3,
    missingMessage: 'Add at least 3 interests',
  );

  addRule(
    key: 'work_or_school',
    weight: 0.08,
    satisfied: (profile.jobTitle?.trim().isNotEmpty ?? false) ||
        (profile.company?.trim().isNotEmpty ?? false) ||
        (profile.school?.trim().isNotEmpty ?? false),
    missingMessage: 'Add work or school',
  );

  addRule(
    key: 'location',
    weight: 0.07,
    satisfied: profile.city.trim().isNotEmpty &&
        profile.country.trim().isNotEmpty &&
        profile.country.trim().toLowerCase() != 'unknown',
    missingMessage: 'Add your city & country',
  );

  score = score.clamp(0.0, 1.0);

  return ProfileCompletenessSummary(
    score: score,
    breakdown: breakdown,
    missing: missing,
    requiredMissing: requiredMissing,
  );
}

double computeProfileCompleteness(Profile? profile) =>
    evaluateProfileCompleteness(profile).score;

bool isProfileComplete(Profile? profile) =>
    evaluateProfileCompleteness(profile).score >= 1.0;

Map<String, double> computeProfileCompletenessBreakdown(Profile? profile) =>
    evaluateProfileCompleteness(profile).breakdown;
