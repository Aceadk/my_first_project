import re

# 1. Update RealtimeMatchService
with open("lib/features/discovery/data/services/realtime_match_service.dart", "r") as f:
    text = f.read()

text = text.replace("class RealtimeMatchService {", "import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';\n\nclass RealtimeMatchService implements RealtimeMatchRepository {")
with open("lib/features/discovery/data/services/realtime_match_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';\nimport 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';\n"
if "realtime_match_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<RealtimeMatchRepository>.value(\n          value: RealtimeMatchService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update app.dart
with open("lib/app.dart", "r") as f:
    app_text = f.read()

app_text = app_text.replace("import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';", "import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';")
app_text = app_text.replace("RealtimeMatchService.instance.onNewMatch", "context.read<RealtimeMatchRepository>().onNewMatch")
app_text = app_text.replace("RealtimeMatchService.instance.stopListening()", "context.read<RealtimeMatchRepository>().stopListening()")
app_text = app_text.replace("RealtimeMatchService.instance.startListening(userId)", "context.read<RealtimeMatchRepository>().startListening(userId)")

with open("lib/app.dart", "w") as f:
    f.write(app_text)

# 4. Update MatchesScreen
with open("lib/features/chat/presentation/screens/matches_screen.dart", "r") as f:
    matches = f.read()

matches = matches.replace("import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';", "import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';")
matches = matches.replace("RealtimeMatchService.instance", "context.read<RealtimeMatchRepository>()")

with open("lib/features/chat/presentation/screens/matches_screen.dart", "w") as f:
    f.write(matches)

