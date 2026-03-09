import re

# 1. Move RealtimeMatchNotification to RealtimeMatchRepository
with open("lib/features/discovery/data/services/realtime_match_service.dart", "r") as f:
    text = f.read()

# Extract RealtimeMatchNotification
match_class = re.search(r'/// Data class for real-time match notification\.\nclass RealtimeMatchNotification \{.*?\n\}\n', text, flags=re.DOTALL)
if match_class:
    class_str = match_class.group(0)
    # Remove from service
    text = text.replace(class_str, "")
    with open("lib/features/discovery/data/services/realtime_match_service.dart", "w") as f:
        f.write(text)
        
    # Append to repository
    with open("lib/features/discovery/domain/repositories/realtime_match_repository.dart", "r") as f:
        repo_text = f.read()
    
    # Remove the import of service
    repo_text = repo_text.replace("import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';", "")
    repo_text = class_str + "\n" + repo_text
    
    with open("lib/features/discovery/domain/repositories/realtime_match_repository.dart", "w") as f:
        f.write(repo_text)

# 2. Fix CallHistoryScreen
with open("lib/features/calls/presentation/screens/call_history_screen.dart", "r") as f:
    history = f.read()

# Make sure flutter_bloc is imported
if "import 'package:flutter_bloc/flutter_bloc.dart';" not in history:
    history = "import 'package:flutter_bloc/flutter_bloc.dart';\n" + history

# Replace leftover CallService import if exists
history = history.replace("import 'package:crushhour/features/calls/data/services/call_service.dart';", "import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';")
history = history.replace("import '../../data/services/call_service.dart';", "import '../../domain/repositories/call_manager_repository.dart';")

with open("lib/features/calls/presentation/screens/call_history_screen.dart", "w") as f:
    f.write(history)

