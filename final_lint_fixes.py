import os

# 1. di.dart
di_file = "lib/core/di.dart"
if os.path.exists(di_file):
    with open(di_file, "r") as f:
        content = f.read()
    content = content.replace("CallManagerRepository", "CallRepository")
    with open(di_file, "w") as f:
        f.write(content)

# 2. states_showcase.dart
states = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(states):
    with open(states, "r") as f:
        content = f.read()
    # EmptyStateError does have message, wait, let's remove message from all EmptyStates in showcase just in case if it's undefined
    content = content.replace("message: 'You can customize icon, title, subtitle, and actions.',", "")
    content = content.replace("message: 'Check your connection and try again.',", "")
    content = content.replace("message: 'Change filters to see more people.',", "")
    content = content.replace("message: 'We could not load your data.\\nPlease try again.',", "")
    with open(states, "w") as f:
        f.write(content)

# 3. chat_screen.dart typing indicator
chat_screen = "lib/features/chat/presentation/screens/chat_screen.dart"
if os.path.exists(chat_screen):
    with open(chat_screen, "r") as f:
        content = f.read()
    content = content.replace("const TypingIndicator(\n                      isTyping: true,\n                      userName: widget.args.otherName,\n                      showAvatar: false,\n                    ),", "const TypingIndicator(),")
    with open(chat_screen, "w") as f:
        f.write(content)

# 4. matches_screen.dart Unnecessary Container / const
matches_screen = "lib/features/chat/presentation/screens/matches_screen.dart"
if os.path.exists(matches_screen):
    with open(matches_screen, "r") as f:
        content = f.read()
    content = content.replace("return const Container(\n              child: Center(", "return Center(")
    content = content.replace("return Container(\n              child: Center(", "return Center(")
    with open(matches_screen, "w") as f:
        f.write(content)

# 5. message_requests_screen.dart MatchCelebration modal
msg_req = "lib/features/chat/presentation/screens/message_requests_screen.dart"
if os.path.exists(msg_req):
    with open(msg_req, "r") as f:
        content = f.read()
    # Replace the showDialog block
    old_block = """    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MatchCelebration.show(userName: userName),
    ).then((_) {"""
    new_block = """    MatchCelebration.show(
      context: context,
      yourImageUrl: '',
      matchImageUrl: '',
      matchName: userName,
    ).then((_) {"""
    content = content.replace(old_block, new_block)
    with open(msg_req, "w") as f:
        f.write(content)

# 6. deck_screen.dart MatchCelebration modal params
deck_screen = "lib/features/discovery/presentation/screens/deck_screen.dart"
if os.path.exists(deck_screen):
    with open(deck_screen, "r") as f:
        content = f.read()
    content = content.replace("matchedProfile: newMatch.matchedProfile,", "matchName: newMatch.matchedProfile.name, matchImageUrl: newMatch.matchedProfile.photoUrls.isNotEmpty ? newMatch.matchedProfile.photoUrls.first : '',")
    content = content.replace("currentUserPhotoUrl: currentUserPhotoUrl,", "yourImageUrl: currentUserPhotoUrl ?? '',")
    with open(deck_screen, "w") as f:
        f.write(content)

