import re

with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    lines = f.readlines()

out_lines = []
skip = False
for i, line in enumerate(lines):
    if "safetyCubit: safety," in line:
        continue
    
    if "_controller.text = text;" in line:
        out_lines.append("    context.read<ChatBloc>().add(ChatMessageSent(matchId: widget.args.matchId, content: text, type: MessageType.text));\n")
        continue

    if "? _buildMessageSkeletonList()" in line:
        out_lines.append(line.replace("? _buildMessageSkeletonList()", "? const Center(child: CircularProgressIndicator())"))
        continue

    if ": messages.isEmpty" in line and "ChatEmptyState" in lines[i+1]:
        skip = True
        replacement = """                        : ChatMessageList(
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
"""
        out_lines.append(replacement)
        continue
        
    if skip and "if (state.isUnsendInProgress)" in line:
        skip = False
        
    if not skip:
        out_lines.append(line)

text = "".join(out_lines)

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.write(text)

