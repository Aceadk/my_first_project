import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'call_repository.dart';

class AgoraCallRepository implements CallRepository {
  final String agoraAppId;
  final RtcEngine _engine = createAgoraRtcEngine();
  final _controller = StreamController<CallEngineEvent>.broadcast();
  bool _initialized = false;

  AgoraCallRepository({required this.agoraAppId});

  RtcEngine get engine => _engine;

  @override
  Stream<CallEngineEvent> engineEvents() => _controller.stream;

  Future<void> _ensureInitialized(bool enableVideo) async {
    if (_initialized) return;
    await _engine.initialize(RtcEngineContext(appId: agoraAppId));
    if (enableVideo) {
      await _engine.enableVideo();
    } else {
      await _engine.disableVideo();
    }
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _controller.add(CallEngineEvent(type: CallEngineEventType.joinedChannel));
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        _controller.add(
          CallEngineEvent(
            type: CallEngineEventType.userJoined,
            remoteUid: uid,
          ),
        );
      },
      onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        _controller.add(
          CallEngineEvent(
            type: CallEngineEventType.userOffline,
            remoteUid: uid,
          ),
        );
      },
      onError: (err, msg) {
        _controller.add(
          CallEngineEvent(
            type: CallEngineEventType.error,
            error: '$err $msg',
          ),
        );
      },
    ));
    _initialized = true;
  }

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    await _ensureInitialized(isVideoCall);

    // Use a random local UID; for a real app, request from backend token call
    final localUid = DateTime.now().millisecondsSinceEpoch % 1000000;

    await _engine.joinChannel(
      token: '', // supply a real token from backend for production
      channelId: matchId,
      uid: localUid,
      options: const ChannelMediaOptions(),
    );

    return CallSession(
      matchId: matchId,
      localUid: localUid,
      channelName: matchId,
      isVideoCall: isVideoCall,
    );
  }

  @override
  Future<void> endCall() async {
    try {
      await _engine.leaveChannel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _engine.release();
    await _controller.close();
  }
}
