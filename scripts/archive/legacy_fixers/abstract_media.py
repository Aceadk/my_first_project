import re

# 1. Update ProfileMediaService
with open("lib/features/profile/data/services/profile_media_service.dart", "r") as f:
    text = f.read()

text = text.replace("class ProfileMediaService {", "import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';\n\nclass ProfileMediaService implements ProfileMediaRepository {")
with open("lib/features/profile/data/services/profile_media_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';\nimport 'package:crushhour/features/profile/data/services/profile_media_service.dart';\n"
if "profile_media_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<ProfileMediaRepository>.value(\n          value: ProfileMediaService()),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update ProfileSetupScreen
with open("lib/features/profile/presentation/screens/profile_setup_screen.dart", "r") as f:
    setup = f.read()

setup = setup.replace("import 'package:crushhour/features/profile/data/services/profile_media_service.dart';", "import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';")
setup = setup.replace("  final _mediaService = ProfileMediaService();", "  late final _mediaService = context.read<ProfileMediaRepository>();")

with open("lib/features/profile/presentation/screens/profile_setup_screen.dart", "w") as f:
    f.write(setup)

# 4. Update ProfileEditScreen
with open("lib/features/profile/presentation/screens/profile_edit_screen.dart", "r") as f:
    edit = f.read()

edit = edit.replace("import 'package:crushhour/features/profile/data/services/profile_media_service.dart';", "import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';")
edit = edit.replace("  final _mediaService = ProfileMediaService();", "  late final _mediaService = context.read<ProfileMediaRepository>();")

with open("lib/features/profile/presentation/screens/profile_edit_screen.dart", "w") as f:
    f.write(edit)

