import re

# 1. Update IncognitoService
with open("lib/features/discovery/data/services/incognito_service.dart", "r") as f:
    text = f.read()

text = text.replace("class IncognitoService {", "import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';\n\nclass IncognitoService implements IncognitoRepository {")
with open("lib/features/discovery/data/services/incognito_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';\nimport 'package:crushhour/features/discovery/data/services/incognito_service.dart';\n"
if "incognito_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<IncognitoRepository>.value(\n          value: IncognitoService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update SettingsScreen
with open("lib/features/settings/presentation/screens/settings_screen.dart", "r") as f:
    settings = f.read()

settings = settings.replace("import 'package:crushhour/features/discovery/data/services/incognito_service.dart';", "import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';")
# Use context.read<IncognitoRepository>()
# But since settings_screen a StatefulWidget, let's substitute directly
settings = settings.replace("IncognitoService.instance", "context.read<IncognitoRepository>()")

with open("lib/features/settings/presentation/screens/settings_screen.dart", "w") as f:
    f.write(settings)

