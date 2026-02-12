import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/safety/data/models/date_plan.dart';

void main() {
  group('DatePlan', () {
    const contact = EmergencyContact(
      name: 'Alex',
      phone: '+1234567890',
      email: 'alex@example.com',
      relationship: 'friend',
    );

    DatePlan buildPlan({
      DateTime? dateTime,
      DateTime? checkInTime,
      DateTime? checkedInAt,
      DatePlanStatus status = DatePlanStatus.scheduled,
    }) {
      final now = DateTime.now();
      return DatePlan(
        id: 'plan-1',
        userId: 'user-1',
        matchId: 'match-1',
        matchName: 'Taylor',
        matchPhotoUrl: 'https://example.com/match.jpg',
        dateTime: dateTime ?? now.add(const Duration(hours: 2)),
        location: 'Cafe Downtown',
        locationAddress: '123 Main St',
        locationLatitude: 40.0,
        locationLongitude: -73.0,
        notes: 'Window seat',
        sharedWith: const [contact],
        createdAt: now.subtract(const Duration(minutes: 5)),
        checkInTime: checkInTime,
        checkedInAt: checkedInAt,
        status: status,
      );
    }

    test('serializes and deserializes correctly', () {
      final plan = buildPlan(
        dateTime: DateTime(2030, 12, 25, 13, 5),
        checkInTime: DateTime(2030, 12, 25, 15, 0),
      );

      final json = plan.toJson();
      final restored = DatePlan.fromJson(json);

      expect(restored, plan);
    });

    test('falls back to scheduled for unknown status value', () {
      final json = buildPlan().toJson()..['status'] = 'unknown_status';
      final restored = DatePlan.fromJson(json);

      expect(restored.status, DatePlanStatus.scheduled);
    });

    test('isUpcoming is true only for future scheduled plans', () {
      final futurePlan = buildPlan(
        dateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      final pastPlan = buildPlan(
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final completedFuturePlan = buildPlan(
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        status: DatePlanStatus.completed,
      );

      expect(futurePlan.isUpcoming, isTrue);
      expect(pastPlan.isUpcoming, isFalse);
      expect(completedFuturePlan.isUpcoming, isFalse);
    });

    test('reports check-in overdue only when expected and not checked in', () {
      final overduePlan = buildPlan(
        checkInTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      final checkedInPlan = buildPlan(
        checkInTime: DateTime.now().subtract(const Duration(minutes: 30)),
        checkedInAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final noCheckInPlan = buildPlan();

      expect(overduePlan.isCheckInOverdue, isTrue);
      expect(checkedInPlan.isCheckInOverdue, isFalse);
      expect(noCheckInPlan.isCheckInOverdue, isFalse);
    });

    test('formats date labels and time string correctly', () {
      final now = DateTime.now();
      final todayPlan = buildPlan(
        dateTime: DateTime(now.year, now.month, now.day, 9, 7),
      );
      final tomorrowPlan = buildPlan(
        dateTime: DateTime(now.year, now.month, now.day + 1, 13, 5),
      );
      final otherDayPlan = buildPlan(
        dateTime: DateTime(2030, 12, 25, 13, 5),
      );

      expect(todayPlan.formattedDate, 'Today');
      expect(tomorrowPlan.formattedDate, 'Tomorrow');
      expect(otherDayPlan.formattedDate, '12/25/2030');
      expect(todayPlan.formattedTime, '9:07 AM');
      expect(otherDayPlan.formattedTime, '1:05 PM');
    });

    test('timeUntilDate reflects future offset', () {
      final plan = buildPlan(
        dateTime: DateTime.now().add(const Duration(hours: 3)),
      );

      expect(plan.timeUntilDate.inHours, inInclusiveRange(2, 3));
    });
  });

  group('EmergencyContact', () {
    test('parses default notification flags when absent', () {
      final contact = EmergencyContact.fromJson(const {
        'name': 'Sam',
        'phone': '+15551234567',
      });

      expect(contact.name, 'Sam');
      expect(contact.phone, '+15551234567');
      expect(contact.notifyBySms, isTrue);
      expect(contact.notifyByEmail, isFalse);
    });

    test('serializes all fields', () {
      const contact = EmergencyContact(
        name: 'Sam',
        phone: '+15551234567',
        email: 'sam@example.com',
        relationship: 'sibling',
        notifyBySms: false,
        notifyByEmail: true,
      );

      expect(contact.toJson(), {
        'name': 'Sam',
        'phone': '+15551234567',
        'email': 'sam@example.com',
        'relationship': 'sibling',
        'notifyBySms': false,
        'notifyByEmail': true,
      });
    });
  });
}
