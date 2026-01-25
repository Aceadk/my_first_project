import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/discovery/data/repositories/boost_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Firebase implementation of BoostRepository.
///
/// Stores boost sessions in Firestore under `boosts` collection.
/// Each boost document contains:
/// - userId: The user who activated the boost
/// - startedAt: When the boost started
/// - endsAt: When the boost ends
/// - profileViewsGained: Number of profile views during boost
/// - status: 'active' or 'completed'
class FirebaseBoostRepository implements BoostRepository {
  FirebaseBoostRepository({
    required this.subscriptionRepository,
  });

  final SubscriptionRepository subscriptionRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for boosts.
  CollectionReference<Map<String, dynamic>> get _boostsCollection =>
      _firestore.collection('boosts');

  @override
  Future<BoostStatus> getBoostStatus(String userId) async {
    final plan = await subscriptionRepository.getCurrentPlan();

    // Check for active boost
    final activeBoostQuery = await _boostsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .where('endsAt', isGreaterThan: Timestamp.now())
        .orderBy('endsAt', descending: true)
        .limit(1)
        .get();

    BoostSession? activeSession;
    if (activeBoostQuery.docs.isNotEmpty) {
      final doc = activeBoostQuery.docs.first;
      final data = doc.data();
      activeSession = _boostSessionFromFirestore(data);

      // Update status if boost has expired
      if (activeSession.hasExpired) {
        await doc.reference.update({'status': 'completed'});
        activeSession = null;
      }
    }

    // If boost is active, user can't boost again
    if (activeSession != null && activeSession.isActive) {
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

    // Get the most recent completed boost to check cooldown
    final lastBoostQuery = await _boostsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .get();

    if (lastBoostQuery.docs.isNotEmpty) {
      final data = lastBoostQuery.docs.first.data();
      final startedAt = (data['startedAt'] as Timestamp).toDate();
      final cooldownEnds = startedAt.add(Duration(hours: cooldownHours));

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
    final plan = await subscriptionRepository.getCurrentPlan();

    // Check if user can boost
    final status = await getBoostStatus(userId);
    if (!status.canBoost) {
      throw Exception('Cannot activate boost: on cooldown or boost already active');
    }

    // Calculate boost duration based on subscription
    final boostMinutes = plan.isPlus
        ? CrushConstants.premiumBoostDurationMinutes
        : CrushConstants.freeBoostDurationMinutes;

    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: boostMinutes));

    // Create boost document in Firestore
    final boostDoc = await _boostsCollection.add({
      'userId': userId,
      'startedAt': Timestamp.fromDate(now),
      'endsAt': Timestamp.fromDate(endTime),
      'profileViewsGained': 0,
      'status': 'active',
      'plan': plan.isPlus ? 'plus' : 'free',
      'durationMinutes': boostMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also update the user's profile to mark as boosted for discovery prioritization
    await _firestore.collection('users').doc(userId).update({
      'profile.isBoosted': true,
      'profile.boostEndsAt': Timestamp.fromDate(endTime),
      'profile.boostId': boostDoc.id,
    });

    // Schedule boost expiration cleanup (Cloud Function should handle this)
    // For now, we rely on getBoostStatus() to update status when checking

    return BoostSession(
      startedAt: now,
      endsAt: endTime,
      isActive: true,
      profileViewsGained: 0,
    );
  }

  @override
  Future<List<BoostSession>> getBoostHistory(String userId) async {
    final historyQuery = await _boostsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(20)
        .get();

    return historyQuery.docs
        .map((doc) => _boostSessionFromFirestore(doc.data()))
        .toList();
  }

  /// Convert Firestore document to BoostSession.
  BoostSession _boostSessionFromFirestore(Map<String, dynamic> data) {
    final startedAt = (data['startedAt'] as Timestamp).toDate();
    final endsAt = (data['endsAt'] as Timestamp).toDate();
    final now = DateTime.now();
    final isActive = data['status'] == 'active' && now.isBefore(endsAt);

    return BoostSession(
      startedAt: startedAt,
      endsAt: endsAt,
      isActive: isActive,
      profileViewsGained: data['profileViewsGained'] as int? ?? 0,
    );
  }

  /// Increment profile views for active boost.
  /// Called when someone views a boosted user's profile.
  Future<void> incrementBoostViews(String boostId) async {
    await _boostsCollection.doc(boostId).update({
      'profileViewsGained': FieldValue.increment(1),
    });
  }

  /// Complete an expired boost.
  /// Called by Cloud Function or when checking status.
  Future<void> completeBoost(String boostId, String userId) async {
    final batch = _firestore.batch();

    // Update boost status
    batch.update(_boostsCollection.doc(boostId), {
      'status': 'completed',
    });

    // Remove boost flag from user profile
    batch.update(_firestore.collection('users').doc(userId), {
      'profile.isBoosted': false,
      'profile.boostEndsAt': FieldValue.delete(),
      'profile.boostId': FieldValue.delete(),
    });

    await batch.commit();
  }
}
