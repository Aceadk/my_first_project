import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';

/// Filter options for discovery deck.
class DiscoveryFilter {
  /// Maximum distance in km. If null, no distance filter is applied.
  final double? maxDistanceKm;

  /// Whether user has Passport mode enabled (Plus feature).
  /// When true, ignores distance restrictions and shows global profiles.
  final bool passportModeEnabled;

  /// Whether the local deck (within 220km) has been exhausted.
  /// When true, extends search to beyond 220km.
  final bool localDeckExhausted;

  /// User's current latitude for distance calculation.
  final double? userLatitude;

  /// User's current longitude for distance calculation.
  final double? userLongitude;

  /// Passport mode location override latitude.
  final double? passportLatitude;

  /// Passport mode location override longitude.
  final double? passportLongitude;

  const DiscoveryFilter({
    this.maxDistanceKm,
    this.passportModeEnabled = false,
    this.localDeckExhausted = false,
    this.userLatitude,
    this.userLongitude,
    this.passportLatitude,
    this.passportLongitude,
  });

  /// Returns the effective latitude for discovery.
  /// Uses passport location if passport mode is enabled, otherwise user location.
  double? get effectiveLatitude =>
      passportModeEnabled ? (passportLatitude ?? userLatitude) : userLatitude;

  /// Returns the effective longitude for discovery.
  double? get effectiveLongitude => passportModeEnabled
      ? (passportLongitude ?? userLongitude)
      : userLongitude;
}

abstract class DiscoveryRepository {
  /// Fetches the discovery deck for a user.
  /// [filter] contains distance and passport mode parameters.
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  });

  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage, // for premium "message before match"
  });

  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  });

  Future<List<Profile>> fetchTopPicks(String userId);

  Future<List<Profile>> fetchLikesYou(String userId);

  Future<List<CrushMatch>> fetchMatches(String userId);

  /// Fetches a single profile by ID.
  /// Returns null if profile not found.
  Future<Profile?> fetchProfileById(String profileId);

  /// Super Like a profile (higher priority, notifies the target user).
  /// Returns a match if mutual, null otherwise.
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  });

  /// Rewind/undo the last swipe action.
  /// Returns the profile that was rewound, or null if cannot rewind.
  Future<Profile?> rewindLastSwipe(String userId);
}
