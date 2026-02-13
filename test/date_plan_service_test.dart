import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';
import 'core/services/firebase_mocks.dart';

void main() {
  group('DatePlanService', () {
    late DatePlanService service;

    setUpAll(() {
      setupFirebaseCoreMocks();
      service = DatePlanService.instance;
    });

    test('createDatePlan stores and returns a scheduled plan', () async {
      final now = DateTime.now();
      final userId = _uid('create');

      final plan = await service.createDatePlan(
        userId: userId,
        matchId: 'match-a',
        matchName: 'Alex',
        dateTime: now.add(const Duration(days: 1)),
        location: 'Coffee Shop',
        notes: 'Near window',
        checkInDelay: const Duration(hours: 3),
      );

      expect(plan.id, startsWith('date_'));
      expect(plan.status, DatePlanStatus.scheduled);
      expect(plan.checkInTime, plan.dateTime.add(const Duration(hours: 3)));
      expect(service.getPlan(plan.id), plan);
    });

    test('addEmergencyContact and removeEmergencyContact update contacts',
        () async {
      final userId = _uid('contacts');
      final plan = await service.createDatePlan(
        userId: userId,
        matchId: 'match-b',
        matchName: 'Blake',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Museum',
      );

      const contact = EmergencyContact(
        name: 'Sam',
        phone: '+15550000001',
        email: null,
        notifyBySms: true,
      );

      final withContact = await service.addEmergencyContact(
        planId: plan.id,
        contact: contact,
      );
      expect(withContact.sharedWith.length, 1);
      expect(withContact.sharedWith.first.phone, '+15550000001');

      final removed = await service.removeEmergencyContact(
        planId: plan.id,
        contactPhone: '+15550000001',
      );
      expect(removed.sharedWith, isEmpty);
    });

    test('startDate, checkIn, endDateSafely, cancelPlan, triggerEmergencyAlert',
        () async {
      final userId = _uid('status');

      final plan = await service.createDatePlan(
        userId: userId,
        matchId: 'match-c',
        matchName: 'Casey',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Park',
      );

      final started = await service.startDate(plan.id);
      expect(started.status, DatePlanStatus.ongoing);

      final confirmedFuture =
          service.checkInStream.firstWhere((s) => s == CheckInStatus.confirmed);
      final checkedIn = await service.checkIn(plan.id);
      expect(checkedIn.checkedInAt, isNotNull);
      expect(await confirmedFuture, CheckInStatus.confirmed);

      final ended = await service.endDateSafely(plan.id);
      expect(ended.status, DatePlanStatus.completed);
      expect(ended.checkedInAt, isNotNull);

      await service.cancelPlan(plan.id);
      expect(service.getPlan(plan.id)?.status, DatePlanStatus.cancelled);

      await service.triggerEmergencyAlert(plan.id);
      expect(service.getPlan(plan.id)?.status, DatePlanStatus.emergency);
    });

    test('getActivePlans returns only scheduled/ongoing plans', () async {
      final userId = _uid('active');

      final scheduled = await service.createDatePlan(
        userId: userId,
        matchId: 'match-d',
        matchName: 'Dana',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Cafe',
      );
      final toComplete = await service.createDatePlan(
        userId: userId,
        matchId: 'match-e',
        matchName: 'Elliot',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Library',
      );
      final ongoing = await service.startDate(toComplete.id);
      await service.endDateSafely(ongoing.id);

      final active = await service.getActivePlans(userId);
      final activeIds = active.map((e) => e.id).toSet();

      expect(activeIds.contains(scheduled.id), isTrue);
      expect(activeIds.contains(toComplete.id), isFalse);
    });

    test('getAllPlans returns plans sorted by date desc', () async {
      final userId = _uid('all-plans');
      final older = await service.createDatePlan(
        userId: userId,
        matchId: 'match-f',
        matchName: 'Finn',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Gallery',
      );
      final newer = await service.createDatePlan(
        userId: userId,
        matchId: 'match-g',
        matchName: 'Gray',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        location: 'Restaurant',
      );

      final plans = await service.getAllPlans(userId);

      expect(plans.first.id, newer.id);
      expect(plans.last.id, older.id);
    });

    test('throws for unknown plan IDs on required operations', () async {
      expect(
        () => service.startDate('missing-plan'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.checkIn('missing-plan'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.addEmergencyContact(
          planId: 'missing-plan',
          contact: const EmergencyContact(name: 'A', phone: '1'),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.removeEmergencyContact(
          planId: 'missing-plan',
          contactPhone: '1',
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.endDateSafely('missing-plan'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.triggerEmergencyAlert('missing-plan'),
        throwsA(isA<Exception>()),
      );
    });

    test('emits due and overdue when check-in is missed for an ongoing date',
        () {
      fakeAsync((async) {
        final userId = _uid('missed-checkin');
        final statuses = <CheckInStatus>[];
        final subscription = service.checkInStream.listen(statuses.add);

        service
            .createDatePlan(
              userId: userId,
              matchId: 'match-h',
              matchName: 'Harper',
              dateTime: DateTime.now().add(const Duration(seconds: 1)),
              location: 'Plaza',
              checkInDelay: Duration.zero,
            )
            .then((plan) => service.startDate(plan.id));

        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(statuses.contains(CheckInStatus.due), isTrue);

        async.elapse(const Duration(minutes: 15));
        async.flushMicrotasks();

        expect(statuses.contains(CheckInStatus.overdue), isTrue);
        subscription.cancel();
      });
    });
  });
}

String _uid(String suffix) => 'test_${suffix}_${DateTime.now().microsecondsSinceEpoch}';
