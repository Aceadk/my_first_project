// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/core/network/realtime/firebase_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return super.noSuchMethod(
          Invocation.method(#collection, [collectionPath]),
          returnValue: _MockCollectionReference(),
        )
        as CollectionReference<Map<String, dynamic>>;
  }
}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return super.noSuchMethod(
          Invocation.method(#doc, [path]),
          returnValue: _MockDocumentReference(),
        )
        as DocumentReference<Map<String, dynamic>>;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return super.noSuchMethod(
          Invocation.method(#snapshots, [], {
            #includeMetadataChanges: includeMetadataChanges,
            #source: source,
          }),
          returnValue: const Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
        )
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }
}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return super.noSuchMethod(
          Invocation.method(#snapshots, [], {
            #includeMetadataChanges: includeMetadataChanges,
            #source: source,
          }),
          returnValue:
              const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty(),
        )
        as Stream<DocumentSnapshot<Map<String, dynamic>>>;
  }
}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return super.noSuchMethod(
          Invocation.method(#where, [field], {
            #isEqualTo: isEqualTo,
            #isNotEqualTo: isNotEqualTo,
            #isLessThan: isLessThan,
            #isLessThanOrEqualTo: isLessThanOrEqualTo,
            #isGreaterThan: isGreaterThan,
            #isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
            #arrayContains: arrayContains,
            #arrayContainsAny: arrayContainsAny,
            #whereIn: whereIn,
            #whereNotIn: whereNotIn,
            #isNull: isNull,
          }),
          returnValue: this,
        )
        as Query<Map<String, dynamic>>;
  }
}

