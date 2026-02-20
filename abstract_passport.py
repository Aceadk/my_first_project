import re

# 1. Update PassportLocationsService
with open("lib/features/discovery/data/services/passport_locations_service.dart", "r") as f:
    text = f.read()

text = text.replace("class PassportLocationsService {", "import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';\n\nclass PassportLocationsService implements PassportLocationsRepository {")
with open("lib/features/discovery/data/services/passport_locations_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';\nimport 'package:crushhour/features/discovery/data/services/passport_locations_service.dart';\n"
if "passport_locations_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<PassportLocationsRepository>.value(\n          value: PassportLocationsService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update ProfileSetupScreen
with open("lib/features/profile/presentation/screens/profile_setup_screen.dart", "r") as f:
    setup = f.read()

setup = setup.replace("import 'package:crushhour/features/discovery/data/services/passport_locations_service.dart';", "import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';")
setup = setup.replace("  final _passportService = PassportLocationsService.instance;", "  late final _passportService = context.read<PassportLocationsRepository>();")

with open("lib/features/profile/presentation/screens/profile_setup_screen.dart", "w") as f:
    f.write(setup)

