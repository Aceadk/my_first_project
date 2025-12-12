import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/call/call_bloc.dart';
import '../../logic/call/call_event.dart';
import '../../logic/call/call_state.dart';

class CallScreen extends StatelessWidget {
  final String matchId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.matchId,
    required this.isVideoCall,
  });

  RtcEngine? _engine(BuildContext context) {
    final repo = context.read<CallBloc>().callRepository;
    try {
      return (repo as dynamic).engine as RtcEngine?;
    } catch (_) {
      try {
        return (repo as dynamic)._engine as RtcEngine?;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<CallBloc>().add(
          CallStarted(matchId: matchId, isVideoCall: isVideoCall),
        );

    final rtcEngine = _engine(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            Widget content;
            if (state.status == CallStatus.error) {
              content = Center(
                child: Text(
                  state.errorMessage ?? 'Error',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else if (state.status == CallStatus.connecting) {
              content = const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              content = Stack(
                children: [
                  if (isVideoCall && state.remoteUid != null && rtcEngine != null)
                    AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: rtcEngine,
                        connection: RtcConnection(
                          channelId: matchId,
                        ),
                        canvas: VideoCanvas(
                          uid: state.remoteUid,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        'Waiting for other user...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  // local preview (small)
                  if (isVideoCall && state.localUid != null && rtcEngine != null)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: SizedBox(
                        width: 120,
                        height: 180,
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: rtcEngine,
                            canvas: VideoCanvas(
                              uid: state.localUid,
                              renderMode: RenderModeType.renderModeHidden,
                            ),
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: () {
                            context.read<CallBloc>().add(CallEnded());
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.call_end),
                        )
                      ],
                    ),
                  )
                ],
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}
