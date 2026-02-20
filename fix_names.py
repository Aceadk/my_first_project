with open("lib/features/chat/presentation/widgets/chat_message_list.dart", "r") as f:
    text = f.read()

# Fix launchUrl shadowing
text = text.replace("Future<void> launchUrl(String url)", "Future<void> openUrl(String url)")
text = text.replace("launchUrl(uri, mode: LaunchMode.externalApplication);", "LAUNCH_URL_MARKER")
text = text.replace("launchUrl(", "openUrl(")
text = text.replace("LAUNCH_URL_MARKER", "launchUrl(uri, mode: LaunchMode.externalApplication);")

# Fix reactionCounts shadowing
text = text.replace("Map<String, int> reactionCounts(", "Map<String, int> getReactionCounts(")
text = text.replace("final reactionCounts = reactionCounts(msg);", "final reactionCounts = getReactionCounts(msg);")

# Fix widget.args.
text = text.replace("widget.args.", "")

with open("lib/features/chat/presentation/widgets/chat_message_list.dart", "w") as f:
    f.write(text)
