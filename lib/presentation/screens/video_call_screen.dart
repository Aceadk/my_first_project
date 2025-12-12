import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherName;

  const VideoCallScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _caller;
  RTCPeerConnection? _callee;
  MediaStream? _localStream;
  bool _connecting = true;
  String? _error;
  bool _cleanedUp = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      });
      _localStream = stream;
      _localRenderer.srcObject = stream;

      final config = {
        'sdpSemantics': 'unified-plan',
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };
      final caller = await createPeerConnection(config);
      final callee = await createPeerConnection(config);

      for (final track in stream.getTracks()) {
        await caller.addTrack(track, stream);
      }

      caller.onIceCandidate = (candidate) {
        callee.addCandidate(candidate);
      };
      callee.onIceCandidate = (candidate) {
        caller.addCandidate(candidate);
      };

      callee.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams.first;
        }
      };

      final offer = await caller.createOffer();
      await caller.setLocalDescription(offer);
      await callee.setRemoteDescription(offer);
      final answer = await callee.createAnswer();
      await callee.setLocalDescription(answer);
      await caller.setRemoteDescription(answer);

      if (!mounted) return;
      setState(() {
        _caller = caller;
        _callee = callee;
        _connecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  Future<void> _cleanup() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    await _localStream?.dispose();
    await _caller?.close();
    await _callee?.close();
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
  }

  Future<void> _hangUp() async {
    await _cleanup();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video call with ${widget.otherName}'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(child: _buildVideoStage()),
            if (_connecting) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 72),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _hangUp,
        child: const Icon(Icons.call_end),
      ),
    );
  }

  Widget _buildVideoStage() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: _remoteRenderer.srcObject == null
                ? Center(
                    child: Text(
                      _connecting ? 'Connecting video...' : 'Remote video unavailable',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                : RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            width: 120,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localRenderer.srcObject == null
                    ? const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white54,
                        ),
                      )
                    : RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
