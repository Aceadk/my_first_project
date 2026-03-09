with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    lines = f.readlines()

ranges_to_delete = [
    (994, 1156),   # _showMessageActions
    (1168, 1221),  # _showEditMessageDialog
    (1231, 1252),  # _toggleReaction
    (1289, 1301),  # _buildMessageSkeletonList
    (1305, 1395),  # _buildMessageContent
    (1397, 1403),  # _reactionCounts
    (1405, 1411),  # _shouldShowDateSeparator
    (1413, 1416),  # _isSameDay
    (1418, 1449),  # _buildMediaErrorPlaceholder
    (1451, 1457),  # _formatTime
    (1459, 1470),  # _moderationLabel
    (1610, 1618),  # _launchUrl
    (2341, 2378),  # _LoadMoreIndicator + docstring
]

for start, end in ranges_to_delete:
    for i in range(start - 1, end):
        lines[i] = ""

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.writelines(lines)
