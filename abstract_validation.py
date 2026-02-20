import re

# 1. Update ProfileValidationService
with open("lib/features/profile/data/services/profile_validation_service.dart", "r") as f:
    text = f.read()

text = text.replace("class ProfileValidationService {", "import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';\n\nclass ProfileValidationService implements ProfileValidationRepository {")
with open("lib/features/profile/data/services/profile_validation_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';\nimport 'package:crushhour/features/profile/data/services/profile_validation_service.dart';\n"
if "profile_validation_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<ProfileValidationRepository>.value(\n          value: ProfileValidationService()),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update DeckScreen
with open("lib/features/discovery/presentation/screens/deck_screen.dart", "r") as f:
    deck = f.read()

deck = deck.replace("import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';", "import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';")
deck = deck.replace("final ProfileValidationService? validationService;", "final ProfileValidationRepository? validationService;")
deck = deck.replace("  ProfileValidationService get _validationService =>", "  ProfileValidationRepository get _validationService =>")
deck = deck.replace("      widget.validationService ?? ProfileValidationService();", "      widget.validationService ?? context.read<ProfileValidationRepository>();")

with open("lib/features/discovery/presentation/screens/deck_screen.dart", "w") as f:
    f.write(deck)

# 4. Update ChatScreen
with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    chat = f.read()

chat = chat.replace("import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';", "import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';")
chat = chat.replace("  final ProfileValidationService _validationService =\n      ProfileValidationService();", "  late final ProfileValidationRepository _validationService =\n      context.read<ProfileValidationRepository>();")

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.write(chat)

