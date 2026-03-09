import 'package:crushhour/data/models/profile.dart';

/// Minimum completeness thresholds
const double kSwipeMinimumCompleteness =
    1.0; // Must complete all required fields
const double kMessagingMinimumCompleteness = 1.0;

/// Minimum requirements for swiping
const int kMinPhotos = 1;
const int kMinBioLength = 10; // Only 10 characters needed
const int kMinInterests = 3;

/// Optional enhancement (prompts are not required for swiping)
const int kRecommendedPrompts = 2;

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
      missing: [
        'Add at least 1 photo',
        'Write a bio (at least 10 characters)',
        'Add at least 3 interests',
        'Add your city and country',
      ],
      requiredMissing: [
        'Add at least 1 photo',
        'Write a bio (at least 10 characters)',
        'Add at least 3 interests',
        'Add your city and country',
      ],
      recommended: ['Answer prompts to stand out'],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE COMPLETENESS FOR SWIPING
  // Required: 1 photo, 10 char bio, 3 interests, city + country
  // Prompts are optional (recommended only)
  // ═══════════════════════════════════════════════════════════════════════════

  final breakdown = <String, double>{};
  final missing = <String>[];
  final requiredMissing = <String>[];
  final recommended = <String>[];

  // Photos: 30% weight (min 1 photo required)
  final photoCount = profile.photoUrls.length;
  final photoScore = (photoCount / kMinPhotos).clamp(0.0, 1.0);
  breakdown['photos'] = photoScore * 0.30;
  if (photoCount < kMinPhotos) {
    const msg = 'Add at least 1 photo';
    missing.add(msg);
    requiredMissing.add(msg);
  }

  // Bio: 25% weight (min 10 chars required)
  final bioLength = profile.bio.trim().length;
  final bioScore = (bioLength / kMinBioLength).clamp(0.0, 1.0);
  breakdown['bio'] = bioScore * 0.25;
  if (bioLength < kMinBioLength) {
    const msg = 'Write a bio (at least $kMinBioLength characters)';
    missing.add(msg);
    requiredMissing.add(msg);
  }

  // Interests: 25% weight (min 3 interests required)
  final interestCount = profile.interests.length;
  final interestsScore = (interestCount / kMinInterests).clamp(0.0, 1.0);
  breakdown['interests'] = interestsScore * 0.25;
  if (interestCount < kMinInterests) {
    const msg = 'Add at least $kMinInterests interests';
    missing.add(msg);
    requiredMissing.add(msg);
  }

  // Location: 20% weight (city + country required)
  final hasLocation =
      profile.city.trim().isNotEmpty &&
      profile.country.trim().isNotEmpty &&
      profile.country.trim().toLowerCase() != 'unknown';
  final locationScore = hasLocation ? 1.0 : 0.0;
  breakdown['location'] = locationScore * 0.20;
  if (!hasLocation) {
    const msg = 'Add your city and country';
    missing.add(msg);
    requiredMissing.add(msg);
  }

  // Prompts: Optional (not counted in score, just recommended)
  final promptCount = profile.profilePrompts.length;
  breakdown['prompts'] = promptCount > 0 ? 1.0 : 0.0; // Just for tracking
  if (promptCount < kRecommendedPrompts) {
    recommended.add('Answer prompts to stand out');
  }

  // Calculate total score (photos + bio + interests + location = 100%)
  final score =
      (breakdown['photos']! +
              breakdown['bio']! +
              breakdown['interests']! +
              breakdown['location']!)
          .clamp(0.0, 1.0);

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
