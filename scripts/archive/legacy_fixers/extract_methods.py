import sys

path = 'lib/features/chat/presentation/screens/chat_screen.dart'
with open(path) as f:
    lines = f.readlines()

prefixes = [
    "  Map<String, int> _reactionCounts(",
    "  bool _shouldShowDateSeparator(",
    "  String _formatTime(",
    "  String _messageSemanticLabel(",
    "  Widget _buildMessageContent(",
    "  void _showMessageActions(",
    "class _LoadMoreIndicator extends StatelessWidget {",
    "  String _moderationLabel(",
    "  bool _isSameDay(",
    "  Future<void> _launchUrl(",
    "  Widget _buildMediaErrorPlaceholder(",
    "  void _toggleReaction(",
    "  void _showEditMessageDialog("
]

with open('methods_dump.dart', 'w') as f:
    for prefix in prefixes:
        idx = next((i for i,l in enumerate(lines) if l.startswith(prefix)), None)
        if idx is not None:
            bracket_count = 0
            for i in range(idx, len(lines)):
                f.write(lines[i])
                bracket_count += lines[i].count('{') - lines[i].count('}')
                if i >= idx and bracket_count == 0 and '{' in lines[idx:i+1]:
                    # Wait, if '{' is not on the first line, we need to make sure we've seen it.
                    # but actually dart format puts '{' on the signature line or next line.
                    break
                # improved bracket counting to handle opening brace on next lines
                has_seen_brace = False
                for j in range(idx, i+1):
                    if '{' in lines[j]:
                        has_seen_brace = True
                if has_seen_brace and bracket_count == 0:
                    break
            f.write('\n\n')

