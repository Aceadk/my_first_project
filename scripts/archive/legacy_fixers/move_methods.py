import sys

with open("lib/features/chat/presentation/widgets/chat_message_list.dart", "r") as f:
    text = f.read()

# Find the start of _moderationLabel
idx = text.find("String _moderationLabel(")
if (idx == -1):
    print("Could not find _moderationLabel")
    sys.exit(1)

# Extract everything from _moderationLabel to the end
methods_to_move = text[idx:]

# Remove it from the end
text = text[:idx]

# Find the end of _showMessageActions inside build
idx2 = text.find("class _LoadMoreIndicator")
if (idx2 == -1):
    print("Could not find _LoadMoreIndicator")
    sys.exit(1)
    
# Wait, _showMessageActions is inside build.
# We can just put methods_to_move right before `final messages = state.allMessages;`
idx_messages = text.find("final messages = state.allMessages;")
if (idx_messages == -1):
    print("Could not find messages")
    sys.exit(1)

# Insert methods_to_move before idx_messages
text = text[:idx_messages] + methods_to_move + "\n\n" + text[idx_messages:]

with open("lib/features/chat/presentation/widgets/chat_message_list.dart", "w") as f:
    f.write(text)
