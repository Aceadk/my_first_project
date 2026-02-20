import os
import re

# 1. Add show method to MatchCelebration
match_celebration = "lib/design_system/widgets/match_celebration.dart"
if os.path.exists(match_celebration):
    with open(match_celebration, "r") as f:
        content = f.read()
    
    show_method = """
  /// Show the match celebration as a full-screen dialog.
  static Future<void> show({
    required BuildContext context,
    required String yourImageUrl,
    required String matchImageUrl,
    required String matchName,
    VoidCallback? onSendMessage,
    VoidCallback? onKeepSwiping,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return MatchCelebration(
          yourImageUrl: yourImageUrl,
          matchImageUrl: matchImageUrl,
          matchName: matchName,
          onSendMessage: () {
            Navigator.of(context).pop();
            onSendMessage?.call();
          },
          onKeepSwiping: () {
            Navigator.of(context).pop();
            onKeepSwiping?.call();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }
  """
    
    if "static Future<void> show" not in content:
        # insert right before @override State<MatchCelebration> createState
        idx = content.find("@override\n  State<MatchCelebration> createState()")
        # if not found, try without newline
        if idx == -1: idx = content.find("State<MatchCelebration> createState()")
        if idx != -1:
            content = content[:idx] + show_method + "\n  " + content[idx:]
            with open(match_celebration, "w") as f:
                f.write(content)

# 2. Update DeckScreen
deck_screen = "lib/features/discovery/presentation/screens/deck_screen.dart"
if os.path.exists(deck_screen):
    with open(deck_screen, "r") as f:
        content = f.read()
    
    # replace import
    content = content.replace("import '../widgets/match_celebration_modal.dart';", "import 'package:crushhour/design_system/widgets/match_celebration.dart';")
    
    # replace usage
    old_usage = """MatchCelebrationModal.show(
            context: context,
            matchedProfile: matchProfile,
            currentUserPhotoUrl: null,
            onSendMessage: () => _navigateToChat(context, matchProfile.id),
            onKeepSwiping: () {},
          );"""
    
    new_usage = """MatchCelebration.show(
            context: context,
            yourImageUrl: '',
            matchImageUrl: matchProfile.photoUrls.isNotEmpty ? matchProfile.photoUrls.first : '',
            matchName: matchProfile.publicDisplayName,
            onSendMessage: () => _navigateToChat(context, matchProfile.id),
            onKeepSwiping: () {},
          );"""
    content = content.replace(old_usage, new_usage)
    if "MatchCelebrationModal.show" in content:
        # Just in case regex or multiline match failed
        content = re.sub(r'MatchCelebrationModal\.show\([\s\S]*?onKeepSwiping: \(\) \{\},[\s]*\);', new_usage, content)

    with open(deck_screen, "w") as f:
        f.write(content)

# 3. Handle MessageRequestsScreen _MatchCelebrationDialog
# Delete inner classes _MatchCelebrationDialog and _MatchCelebrationDialogState, then replace the showDialog call.
message_screen = "lib/features/chat/presentation/screens/message_requests_screen.dart"
if os.path.exists(message_screen):
    with open(message_screen, "r") as f:
        content = f.read()

    # Remove the inner dialog
    content = re.sub(r'class _MatchCelebrationDialog(State)? extends StatefulWidget[\s\S]*?(?=^class |$)', '', content, flags=re.MULTILINE)
    content = re.sub(r'class _MatchCelebrationDialogState extends State<_MatchCelebrationDialog>[\s\S]*?(?=^class |$)', '', content, flags=re.MULTILINE)

    # Convert _showMatchCelebration to use MatchCelebration.show
    old_show = """void _showMatchCelebration(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => _MatchCelebrationDialog(userName: userName),
    );
  }"""
    new_show = """void _showMatchCelebration(BuildContext context, String userName) {
    MatchCelebration.show(
      context: context,
      yourImageUrl: '',
      matchImageUrl: '',
      matchName: userName,
      onSendMessage: () {},
      onKeepSwiping: () {},
    );
  }"""
    content = content.replace(old_show, new_show)
    if "import 'package:crushhour/design_system/widgets/match_celebration.dart';" not in content:
        content = "import 'package:crushhour/design_system/widgets/match_celebration.dart';\n" + content
    
    with open(message_screen, "w") as f:
        f.write(content)

# 4. Remove MatchCelebrationModal
match_modal = "lib/features/discovery/presentation/widgets/match_celebration_modal.dart"
if os.path.exists(match_modal):
    os.remove(match_modal)

