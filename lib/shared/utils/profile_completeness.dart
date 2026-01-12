import 'package:crushhour/data/models/profile.dart';

const double kSwipeMinimumCompleteness = 0.70;
const double kMessagingMinimumCompleteness = 0.70;

class ProfileCompletenessSummary {
  const ProfileCompletenessSummary({
    required this.score,
    required this.breakdown,
    required this.missing,
    required this.requiredMissing,
    required this.recommended,
  });

  final double score; // 0.0 - 1.0
  final Map<String, double> breakdown;
  final List<String> missing;
  final List<String> requiredMissing;
  final List<String> recommended; // Optional but recommended fields

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
      missing: ['Add photos', 'Add display name'],
      requiredMissing: [
        'Add at least 1 photo',
        'Add your display name',
        'Add your date of birth',
        'Add your location',
        'Specify your gender',
        'Specify your sexual orientation',
      ],
      recommended: [
        'Write about yourself',
        'Add interests for better matches',
      ],
    );
  }

  double score = 0.0;
  final breakdown = <String, double>{};
  final missing = <String>[];
  final requiredMissing = <String>[];
  final recommended = <String>[];

  void addRule({
    required String key,
    required double weight,
    required bool satisfied,
    required String missingMessage,
    bool required = false,
    bool isRecommended = false,
  }) {
    if (satisfied) {
      score += weight;
      breakdown[key] = weight;
    } else {
      breakdown[key] = 0.0;
      missing.add(missingMessage);
      if (required) {
        requiredMissing.add(missingMessage);
      }
      if (isRecommended) {
        recommended.add(missingMessage);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUIRED FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  // At least 1 photo (required)
  addRule(
    key: 'photos',
    weight: 0.20,
    satisfied: profile.photoUrls.isNotEmpty,
    missingMessage: 'Add at least 1 photo',
    required: true,
  );

  // Display name (required)
  addRule(
    key: 'name',
    weight: 0.15,
    satisfied: profile.name.trim().isNotEmpty,
    missingMessage: 'Add your display name',
    required: true,
  );

  // Date of birth (required)
  addRule(
    key: 'date_of_birth',
    weight: 0.15,
    satisfied: profile.dateOfBirth != null,
    missingMessage: 'Add your date of birth',
    required: true,
  );

  // Location (required)
  addRule(
    key: 'location',
    weight: 0.15,
    satisfied: profile.city.trim().isNotEmpty &&
        profile.country.trim().isNotEmpty &&
        profile.country.trim().toLowerCase() != 'unknown',
    missingMessage: 'Add your location',
    required: true,
  );

  // Gender (required)
  addRule(
    key: 'gender',
    weight: 0.15,
    satisfied: profile.gender.trim().isNotEmpty,
    missingMessage: 'Specify your gender',
    required: true,
  );

  // Sexual orientation (required)
  addRule(
    key: 'sexual_orientation',
    weight: 0.10,
    satisfied: profile.sexualOrientation?.trim().isNotEmpty ?? false,
    missingMessage: 'Specify your sexual orientation',
    required: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONAL BUT RECOMMENDED FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  // Bio/about me (optional but recommended)
  addRule(
    key: 'bio',
    weight: 0.05,
    satisfied: profile.bio.trim().length >= 20,
    missingMessage: 'Write about yourself for a better profile',
    isRecommended: true,
  );

  // Interests (optional but recommended)
  addRule(
    key: 'interests',
    weight: 0.05,
    satisfied: profile.interests.length >= 3,
    missingMessage: 'Add interests to find better matches',
    isRecommended: true,
  );

  score = score.clamp(0.0, 1.0);

  return ProfileCompletenessSummary(
    score: score,
    breakdown: breakdown,
    missing: missing,
    requiredMissing: requiredMissing,
    recommended: recommended,
  );
}

double computeProfileCompleteness(Profile? profile) =>
    evaluateProfileCompleteness(profile).score;

bool isProfileComplete(Profile? profile) =>
    evaluateProfileCompleteness(profile).score >= 1.0;

Map<String, double> computeProfileCompletenessBreakdown(Profile? profile) =>
    evaluateProfileCompleteness(profile).breakdown;
