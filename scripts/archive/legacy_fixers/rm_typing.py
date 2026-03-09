import os

chat_screen = "lib/features/chat/presentation/screens/chat_screen.dart"
if os.path.exists(chat_screen):
    with open(chat_screen, "r") as f:
        content = f.read()
    
    # Replace the widget call
    content = content.replace("ChatTypingIndicator(name: widget.args.otherName)", "AnimatedTypingIndicator(isTyping: true, userName: widget.args.otherName, showAvatar: false)")
    
    # Replace import
    content = content.replace("import '../widgets/chat_typing_indicator.dart';", "import 'package:crushhour/design_system/widgets/typing_indicator.dart';")
    
    with open(chat_screen, "w") as f:
        f.write(content)

typing_indicator = "lib/features/chat/presentation/widgets/chat_typing_indicator.dart"
if os.path.exists(typing_indicator):
    os.remove(typing_indicator)

