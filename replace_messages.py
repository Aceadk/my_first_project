import re

with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    text = f.read()

idx_start = text.find("                          : messages.isEmpty")
idx_end = text.find("                  if (state.isUnsendInProgress)")
if idx_start != -1 and idx_end != -1:
    replacement = """                          : ChatMessageList(
                              state: state,
                              scrollController: _scrollController,
                              currentUserId: widget.args.currentUserId,
                              otherName: widget.args.otherName,
                              matchId: widget.args.otherUserId,
                              onRefreshIceBreakers: _refreshIceBreakers,
                              onIceBreakerTap: _onIceBreakerTap,
                              iceBreakerSuggestions: _iceBreakerSuggestions,
                            ),
                    ),
                  ),
"""
    text = text[:idx_start] + replacement + text[idx_end:]
else:
    print("Could not find start or end bounds for replacement!")

prefixes = [
    "  Map<String, int> _reactionCounts(",
    "  bool _isSameDay(",
    "  bool _shouldShowDateSeparator(",
    "  String _formatTime(",
    "  String _messageSemanticLabel(",
    "  String _moderationLabel(",
    "  Future<void> _launchUrl(",
    "  Widget _buildMediaErrorPlaceholder(",
    "  Widget _buildMessageContent(",
    "  void _toggleReaction(",
    "  void _showEditMessageDialog(",
    "  void _showMessageActions(",
    "class _LoadMoreIndicator extends StatelessWidget"
]

for prefix in prefixes:
    idx = text.find(prefix)
    if idx != -1:
        bracket_count = 0
        has_seen_brace = False
        idx_end = idx
        for i in range(idx, len(text)):
            if text[i] == '{':
                bracket_count += 1
                has_seen_brace = True
            elif text[i] == '}':
                bracket_count -= 1
            if has_seen_brace and bracket_count == 0:
                idx_end = i + 1
                break
        
        while idx_end < len(text) and text[idx_end] in ['\n', ' ', '\r']:
            idx_end += 1
        text = text[:idx] + text[idx_end:]

# Add the import
import_str = "import 'package:crushhour/features/chat/presentation/widgets/chat_message_list.dart';\n"
if import_str not in text:
    last_import = text.rfind("import '")
    if last_import != -1:
        end_import = text.find("\n", last_import)
        text = text[:end_import+1] + import_str + text[end_import+1:]

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.write(text)

