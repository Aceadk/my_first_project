import 'dart:async';
import 'dart:math';
import '../models/date_plan.dart';

/// Service for managing date plans and safety features.
class DatePlanService {
  DatePlanService._();
  static final DatePlanService instance = DatePlanService._();

  final _datePlanController = StreamController<DatePlan>.broadcast();
  final _checkInController = StreamController<CheckInStatus>.broadcast();

  Stream<DatePlan> get datePlanStream => _datePlanController.stream;
  Stream<CheckInStatus> get checkInStream => _checkInController.stream;

  final Map<String, DatePlan> _plans = {};
  Timer? _checkInTimer;

  /// Create a new date plan.
  Future<DatePlan> createDatePlan({
    required String userId,
    required String matchId,
    required String matchName,
    String? matchPhotoUrl,
    required DateTime dateTime,
    required String location,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? notes,
    List<EmergencyContact> sharedWith = const [],
    Duration checkInDelay = const Duration(hours: 2),
  }) async {
    final plan = DatePlan(
      id: _generateId(),
      userId: userId,
      matchId: matchId,
      matchName: matchName,
      matchPhotoUrl: matchPhotoUrl,
      dateTime: dateTime,
      location: location,
      locationAddress: locationAddress,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      notes: notes,
      sharedWith: sharedWith,
      createdAt: DateTime.now(),
      checkInTime: dateTime.add(checkInDelay),
      status: DatePlanStatus.scheduled,
    );

    _plans[plan.id] = plan;
    _datePlanController.add(plan);

    // Schedule check-in reminder
    _scheduleCheckInReminder(plan);

    return plan;
  }

  /// Add emergency contact to a date plan.
  Future<DatePlan> addEmergencyContact({
    required String planId,
    required EmergencyContact contact,
  }) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedContacts = [...plan.sharedWith, contact];
    final updatedPlan = plan.copyWith(sharedWith: updatedContacts);

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);

    // Notify contact about being added
    await _notifyContactAdded(contact, updatedPlan);

    return updatedPlan;
  }

  /// Remove emergency contact from a date plan.
  Future<DatePlan> removeEmergencyContact({
    required String planId,
    required String contactPhone,
  }) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedContacts = plan.sharedWith
        .where((c) => c.phone != contactPhone)
        .toList();
    final updatedPlan = plan.copyWith(sharedWith: updatedContacts);

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);

    return updatedPlan;
  }

  /// Start the date (when user arrives).
  Future<DatePlan> startDate(String planId) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedPlan = plan.copyWith(
      status: DatePlanStatus.ongoing,
    );

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);

    // Notify contacts that date has started
    await _notifyContactsDateStarted(updatedPlan);

    return updatedPlan;
  }

  /// Check in (confirm safety).
  Future<DatePlan> checkIn(String planId) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedPlan = plan.copyWith(
      checkedInAt: DateTime.now(),
    );

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);
    _checkInController.add(CheckInStatus.confirmed);

    // Notify contacts
    await _notifyContactsCheckedIn(updatedPlan);

    return updatedPlan;
  }

  /// End the date safely.
  Future<DatePlan> endDateSafely(String planId) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedPlan = plan.copyWith(
      status: DatePlanStatus.completed,
      checkedInAt: plan.checkedInAt ?? DateTime.now(),
    );

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);

    // Notify contacts date ended safely
    await _notifyContactsDateEnded(updatedPlan);

    return updatedPlan;
  }

  /// Trigger emergency alert.
  Future<void> triggerEmergencyAlert(String planId) async {
    final plan = _plans[planId];
    if (plan == null) throw Exception('Date plan not found');

    final updatedPlan = plan.copyWith(
      status: DatePlanStatus.emergency,
    );

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);

    // Immediately notify all emergency contacts
    await _sendEmergencyAlerts(updatedPlan);
  }

  /// Get active date plans for user.
  Future<List<DatePlan>> getActivePlans(String userId) async {
    return _plans.values
        .where((p) => p.userId == userId &&
            (p.status == DatePlanStatus.scheduled ||
             p.status == DatePlanStatus.ongoing))
        .toList();
  }

  /// Get all plans for user.
  Future<List<DatePlan>> getAllPlans(String userId) async {
    return _plans.values
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Get date plan by ID.
  DatePlan? getPlan(String planId) => _plans[planId];

  /// Cancel a date plan.
  Future<void> cancelPlan(String planId) async {
    final plan = _plans[planId];
    if (plan == null) return;

    final updatedPlan = plan.copyWith(
      status: DatePlanStatus.cancelled,
    );

    _plans[planId] = updatedPlan;
    _datePlanController.add(updatedPlan);
  }

  void _scheduleCheckInReminder(DatePlan plan) {
    if (plan.checkInTime == null) return;

    final delay = plan.checkInTime!.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () {
      final currentPlan = _plans[plan.id];
      if (currentPlan != null &&
          currentPlan.checkedInAt == null &&
          currentPlan.status == DatePlanStatus.ongoing) {
        _checkInController.add(CheckInStatus.due);

        // If still no check-in after 15 minutes, alert contacts
        Future.delayed(const Duration(minutes: 15), () {
          final latePlan = _plans[plan.id];
          if (latePlan != null && latePlan.checkedInAt == null) {
            _checkInController.add(CheckInStatus.overdue);
            _notifyContactsMissedCheckIn(latePlan);
          }
        });
      }
    });
  }

  Future<void> _notifyContactAdded(EmergencyContact contact, DatePlan plan) async {
    // In production, send SMS/push notification
  }

  Future<void> _notifyContactsDateStarted(DatePlan plan) async {
    for (final _ in plan.sharedWith) {
      // In production: send SMS/email notification
    }
  }

  Future<void> _notifyContactsCheckedIn(DatePlan plan) async {
    for (final _ in plan.sharedWith) {
      // Notify contacts that user checked in safely
    }
  }

  Future<void> _notifyContactsDateEnded(DatePlan plan) async {
    for (final _ in plan.sharedWith) {
      // Notify contacts that date ended safely
    }
  }

  Future<void> _notifyContactsMissedCheckIn(DatePlan plan) async {
    for (final _ in plan.sharedWith) {
      // Alert contacts about missed check-in
    }
  }

  Future<void> _sendEmergencyAlerts(DatePlan plan) async {
    for (final _ in plan.sharedWith) {
      // In production: send urgent SMS/call with location
    }
  }

  String _generateId() {
    return 'date_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void dispose() {
    _checkInTimer?.cancel();
    _datePlanController.close();
    _checkInController.close();
  }
}

/// Check-in status for UI.
enum CheckInStatus {
  none,
  due,
  confirmed,
  overdue,
}
