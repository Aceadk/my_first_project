import os

# 1. Create CallManagerRepository
with open("lib/features/calls/domain/repositories/call_manager_repository.dart", "w") as f:
    f.write('''import 'dart:async';
import 'package:crushhour/features/calls/domain/models/call.dart';

enum CallUIState { idle, outgoing, incoming, connecting, connected, ended }

abstract class CallManagerRepository {
  Stream<Call> get callStream;
  Stream<CallUIState> get callStateStream;
  Stream<Call> get missedCallStream;
  Call? get activeCall;
  bool get hasActiveCall;
  bool get isMuted;
  bool get isSpeakerOn;
  bool get isVideoEnabled;
  bool get isFrontCamera;

  Future<Call> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType type,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  });
  Future<void> acceptCall({CallType? asType});
  Future<void> declineCall();
  Future<void> endCall();
  void toggleMute();
  void toggleSpeaker();
  void toggleVideo();
  void switchCamera();
  void handleIncomingCall(Call incomingCall);
  Future<List<Call>> getCallHistory(String userId, {int limit = 20, DateTime? before});
  void dispose();
}
''')

def update_file(filepath, replacements):
    if not os.path.exists(filepath): return
    with open(filepath, "r") as f:
        content = f.read()
    for o, n in replacements:
        content = content.replace(o, n)
    with open(filepath, "w") as f:
        f.write(content)

# 2. Update call_service.dart
update_file("lib/features/calls/data/services/call_service.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';"),
    ("class CallService implements CallRepository {", "class CallService implements CallManagerRepository {")
])

# 3. Update di.dart
update_file("lib/core/di.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';"),
    ("RepositoryProvider<CallRepository>.value(", "RepositoryProvider<CallManagerRepository>.value("),
])

# 4. Update app.dart
update_file("lib/app.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';"),
    ("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
])

# 5. Update call_screen.dart
update_file("lib/features/calls/presentation/screens/call_screen.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';"),
    ("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
])

# 6. Update incoming_call_screen.dart
update_file("lib/features/calls/presentation/screens/incoming_call_screen.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';"),
    ("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
])

# 7. Update call_history_screen.dart
update_file("lib/features/calls/presentation/screens/call_history_screen.dart", [
    ("import '../../domain/repositories/call_repository.dart';", "import '../../domain/repositories/call_manager_repository.dart';"),
    ("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
])

# 8. Update pip_video_overlay.dart
update_file("lib/features/calls/presentation/widgets/pip_video_overlay.dart", [
    ("import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';"),
    ("import '../../domain/repositories/call_repository.dart';", "import '../../domain/repositories/call_manager_repository.dart';"),
    ("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
])

