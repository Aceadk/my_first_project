import re

# 1. Update VoiceRecorderService
with open("lib/features/chat/data/services/voice_recorder_service.dart", "r") as f:
    text = f.read()

text = text.replace("class VoiceRecorderService {", "import 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';\n\nclass VoiceRecorderService implements VoiceRecorderRepository {")
with open("lib/features/chat/data/services/voice_recorder_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';\nimport 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';\n"
if "voice_recorder_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<VoiceRecorderRepository>.value(\n          value: VoiceRecorderService()),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update VoiceNoteRecorder widget
with open("lib/features/chat/presentation/widgets/voice_note_recorder.dart", "r") as f:
    voice_note = f.read()

voice_note = voice_note.replace("import '../../data/services/voice_recorder_service.dart';", "import '../../domain/repositories/voice_recorder_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';")
voice_note = voice_note.replace("  final _recorderService = VoiceRecorderService();", "  late final _recorderService = context.read<VoiceRecorderRepository>();\n")
# Wait, let's fix the dispose method
voice_note = voice_note.replace("    _recorderService.dispose();", "    _recorderService.cancelRecording();")

with open("lib/features/chat/presentation/widgets/voice_note_recorder.dart", "w") as f:
    f.write(voice_note)

