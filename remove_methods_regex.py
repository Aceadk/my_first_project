import re

with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    text = f.read()

# Replace ListView.builder
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


prefixes = [
    r"  Map<String, int> _reactionCounts\(",
    r"  bool _isSameDay\(",
    r"  bool _shouldShowDateSeparator\(",
    r"  String _formatTime\(",
    r"  String _messageSemanticLabel\(",
    r"  String _moderationLabel\(",
    r"  Future<void> _launchUrl\(",
    r"  Widget _buildMediaErrorPlaceholder\(",
    r"  Widget _buildMessageContent\(",
    r"  void _toggleReaction\(",
    r"  void _showEditMessageDialog\(",
    r"  void _showMessageActions\(",
    r"  Widget _buildMessageSkeletonList\(",
    r"class _LoadMoreIndicator extends StatelessWidget"
]

for prefix in prefixes:
    # Match from prefix to the first ^  } (or ^} for the class)
    # The class _LoadMoreIndicator ends with ^}
    end_pattern = r"^  \}" if not prefix.startswith("class") else r"^\}"
    pattern = r"(?sm)^" + prefix + r".*?" + end_pattern + r"\n*"
    text = re.sub(pattern, "", text, count=1)

# Add the import
import_str = "import 'package:crushhour/features/chat/presentation/widgets/chat_message_list.dart';\n"
if import_str not in text:
    last_import = text.rfind("import '")
    if last_import != -1:
        end_import = text.find("\n", last_import)
        text = text[:end_import+1] + import_str + text[end_import+1:]

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.write(text)