void main() {
  group('FirebaseRealtimeService subscription lifecycle', () {
    late _MockFirebaseFirestore firestore;
    late _MockCollectionReference usersCollection;
    late _MockDocumentReference userDoc;
    late FirebaseRealtimeService service;

    setUp(() {
      firestore = _MockFirebaseFirestore();
      usersCollection = _MockCollectionReference();
      userDoc = _MockDocumentReference();
      service = FirebaseRealtimeService.test(firestore: firestore);

      when(firestore.collection('users')).thenReturn(usersCollection);
      when(usersCollection.doc('user-1')).thenReturn(userDoc);
    });

    test(
      'subscribeToDocument replaces existing subscription for same key',
      () async {
        var firstCancelled = false;
        final firstController =
            StreamController<DocumentSnapshot<Map<String, dynamic>>>(
              onCancel: () {
                firstCancelled = true;
              },
            );
        final secondController =
            StreamController<DocumentSnapshot<Map<String, dynamic>>>();
        var callCount = 0;
        when(userDoc.snapshots()).thenAnswer((_) {
          callCount += 1;
          return callCount == 1
              ? firstController.stream
              : secondController.stream;
        });

        final receivedPayloads = <Map<String, dynamic>?>[];
        final firstId = service.subscribeToDocument(
          collection: 'users',
          documentId: 'user-1',
          onData: receivedPayloads.add,
        );
        final secondId = service.subscribeToDocument(
          collection: 'users',
          documentId: 'user-1',
          onData: receivedPayloads.add,
        );

        expect(firstId, 'users_user-1');
        expect(secondId, 'users_user-1');
        expect(service.activeSubscriptionCount, 1);

        await Future<void>.delayed(Duration.zero);
        expect(firstCancelled, isTrue);

        final snapshot = _MockDocumentSnapshot();
        when(snapshot.data()).thenReturn({'name': 'Taylor'});
        secondController.add(snapshot);
        await Future<void>.delayed(Duration.zero);

        expect(receivedPayloads, <Map<String, dynamic>?>[
          {'name': 'Taylor'},
        ]);

        service.cancelAllSubscriptions();
        await Future<void>.delayed(Duration.zero);
        await firstController.close();
        await secondController.close();
      },
    );

    test('cancelSubscription removes and cancels the tracked subscription', () async {
      var cancelled = false;
      final collectionController =
          StreamController<QuerySnapshot<Map<String, dynamic>>>(
            onCancel: () {
              cancelled = true;
            },
          );
      final matchesCollection = _MockCollectionReference();
      when(firestore.collection('matches')).thenReturn(matchesCollection);
      when(matchesCollection.snapshots())
          .thenAnswer((_) => collectionController.stream);

      final subscriptionId = service.subscribeToCollection(
        collection: 'matches',
        onChanges: (_) {},
      );
      expect(service.activeSubscriptionCount, 1);

      service.cancelSubscription(subscriptionId);
      await Future<void>.delayed(Duration.zero);

      expect(cancelled, isTrue);
      expect(service.activeSubscriptionCount, 0);

      await collectionController.close();
    });

    test('cancelAllSubscriptions cancels all active listeners', () async {
      var firstCancelled = false;
      var secondCancelled = false;
      final firstController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>(
            onCancel: () {
              firstCancelled = true;
            },
          );
      final secondController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>(
            onCancel: () {
              secondCancelled = true;
            },
          );

      final secondDoc = _MockDocumentReference();
      when(usersCollection.doc('user-2')).thenReturn(secondDoc);
      when(userDoc.snapshots()).thenAnswer((_) => firstController.stream);
      when(secondDoc.snapshots()).thenAnswer((_) => secondController.stream);

      service.subscribeToDocument(
        collection: 'users',
        documentId: 'user-1',
        onData: (_) {},
      );
      service.subscribeToDocument(
        collection: 'users',
        documentId: 'user-2',
        onData: (_) {},
      );
      expect(service.activeSubscriptionCount, 2);

      service.cancelAllSubscriptions();
      await Future<void>.delayed(Duration.zero);

      expect(firstCancelled, isTrue);
      expect(secondCancelled, isTrue);
      expect(service.activeSubscriptionCount, 0);

      await firstController.close();
      await secondController.close();
    });
  });

  group('FirebaseRealtimeService filter mappings', () {
    late _MockFirebaseFirestore firestore;
    late FirebaseRealtimeService service;
    late _MockQuery query;

    setUp(() {
      firestore = _MockFirebaseFirestore();
      service = FirebaseRealtimeService.test(firestore: firestore);
      query = _MockQuery();
    });

    test('equals maps to isEqualTo', () {
      when(query.where('status', isEqualTo: 'active')).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'status',
          operator: FilterOperator.equals,
          value: 'active',
        ),
      );

      expect(mapped, same(query));
      verify(query.where('status', isEqualTo: 'active')).called(1);
    });

    test('notEquals maps to isNotEqualTo', () {
      when(query.where('status', isNotEqualTo: 'blocked')).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'status',
          operator: FilterOperator.notEquals,
          value: 'blocked',
        ),
      );

      expect(mapped, same(query));
      verify(query.where('status', isNotEqualTo: 'blocked')).called(1);
    });

    test('lessThan maps to isLessThan', () {
      when(query.where('age', isLessThan: 30)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'age',
          operator: FilterOperator.lessThan,
          value: 30,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('age', isLessThan: 30)).called(1);
    });

    test('lessThanOrEqual maps to isLessThanOrEqualTo', () {
      when(query.where('age', isLessThanOrEqualTo: 30)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'age',
          operator: FilterOperator.lessThanOrEqual,
          value: 30,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('age', isLessThanOrEqualTo: 30)).called(1);
    });

    test('greaterThan maps to isGreaterThan', () {
      when(query.where('age', isGreaterThan: 18)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'age',
          operator: FilterOperator.greaterThan,
          value: 18,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('age', isGreaterThan: 18)).called(1);
    });

    test('greaterThanOrEqual maps to isGreaterThanOrEqualTo', () {
      when(query.where('age', isGreaterThanOrEqualTo: 18)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'age',
          operator: FilterOperator.greaterThanOrEqual,
          value: 18,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('age', isGreaterThanOrEqualTo: 18)).called(1);
    });

    test('arrayContains maps to arrayContains', () {
      when(query.where('participant_ids', arrayContains: 'user-1'))
          .thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'participant_ids',
          operator: FilterOperator.arrayContains,
          value: 'user-1',
        ),
      );

      expect(mapped, same(query));
      verify(query.where('participant_ids', arrayContains: 'user-1')).called(1);
    });

    test('arrayContainsAny maps to arrayContainsAny', () {
      const values = <String>['user-1', 'user-2'];
      when(query.where('participant_ids', arrayContainsAny: values))
          .thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'participant_ids',
          operator: FilterOperator.arrayContainsAny,
          value: values,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('participant_ids', arrayContainsAny: values)).called(1);
    });

    test('whereIn maps to whereIn', () {
      const values = <String>['active', 'pending'];
      when(query.where('status', whereIn: values)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'status',
          operator: FilterOperator.whereIn,
          value: values,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('status', whereIn: values)).called(1);
    });

    test('whereNotIn maps to whereNotIn', () {
      const values = <String>['blocked', 'suspended'];
      when(query.where('status', whereNotIn: values)).thenReturn(query);

      final mapped = service.applyFilterForTesting(
        query,
        const QueryFilter(
          field: 'status',
          operator: FilterOperator.whereNotIn,
          value: values,
        ),
      );

      expect(mapped, same(query));
      verify(query.where('status', whereNotIn: values)).called(1);
    });
  });
}
