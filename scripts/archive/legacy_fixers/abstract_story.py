import re

# 1. Update StoryService
with open("lib/features/discovery/data/services/story_service.dart", "r") as f:
    text = f.read()

text = text.replace("class StoryService {", "import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';\n\nclass StoryService implements StoryRepository {")
# Remove ProfileStoryExtension
text = re.sub(r'/// Extension for easy story access on profile\..*?}\n', '', text, flags=re.DOTALL)

with open("lib/features/discovery/data/services/story_service.dart", "w") as f:
    f.write(text)

# 2. Update di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';\nimport 'package:crushhour/features/discovery/data/services/story_service.dart';\n"
if "story_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<StoryRepository>.value(\n          value: StoryService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update SwipeCard
with open("lib/features/discovery/presentation/widgets/swipe_card.dart", "r") as f:
    swipe_card = f.read()

swipe_card = swipe_card.replace("import 'package:crushhour/features/discovery/data/services/story_service.dart';", "import 'package:crushhour/features/discovery/domain/repositories/story_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';")
swipe_card = swipe_card.replace("final stories = profile.id.activeStories;", "final stories = context.read<StoryRepository>().getStoriesForUser(profile.id);")

with open("lib/features/discovery/presentation/widgets/swipe_card.dart", "w") as f:
    f.write(swipe_card)

# 4. Update StoryViewerScreen
with open("lib/features/discovery/presentation/screens/story_viewer_screen.dart", "r") as f:
    story_viewer = f.read()

story_viewer = story_viewer.replace("import '../data/services/story_service.dart';", "import '../domain/repositories/story_repository.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';")
story_viewer = story_viewer.replace("StoryService.instance", "context.read<StoryRepository>()")

with open("lib/features/discovery/presentation/screens/story_viewer_screen.dart", "w") as f:
    f.write(story_viewer)

