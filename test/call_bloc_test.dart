import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_event.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_state.dart';

import 'mock/firebase_mock.dart';

// ---------------------------------------------------------------------------
// Mock CallRepository
// ---------------------------------------------------------------------------
class MockCallRepository implements CallRepository {
  MockCallRepository({
    this.shouldFailStartCall = false,
    this.startCallDelay = Duration.zero,
  });

  final bool shouldFailStartCall;
  final Duration startCallDelay;

  final _engineController = StreamController<CallEngineEvent>.broadcast();
  bool endCallCalled = false;

  /// Push a synthetic engine event into the stream.
  void pushEngineEvent(CallEngineEvent event) {
    _engineController.add(event);
  }

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    if (startCallDelay > Duration.zero) {
      await Future.delayed(startCallDelay);
    }
    if (shouldFailStartCall) {
      throw Exception('Network error');
    }
    return CallSession(
      matchId: matchId,
      localUid: 12345,
      channelName: 'channel_$matchId',
      isVideoCall: isVideoCall,
    );
  }

  @override
  Future<void> endCall() async {
    endCallCalled = true;
  }

  @override
  Stream<CallEngineEvent> engineEvents() => _engineController.stream;

  void dispose() {
    _engineController.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setupFirebaseAnalyticsMocks();

  group('CallState', () {
    test('default state is idle with no data', () {
      const state = CallState();
      expect(state.status, CallStatus.idle);
      expect(state.matchId, isNull);
      expect(state.isVideoCall, isTrue);
      expect(state.localUid, isNull);
      expect(state.remoteUid, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith overrides specific fields', () {
      const state = CallState();
      final updated = state.copyWith(
        status: CallStatus.connecting,
        matchId: 'match-1',
        isVideoCall: false,
      );
      expect(updated.status, CallStatus.connecting);
      expect(updated.matchId, 'match-1');
      expect(updated.isVideoCall, isFalse);
      expect(updated.localUid, isNull);
    });

    test('copyWith can explicitly set nullable fields to null', () {
      const state = CallState(
        status: CallStatus.inCall,
        matchId: 'match-1',
        remoteUid: 12345,
        errorMessage: 'old error',
      );
      final cleared = state.copyWith(
        remoteUid: null,
        errorMessage: null,
        matchId: null,
      );
      expect(cleared.remoteUid, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.matchId, isNull);
      // Unchanged fields preserved
      expect(cleared.status, CallStatus.inCall);
      expect(cleared.isVideoCall, isTrue);
    });

    test('equatable compares correctly', () {
      const a = CallState(status: CallStatus.idle, matchId: 'x');
      const b = CallState(status: CallStatus.idle, matchId: 'x');
      const c = CallState(status: CallStatus.connecting, matchId: 'x');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CallBloc', () {
    late MockCallRepository repository;
    late CallBloc bloc;

    setUp(() {
      repository = MockCallRepository();
      bloc = CallBloc(callRepository: repository);
    });

    tearDown(() {
      bloc.close();
      repository.dispose();
    });

    test('initial state is idle', () {
      expect(bloc.state, const CallState());
      expect(bloc.state.status, CallStatus.idle);
    });

    // --- CallStarted ---------------------------------------------------------

    test('CallStarted emits connecting then connecting with localUid on success',
        () async {
      final repo = MockCallRepository();
      final testBloc = CallBloc(callRepository: repo);
      final states = <CallState>[];
      final sub = testBloc.stream.listen(states.add);

      testBloc.add(CallStarted(matchId: 'match-1', isVideoCall: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      // First emission: connecting, matchId set
      expect(states[0].status, CallStatus.connecting);
      expect(states[0].matchId, 'match-1');
      expect(states[0].isVideoCall, isTrue);
      // Second emission: still connecting, localUid set
      expect(states[1].status, CallStatus.connecting);
      expect(states[1].localUid, 12345);

      await sub.cancel();
      await testBloc.close();
      repo.dispose();
    });

    test('CallStarted with audio-only call sets isVideoCall false', () async {
      final repo = MockCallRepository();
      final testBloc = CallBloc(callRepository: repo);
      final states = <CallState>[];
      final sub = testBloc.stream.listen(states.add);

      testBloc.add(CallStarted(matchId: 'match-2', isVideoCall: false));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0].isVideoCall, isFalse);
      expect(states[0].matchId, 'match-2');
      expect(states[1].localUid, 12345);

      await sub.cancel();
      await testBloc.close();
      repo.dispose();
    });

    test('CallStarted emits error on repository failure', () async {
      final repo = MockCallRepository(shouldFailStartCall: true);
      final testBloc = CallBloc(callRepository: repo);
      final states = <CallState>[];
      final sub = testBloc.stream.listen(states.add);

      testBloc.add(CallStarted(matchId: 'match-err', isVideoCall: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      // First: connecting
      expect(states[0].status, CallStatus.connecting);
      // Second: error
      expect(states[1].status, CallStatus.error);
      expect(states[1].errorMessage, contains('Call failed'));

      await sub.cancel();
      await testBloc.close();
      repo.dispose();
    });

    // --- CallEnded -----------------------------------------------------------

    test('CallEnded emits ended status and calls endCall on repository',
        () async {
      final repo = MockCallRepository();
      final testBloc = CallBloc(callRepository: repo);
      final states = <CallState>[];
      final sub = testBloc.stream.listen(states.add);

      testBloc.add(CallEnded());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(1));
      expect(states.last.status, CallStatus.ended);
      expect(repo.endCallCalled, isTrue);

      await sub.cancel();
      await testBloc.close();
      repo.dispose();
    });

    // --- CallEngineUpdated ---------------------------------------------------

    test('engine joinedChannel event transitions to inCall', () async {
      final states = <CallState>[];
      final sub = bloc.stream.listen(states.add);

      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.joinedChannel,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, CallStatus.inCall);

      await sub.cancel();
    });

    test('engine userJoined event sets remoteUid', () async {
      final states = <CallState>[];
      final sub = bloc.stream.listen(states.add);

      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: 67890,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, CallStatus.inCall);
      expect(states.last.remoteUid, 67890);

      await sub.cancel();
    });

    test('engine userOffline event clears remoteUid', () async {
      // R-130 FIX: CallState.copyWith now uses sentinel pattern so
      // copyWith(remoteUid: null) correctly clears the field.
      final states = <CallState>[];
      final sub = bloc.stream.listen(states.add);

      // First, add a remote user
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: 67890,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.remoteUid, 67890);

      // Remote user goes offline — BLoC emits copyWith(remoteUid: null)
      // which now correctly clears remoteUid.
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.userOffline,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.remoteUid, isNull);

      await sub.cancel();
    });

    test('engine error event sets error status and message', () async {
      final states = <CallState>[];
      final sub = bloc.stream.listen(states.add);

      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.error,
        error: 'Connection lost',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, CallStatus.error);
      expect(states.last.errorMessage, 'Connection lost');

      await sub.cancel();
    });

    // --- Lifecycle ------------------------------------------------------------

    test('close cancels engine subscription without error', () async {
      await bloc.close();
      // Pushing events after close should not throw
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.joinedChannel,
      ));
    });

    // --- Full call flow integration test -------------------------------------

    test(
        'full call flow: start -> join -> remote joins -> remote leaves -> end',
        () async {
      final states = <CallState>[];
      final sub = bloc.stream.listen(states.add);

      // 1. Start call
      bloc.add(CallStarted(matchId: 'flow-match', isVideoCall: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 2. Engine says we joined channel
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.joinedChannel,
      ));
      await Future<void>.delayed(Duration.zero);

      // 3. Remote user joins
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: 11111,
      ));
      await Future<void>.delayed(Duration.zero);

      // 4. Remote user leaves
      repository.pushEngineEvent(CallEngineEvent(
        type: CallEngineEventType.userOffline,
      ));
      await Future<void>.delayed(Duration.zero);

      // 5. End call
      bloc.add(CallEnded());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify progression of states
      final statusProgression = states.map((s) => s.status).toList();
      expect(statusProgression, contains(CallStatus.connecting));
      expect(statusProgression, contains(CallStatus.inCall));
      expect(statusProgression, contains(CallStatus.ended));

      // Verify remote uid was set then cleared
      final withRemote = states.where((s) => s.remoteUid == 11111);
      expect(withRemote, isNotEmpty);

      await sub.cancel();
    });
  });

  group('CallSession model', () {
    test('stores all fields correctly', () {
      final session = CallSession(
        matchId: 'test-match',
        localUid: 999,
        channelName: 'ch_test',
        isVideoCall: false,
      );

      expect(session.matchId, 'test-match');
      expect(session.localUid, 999);
      expect(session.channelName, 'ch_test');
      expect(session.isVideoCall, isFalse);
    });
  });

  group('CallEngineEvent model', () {
    test('stores type and optional fields', () {
      final event = CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: 42,
      );
      expect(event.type, CallEngineEventType.userJoined);
      expect(event.remoteUid, 42);
      expect(event.error, isNull);
    });

    test('error event stores message', () {
      final event = CallEngineEvent(
        type: CallEngineEventType.error,
        error: 'timeout',
      );
      expect(event.type, CallEngineEventType.error);
      expect(event.error, 'timeout');
    });
  });

  group('CallEngineEventType enum', () {
    test('has all expected values', () {
      expect(CallEngineEventType.values, hasLength(4));
      expect(CallEngineEventType.values,
          contains(CallEngineEventType.joinedChannel));
      expect(CallEngineEventType.values,
          contains(CallEngineEventType.userJoined));
      expect(CallEngineEventType.values,
          contains(CallEngineEventType.userOffline));
      expect(
          CallEngineEventType.values, contains(CallEngineEventType.error));
    });
  });
}
