import 'dart:math';

import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';

/// Pure decision utilities for discovery filtering and ranking.
class MatchingDecisionEngine {
  const MatchingDecisionEngine._();

  /// Applies discovery filter constraints to candidate profiles.
  static List<Profile> filterCandidates({
    required Iterable<Profile> candidates,
    required DiscoveryFilter filter,
    Set<String> excludedProfileIds = const {},
    bool includeProfilesWithoutLocation = true,
  }) {
    final filtered = <Profile>[];
    for (final candidate in candidates) {
      if (excludedProfileIds.contains(candidate.id)) {
        continue;
      }
      if (!passesDistanceFilter(
        candidate: candidate,
        filter: filter,
        includeProfilesWithoutLocation: includeProfilesWithoutLocation,
      )) {
        continue;
      }
      filtered.add(candidate);
    }
    return filtered;
  }

  /// Returns whether a candidate passes distance/passport constraints.
  static bool passesDistanceFilter({
    required Profile candidate,
    required DiscoveryFilter filter,
    bool includeProfilesWithoutLocation = true,
  }) {
    if (filter.passportModeEnabled || filter.maxDistanceKm == null) {
      return true;
    }

    final userLat = filter.effectiveLatitude;
    final userLng = filter.effectiveLongitude;
    if (userLat == null || userLng == null) {
      return true;
    }

    final candidateLat = candidate.latitude;
    final candidateLng = candidate.longitude;
    if (candidateLat == null || candidateLng == null) {
      return includeProfilesWithoutLocation;
    }

    final distance = haversineDistanceKm(
      lat1: userLat,
      lon1: userLng,
      lat2: candidateLat,
      lon2: candidateLng,
    );
    return distance <= filter.maxDistanceKm!;
  }

  /// Calculates Haversine distance in kilometers.
  static double haversineDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Ranks top picks deterministically based on matching score.
  static List<Profile> rankTopPicks({
    required Iterable<Profile> candidates,
    required DiscoveryPreferences preferences,
    required Iterable<String> userInterests,
    int limit = 10,
  }) {
    final normalizedInterests = userInterests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    final filtered = candidates
        .where((candidate) => matchesBasicPreferences(candidate, preferences))
        .toList();

    filtered.sort((left, right) {
      final scoreDiff =
          topPickScore(
            candidate: right,
            preferences: preferences,
            normalizedUserInterests: normalizedInterests,
          ).compareTo(
            topPickScore(
              candidate: left,
              preferences: preferences,
              normalizedUserInterests: normalizedInterests,
            ),
          );
      if (scoreDiff != 0) return scoreDiff;
      return left.id.compareTo(right.id);
    });

    return filtered.take(limit).toList();
  }

  /// Quick compatibility gate for age and configured gender preferences.
  static bool matchesBasicPreferences(
    Profile candidate,
    DiscoveryPreferences preferences,
  ) {
    if (candidate.age < preferences.minAge ||
        candidate.age > preferences.maxAge) {
      return false;
    }

    final showMe = preferences.showMeGenders
        .map((gender) => gender.toLowerCase())
        .toSet();
    if (showMe.isEmpty) return true;
    return showMe.contains(candidate.gender.toLowerCase());
  }

  /// Compatibility score used for deterministic top-picks ranking.
  static double topPickScore({
    required Profile candidate,
    required DiscoveryPreferences preferences,
    required Set<String> normalizedUserInterests,
  }) {
    final candidateInterests = candidate.interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();
    final sharedInterests = candidateInterests
        .where(normalizedUserInterests.contains)
        .length;

    final targetAgeCenter = (preferences.minAge + preferences.maxAge) / 2;
    final ageScore = -((candidate.age - targetAgeCenter).abs());

    final userCity = preferences.city.trim().toLowerCase();
    final userCountry = preferences.country.trim().toLowerCase();
    final candidateCity = candidate.city.trim().toLowerCase();
    final candidateCountry = candidate.country.trim().toLowerCase();

    final locationBoost =
        (candidateCity == userCity ? 5 : 0) +
        (candidateCountry == userCountry ? 2 : 0);

    return sharedInterests * 10 + ageScore + locationBoost;
  }
}
