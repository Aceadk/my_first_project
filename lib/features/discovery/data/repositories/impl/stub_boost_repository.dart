import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/discovery/data/repositories/boost_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Stub implementation of BoostRepository using SharedPreferences.
class StubBoostRepository implements BoostRepository {
  StubBoostRepository({
    required this.subscriptionRepository,
  });

  final SubscriptionRepository subscriptionRepository;

  static const _lastBoostKey = 'boost_last_activated';
  static const _boostEndKey = 'boost_end_time';

  @override
  Future<BoostStatus> getBoostStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final plan = await subscriptionRepository.getCurrentPlan();

    final lastBoostMs = prefs.getInt(_lastBoostKey);
    final boostEndMs = prefs.getInt(_boostEndKey);

    // Check if there's an active boost
    BoostSession? activeSession;
    if (boostEndMs != null && lastBoostMs != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(boostEndMs);
      final startTime = DateTime.fromMillisecondsSinceEpoch(lastBoostMs);
      if (DateTime.now().isBefore(endTime)) {
        activeSession = BoostSession(
          startedAt: startTime,
          endsAt: endTime,
          isActive: true,
        );
      }
    }

    // If boost is active, user can't boost again
    if (activeSession != null) {
      return BoostStatus(
        canBoost: false,
        nextBoostAvailableAt: activeSession.endsAt,
        activeSession: activeSession,
        boostsRemaining: 0,
      );
    }

    // Calculate cooldown based on subscription
    final cooldownHours = plan.isPlus
        ? CrushConstants.premiumBoostCooldownHours
        : CrushConstants.freeBoostCooldownHours;

    // Check if user is on cooldown
    if (lastBoostMs != null) {
      final lastBoost = DateTime.fromMillisecondsSinceEpoch(lastBoostMs);
      final cooldownEnds = lastBoost.add(Duration(hours: cooldownHours));

      if (DateTime.now().isBefore(cooldownEnds)) {
        return BoostStatus(
          canBoost: false,
          nextBoostAvailableAt: cooldownEnds,
          activeSession: null,
          boostsRemaining: 0,
          cooldownHours: cooldownHours,
        );
      }
    }

    // User can boost
    return BoostStatus(
      canBoost: true,
      nextBoostAvailableAt: null,
      activeSession: null,
      boostsRemaining: 1,
      cooldownHours: cooldownHours,
    );
  }

  @override
  Future<BoostSession> activateBoost(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final plan = await subscriptionRepository.getCurrentPlan();

    // Calculate boost duration based on subscription
    final boostMinutes = plan.isPlus
        ? CrushConstants.premiumBoostDurationMinutes
        : CrushConstants.freeBoostDurationMinutes;

    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: boostMinutes));

    // Save boost timestamps
    await prefs.setInt(_lastBoostKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_boostEndKey, endTime.millisecondsSinceEpoch);

    return BoostSession(
      startedAt: now,
      endsAt: endTime,
      isActive: true,
    );
  }

  @override
  Future<List<BoostSession>> getBoostHistory(String userId) async {
    // Stub implementation - just return current/last boost
    final prefs = await SharedPreferences.getInstance();
    final lastBoostMs = prefs.getInt(_lastBoostKey);
    final boostEndMs = prefs.getInt(_boostEndKey);

    if (lastBoostMs == null || boostEndMs == null) {
      return const [];
    }

    final startTime = DateTime.fromMillisecondsSinceEpoch(lastBoostMs);
    final endTime = DateTime.fromMillisecondsSinceEpoch(boostEndMs);

    return [
      BoostSession(
        startedAt: startTime,
        endsAt: endTime,
        isActive: DateTime.now().isBefore(endTime),
      ),
    ];
  }
}
