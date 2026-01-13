/// Represents an active or past boost session.
class BoostSession {
  const BoostSession({
    required this.startedAt,
    required this.endsAt,
    required this.isActive,
    this.profileViewsGained = 0,
  });

  final DateTime startedAt;
  final DateTime endsAt;
  final bool isActive;
  final int profileViewsGained;

  /// Duration remaining in the boost.
  Duration get remainingDuration {
    if (!isActive) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return Duration.zero;
    return endsAt.difference(now);
  }

  /// Whether the boost has expired.
  bool get hasExpired => DateTime.now().isAfter(endsAt);
}

/// Repository for managing user boosts.
abstract class BoostRepository {
  /// Get the current boost status for a user.
  Future<BoostStatus> getBoostStatus(String userId);

  /// Activate a boost for the user.
  /// Returns the new boost session if successful.
  Future<BoostSession> activateBoost(String userId);

  /// Get boost history for the user.
  Future<List<BoostSession>> getBoostHistory(String userId);
}

/// Status of boost availability and active session.
class BoostStatus {
  const BoostStatus({
    required this.canBoost,
    required this.nextBoostAvailableAt,
    this.activeSession,
    this.boostsRemaining = 0,
    this.cooldownHours = 0,
  });

  /// Whether the user can activate a boost now.
  final bool canBoost;

  /// When the next boost will be available (if on cooldown).
  final DateTime? nextBoostAvailableAt;

  /// Currently active boost session, if any.
  final BoostSession? activeSession;

  /// Number of boosts remaining today (for premium users).
  final int boostsRemaining;

  /// Hours until next boost is available.
  final int cooldownHours;

  /// Whether a boost is currently active.
  bool get isBoostActive => activeSession?.isActive ?? false;

  /// Time remaining until boost is available.
  Duration get cooldownRemaining {
    if (canBoost || nextBoostAvailableAt == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(nextBoostAvailableAt!)) return Duration.zero;
    return nextBoostAvailableAt!.difference(now);
  }
}
