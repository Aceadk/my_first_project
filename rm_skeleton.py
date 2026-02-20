import os
import re

# 1. fix states_showcase.dart
states_showcase = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(states_showcase):
    with open(states_showcase, "r") as f:
        content = f.read()
    
    content = content.replace("DsEmptyState.noMatches(", "EmptyStateNoMatches(")
    content = content.replace("DsEmptyState.noMessages(onFindMatches: () {})", "EmptyStateNoMessages(otherName: 'Someone', onSendHi: () {})")
    content = content.replace("DsEmptyState.noMessages(\n  onFindMatches: () => navigateToDeck(),\n)", "EmptyStateNoMessages(otherName: 'Someone')")
    content = content.replace("DsEmptyState.connectionError(", "EmptyStateError(")
    content = content.replace("subtitle: ", "message: ")
    
    with open(states_showcase, "w") as f:
        f.write(content)

# 2. update design_system.dart
ds_file = "lib/design_system/design_system.dart"
if os.path.exists(ds_file):
    with open(ds_file, "r") as f:
        content = f.read()
    content = content.replace("export 'widgets/skeleton_loader.dart';\n", "")
    with open(ds_file, "w") as f:
        f.write(content)

# 3. update deck_skeleton.dart
deck_skeleton = "lib/features/discovery/presentation/widgets/deck_skeleton.dart"
if os.path.exists(deck_skeleton):
    with open(deck_skeleton, "r") as f:
        content = f.read()
    content = content.replace("import 'package:crushhour/design_system/widgets/skeleton_loader.dart';", "import 'package:crushhour/design_system/widgets/glass_skeleton.dart';")
    content = content.replace("DsShimmer(", "Container(")
    content = re.sub(r'SkeletonBox\(height:\s*(.*?)\)', r'GlassSkeleton(height: \1)', content)
    content = re.sub(r'SkeletonCircle\(size:\s*(.*?)\)', r'GlassSkeleton(width: \1, height: \1, isCircle: true)', content)
    with open(deck_skeleton, "w") as f:
        f.write(content)

# 4. update profile_insights_screen.dart
insights_screen = "lib/features/analytics/presentation/screens/profile_insights_screen.dart"
if os.path.exists(insights_screen):
    with open(insights_screen, "r") as f:
        content = f.read()
    content = re.sub(r'SkeletonBox\((.*?)\)', r'GlassSkeleton(\1)', content)
    with open(insights_screen, "w") as f:
        f.write(content)

# 5. create GlassSkeletonGrid and replace in likes_you_screen.dart
likes_you_screen = "lib/features/discovery/presentation/screens/likes_you_screen.dart"
if os.path.exists(likes_you_screen):
    with open(likes_you_screen, "r") as f:
        content = f.read()
    
    grid_replacement = """GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const GlassSkeleton(borderRadius: DsRadius.md),
      )"""
    content = re.sub(r'const SkeletonGrid\([\s\S]*?\)', grid_replacement, content)
    with open(likes_you_screen, "w") as f:
        f.write(content)

# 6. MatchesScreen
matches_screen = "lib/features/chat/presentation/screens/matches_screen.dart"
if os.path.exists(matches_screen):
    with open(matches_screen, "r") as f:
        content = f.read()
    content = content.replace("SkeletonMatchCard", "GlassSkeletonChatTile")
    content = content.replace("SkeletonList.matches()", "GlassSkeletonChatList()")
    content = re.sub(r'SkeletonBox\((.*?)\)', r'GlassSkeleton(\1)', content)
    with open(matches_screen, "w") as f:
        f.write(content)

# 7. ChatListScreen
chat_list_screen = "lib/features/chat/presentation/screens/chat_list_screen.dart"
if os.path.exists(chat_list_screen):
    with open(chat_list_screen, "r") as f:
        content = f.read()
    content = content.replace("SkeletonList.chat(itemCount", "GlassSkeletonChatList(itemCount")
    content = content.replace("SkeletonList.chat()", "GlassSkeletonChatList()")
    with open(chat_list_screen, "w") as f:
        f.write(content)

# 8. WeeklyPicksScreen
picks_screen = "lib/features/discovery/presentation/screens/weekly_picks_screen.dart"
if os.path.exists(picks_screen):
    with open(picks_screen, "r") as f:
        content = f.read()
    content = content.replace("SkeletonProfileCard()", "GlassSkeletonCard()")
    with open(picks_screen, "w") as f:
        f.write(content)

# 9. Delete skeleton_loader.dart
skeleton_file = "lib/design_system/widgets/skeleton_loader.dart"
if os.path.exists(skeleton_file):
    os.remove(skeleton_file)
