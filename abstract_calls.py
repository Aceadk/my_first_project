import re
import os

# 1. Update CallService and remove CallUIState from it.
with open("lib/features/calls/data/services/call_service.dart", "r") as f:
    text = f.read()

text = text.replace("class CallService {", "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';\n\nclass CallService implements CallRepository {")
text = re.sub(r'/// Call UI state for display\.\nenum CallUIState \{ idle, outgoing, incoming, connecting, connected, ended \}\n', '', text)
with open("lib/features/calls/data/services/call_service.dart", "w") as f:
    f.write(text)

# 2. Update CallKitService and remove CallKitEvent/CallKitEventType from it.
with open("lib/features/calls/data/services/callkit_service.dart", "r") as f:
    text = f.read()

# Remove the enums and classes
text = re.sub(r'enum CallKitEventType \{.*?\}\n\n', '', text, flags=re.DOTALL)
text = re.sub(r'class CallKitEvent \{.*?\}\n\n', '', text, flags=re.DOTALL)

text = text.replace("class CallKitService {", "import 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';\n\nclass CallKitService implements CallKitRepository {")
with open("lib/features/calls/data/services/callkit_service.dart", "w") as f:
    f.write(text)

# 3. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';\nimport 'package:crushhour/features/calls/data/services/call_service.dart';\nimport 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';\nimport 'package:crushhour/features/calls/data/services/callkit_service.dart';\n"
if "call_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<CallRepository>.value(\n          value: CallService.instance),\n      RepositoryProvider<CallKitRepository>.value(\n          value: CallKitService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 4. Update Consumers
def update_file(filepath, replacements):
    if not os.path.exists(filepath): return
    with open(filepath, "r") as f:
        content = f.read()
    for o, n in replacements:
        content = content.replace(o, n)
    with open(filepath, "w") as f:
        f.write(content)

update_file("lib/app.dart", [
    ("import 'package:crushhour/features/calls/data/services/call_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';"),
    ("import 'package:crushhour/features/calls/data/services/callkit_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';"),
    ("CallKitService.instance", "context.read<CallKitRepository>()"),
    ("CallService.instance", "context.read<CallRepository>()"),
])

update_file("lib/features/calls/presentation/screens/call_screen.dart", [
    ("import 'package:crushhour/features/calls/data/services/call_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';"),
    ("  final _callService = CallService.instance;", "  late final _callService = context.read<CallRepository>();"),
])

update_file("lib/features/calls/presentation/screens/incoming_call_screen.dart", [
    ("import 'package:crushhour/features/calls/data/services/call_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';"),
    ("  final _callService = CallService.instance;", "  late final _callService = context.read<CallRepository>();"),
])

update_file("lib/features/calls/presentation/screens/call_history_screen.dart", [
    ("import '../../data/services/call_service.dart';", "import '../../domain/repositories/call_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';"),
    ("  final _callService = CallService.instance;", "  late final _callService = context.read<CallRepository>();"),
])

update_file("lib/features/calls/presentation/widgets/pip_video_overlay.dart", [
    ("import 'package:crushhour/features/calls/data/services/call_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';"),
    ("import '../../data/services/call_service.dart';", "import '../../domain/repositories/call_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';"),
    ("CallService.instance", "context.read<CallRepository>()"),
])

