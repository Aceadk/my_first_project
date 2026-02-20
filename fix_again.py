import os

# 1. di.dart
di_file = "lib/core/di.dart"
if os.path.exists(di_file):
    with open(di_file, "r") as f:
        content = f.read()
    content = content.replace("CallRepository", "CallManagerRepository")
    with open(di_file, "w") as f:
        f.write(content)

# 2. states_showcase.dart - brute force finding "message:"
states = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(states):
    with open(states, "r") as f:
        lines = f.readlines()
    with open(states, "w") as f:
        for line in lines:
            if "message: '" in line or "message: " in line:
                continue
            f.write(line)

# 3. chat_screen.dart typing indicator syntax
chat_screen = "lib/features/chat/presentation/screens/chat_screen.dart"
if os.path.exists(chat_screen):
    with open(chat_screen, "r") as f:
        content = f.read()
    
    # Add import
    if "import 'package:crushhour/design_system/widgets/typing_indicator.dart';" not in content:
        content = "import 'package:crushhour/design_system/widgets/typing_indicator.dart';\n" + content
    
    # Fix the weird syntax error from previous malformed replace
    bad_syntax = """                    const TypingIndicator()
                      isTyping: true,
                      userName: widget.args.otherName,
                      showAvatar: false,
                    ),"""
    content = content.replace(bad_syntax, "                    const TypingIndicator(),")
    
    with open(chat_screen, "w") as f:
        f.write(content)

# 4. matches_screen.dart
match_screen = "lib/features/chat/presentation/screens/matches_screen.dart"
if os.path.exists(match_screen):
    with open(match_screen, "r") as f:
        content = f.read()
    content = content.replace("return const Center(", "return Center(")
    with open(match_screen, "w") as f:
        f.write(content)

