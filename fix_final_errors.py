import os
import re

# 1. di.dart
di_file = "lib/core/di.dart"
if os.path.exists(di_file):
    with open(di_file, "r") as f:
        content = f.read()
    content = content.replace("CallRepository", "CallManagerRepository")
    with open(di_file, "w") as f:
        f.write(content)

# 2. states_showcase.dart
states_showcase = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(states_showcase):
    with open(states_showcase, "r") as f:
        content = f.read()
    content = content.replace("DsEmptyState.noMatches(", "EmptyStateNoMatches(")
    content = content.replace("DsEmptyState.noMessages(", "EmptyStateNoMessages(")
    content = content.replace("DsEmptyState.connectionError(", "EmptyStateError(")
    content = content.replace("DsEmptyState(", "DsEmptyState(message: 'You can customize icon, title, subtitle, and actions.', ", 1)
    
    # replace onKeepSwiping, onFindMatches
    content = content.replace("onKeepSwiping: () => navigateToDeck(),", "onRefresh: () {},")
    content = content.replace("onKeepSwiping: () {}", "onRefresh: () {}")
    content = content.replace("onFindMatches: () => navigateToDeck(),", "otherName: 'Someone', onSendHi: () {},")
    content = content.replace("onFindMatches: () {}", "otherName: 'Someone', onSendHi: () {}")
    # clean up any subtitle usages
    content = content.replace("subtitle: 'Empty state displays for various scenarios'", "/* subtitle */")
    content = content.replace("subtitle: 'Overlay loading indicator on content'", "/* subtitle */")
    content = content.replace("subtitle: 'Dismissible error message banner'", "/* subtitle */")
    content = content.replace("subtitle: 'Standard Flutter loading indicators'", "/* subtitle */")
    content = content.replace("subtitle: ", "message: ")
    with open(states_showcase, "w") as f:
        f.write(content)

# 3. profile_insights_screen.dart
insights_screen = "lib/features/analytics/presentation/screens/profile_insights_screen.dart"
if os.path.exists(insights_screen):
    with open(insights_screen, "r") as f:
        content = f.read()
    content = content.replace("DsShimmer(", "Container(")
    with open(insights_screen, "w") as f:
        f.write(content)

# 4. profile_validation_repository.dart
val_repo = "lib/features/profile/domain/repositories/profile_validation_repository.dart"
if os.path.exists(val_repo):
    with open(val_repo, "r") as f:
        content = f.read()
    if "RemoteProfileCompleteness" not in content and "import" in content:
        content = "import 'package:crushhour/features/profile/data/services/profile_validation_service.dart' show RemoteProfileCompleteness;\n" + content
    else:
        # Just add export
        content = "export 'package:crushhour/features/profile/data/services/profile_validation_service.dart' show RemoteProfileCompleteness;\n" + content
    with open(val_repo, "w") as f:
        f.write(content)

# 5. matches_screen.dart
matches_screen = "lib/features/chat/presentation/screens/matches_screen.dart"
if os.path.exists(matches_screen):
    with open(matches_screen, "r") as f:
        content = f.read()
    content = content.replace("DsShimmer(", "Container(")
    content = content.replace("SkeletonBox(", "GlassSkeleton(")
    with open(matches_screen, "w") as f:
        f.write(content)

# 6. message_requests_screen.dart
msg_req = "lib/features/chat/presentation/screens/message_requests_screen.dart"
if os.path.exists(msg_req):
    with open(msg_req, "r") as f:
        content = f.read()
    content = content.replace("import 'package:crushhour/design_system/widgets/match_celebration.dart';", "")
    content = content.replace("_MatchCelebrationDialog", "MatchCelebration.show")
    with open(msg_req, "w") as f:
        f.write(content)

# 7. chat_widgets.dart
chat_widgets = "lib/features/chat/presentation/widgets/chat_widgets.dart"
if os.path.exists(chat_widgets):
    with open(chat_widgets, "r") as f:
        lines = f.readlines()
    with open(chat_widgets, "w") as f:
        for line in lines:
            if "chat_typing_indicator.dart" not in line:
                f.write(line)

# 8. voice_note_recorder.dart
vn_rec = "lib/features/chat/presentation/widgets/voice_note_recorder.dart"
if os.path.exists(vn_rec):
    with open(vn_rec, "r") as f:
        content = f.read()
    content = content.replace("import 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';", "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';")
    with open(vn_rec, "w") as f:
        f.write(content)

# 9. incognito_repository.dart
incog_repo = "lib/features/discovery/domain/repositories/incognito_repository.dart"
if os.path.exists(incog_repo):
    with open(incog_repo, "r") as f:
        content = f.read()
    content = content.replace("features/discovery/models/incognito_settings.dart", "features/discovery/domain/models/incognito_settings.dart")
    with open(incog_repo, "w") as f:
        f.write(content)

# 10. deck_screen.dart (and replace modal)
deck_screen = "lib/features/discovery/presentation/screens/deck_screen.dart"
if os.path.exists(deck_screen):
    with open(deck_screen, "r") as f:
        content = f.read()
    content = content.replace("import 'package:crushhour/features/discovery/presentation/widgets/match_celebration_modal.dart';", "import 'package:crushhour/design_system/widgets/match_celebration.dart';")
    content = content.replace("MatchCelebrationModal(match:", "MatchCelebration.show(context,")
    content = content.replace("MatchCelebrationModal", "MatchCelebration")
    with open(deck_screen, "w") as f:
        f.write(content)

# 11. likes_you_screen.dart
likes_you = "lib/features/discovery/presentation/screens/likes_you_screen.dart"
if os.path.exists(likes_you):
    with open(likes_you, "r") as f:
        content = f.read()
    content = content.replace("import 'package:crushhour/design_system/widgets/skeleton_loader.dart';", "import 'package:crushhour/design_system/widgets/glass_skeleton.dart';\nimport 'package:crushhour/design_system/tokens/radius.dart';")
    with open(likes_you, "w") as f:
        f.write(content)

# 12. weekly_picks_screen.dart
picks_screen = "lib/features/discovery/presentation/screens/weekly_picks_screen.dart"
if os.path.exists(picks_screen):
    with open(picks_screen, "r") as f:
        content = f.read()
    content = content.replace("DsShimmer(", "Container(")
    with open(picks_screen, "w") as f:
        f.write(content)

# 13. deck_skeleton.dart
deck_skel = "lib/features/discovery/presentation/widgets/deck_skeleton.dart"
if os.path.exists(deck_skel):
    with open(deck_skel, "r") as f:
        content = f.read()
    content = content.replace("const Container(", "Container(")
    with open(deck_skel, "w") as f:
        f.write(content)

# 14/15. imports profile
for path in ["lib/features/profile/data/services/profile_media_service.dart", "lib/features/profile/data/services/profile_validation_service.dart"]:
    if os.path.exists(path):
        with open(path, "r") as f:
            lines = f.readlines()
        imports = [l for l in lines if l.startswith("import ")]
        others = [l for l in lines if not l.startswith("import ")]
        with open(path, "w") as f:
            f.writelines(imports)
            f.writelines(others)

