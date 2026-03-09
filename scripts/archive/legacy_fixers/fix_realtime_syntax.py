import re

# Fix realtime_match_repository.dart
with open("lib/features/discovery/domain/repositories/realtime_match_repository.dart", "r") as f:
    text = f.read()

text = text.replace("import 'dart:async';\n", "")
text = "import 'dart:async';\n\n" + text

with open("lib/features/discovery/domain/repositories/realtime_match_repository.dart", "w") as f:
    f.write(text)

# Fix realtime_match_service.dart
with open("lib/features/discovery/data/services/realtime_match_service.dart", "r") as f:
    text = f.read()

text = text.replace("import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';\n", "")
text = text.replace("import 'package:crushhour/core/app_logger.dart';\n", "import 'package:crushhour/core/app_logger.dart';\nimport 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';\n")

with open("lib/features/discovery/data/services/realtime_match_service.dart", "w") as f:
    f.write(text)

