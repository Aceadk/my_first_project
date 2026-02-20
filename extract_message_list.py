import os
import re

def extract():
    src = '/Users/ace/my_first_project/lib/features/chat/presentation/screens/chat_screen.dart'
    dst = '/Users/ace/my_first_project/lib/features/chat/presentation/widgets/chat_message_list.dart'
    
    with open(src, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = [
        "import 'dart:ui';\n",
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/services.dart';\n",
        "import 'package:intl/intl.dart';\n",
        "import 'package:flutter_bloc/flutter_bloc.dart';\n",
        "\n",
        "import 'package:crushhour/core/app_logger.dart';\n",
        "import 'package:crushhour/core/haptic_service.dart';\n",
        "import 'package:crushhour/design_system/theme/app_theme.dart';\n",
        "import 'package:crushhour/design_system/theme/theme_extensions.dart';\n",
        "import 'package:crushhour/design_system/tokens/blur.dart';\n",
        "import 'package:crushhour/design_system/tokens/colors.dart';\n",
        "import 'package:crushhour/design_system/tokens/radius.dart';\n",
        "import 'package:crushhour/design_system/tokens/sizes.dart';\n",
        "import 'package:crushhour/design_system/tokens/spacing.dart';\n",
        "import 'package:crushhour/design_system/tokens/spacing_widgets.dart';\n",
        "import 'package:crushhour/design_system/widgets/glass_skeleton.dart';\n",
        "import 'package:crushhour/features/chat/domain/models/message.dart';\n",
        "import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';\n",
        "import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';\n",
        "import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';\n",
        "import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';\n",
        "import 'package:crushhour/features/chat/presentation/widgets/chat_message_bubble.dart';\n",
        "import 'package:crushhour/shared/utils/date_formatter.dart';\n",
        "import 'package:crushhour/shared/widgets/cached_image.dart';\n",
        "\n",
        "class ChatMessageList extends StatelessWidget {\n",
        "  final ChatState state;\n",
        "  final ScrollController scrollController;\n",
        "  final String currentUserId;\n",
        "  final String otherName;\n",
        "  final VoidCallback onRefreshIceBreakers;\n",
        "  final Function(String) onIceBreakerTap;\n",
        "  final List<String> iceBreakerSuggestions;\n",
        "\n",
        "  const ChatMessageList({\n",
        "    super.key,\n",
        "    required this.state,\n",
        "    required this.scrollController,\n",
        "    required this.currentUserId,\n",
        "    required this.otherName,\n",
        "    required this.onRefreshIceBreakers,\n",
        "    required this.onIceBreakerTap,\n",
        "    required this.iceBreakerSuggestions,\n",
        "  });\n",
        "\n",
        "  @override\n",
        "  Widget build(BuildContext context) {\n",
        "    final messages = state.allMessages;\n",
        "    if (messages.isEmpty) {\n",
        "      return ChatEmptyState(\n",
        "        onRefresh: onRefreshIceBreakers,\n",
        "        suggestions: iceBreakerSuggestions,\n",
        "        onSuggestionTap: onIceBreakerTap,\n",
        "        otherName: otherName,\n",
        "      );\n",
        "    }\n",
        "    final isDark = Theme.of(context).brightness == Brightness.dark;\n",
        "    final baseSurface = DsGlassColors.surfaceFor(context);\n",
        "    final borderBase = DsGlassColors.borderFor(context);\n",
    ]

    listview_lines = []
    in_listview = False
    bracket_count = 0
    
    methods = {
        "_reactionCounts": [],
        "_shouldShowDateSeparator": [],
        "_formatTime": [],
        "_messageSemanticLabel": [],
        "_buildMessageContent": [],
        "_showMessageActions": [],
        "_buildMessageSkeletonList": [],
    }
    
    current_method = None
    method_bracket_count = 0
    
    load_more_indicator = []
    in_load_more = False

    for line in lines:
        if in_listview:
            listview_lines.append(line)
            bracket_count += line.count("(") - line.count(")")
            if bracket_count == 0:
                in_listview = False
        elif "ListView.builder(" in line and "controller: _scrollController," in "".join(lines):
            # This relies on the fact that ListView.builder happens in the `body` 
            listview_lines.append("    return ListView.builder(\n")
            bracket_count += line.count("(") - line.count(")")
            in_listview = True

        if in_load_more:
            load_more_indicator.append(line)
            method_bracket_count += line.count("{") - line.count("}")
            if method_bracket_count == 0:
                in_load_more = False
        elif line.startswith("class _LoadMoreIndicator"):
            load_more_indicator.append(line)
            method_bracket_count += line.count("{") - line.count("}")
            in_load_more = True
            
        if current_method is not None:
            methods[current_method].append(line)
            method_bracket_count += line.count("{") - line.count("}")
            # wait, if the ({}) was not on same line, bracket count initially could be 0 but it's not closed.
            if method_bracket_count == 0 and "}" in line:
                current_method = None
        else:
            for m in methods.keys():
                if line.startswith(f"  Map<String, int> {m}(") or line.startswith(f"  bool {m}(") or line.startswith(f"  String {m}(") or line.startswith(f"  Widget {m}(") or line.startswith(f"  void {m}("):
                    current_method = m
                    methods[m].append(line.replace(f"  ", f"  ", 1)) # keep indentation
                    method_bracket_count += line.count("{") - line.count("}")
                    break

    # Fix widget.args.currentUserId -> currentUserId
    # Fix widget.args.otherUserId -> state.otherUserId? Not in message list? In list view `msg.fromUserId == widget.args.currentUserId;`
    # Fix _scrollController -> scrollController
    # Fix setState => we can't do setState here if it's stateless. Where is setState used? Not in list view.
    listview_str = "".join(listview_lines)
    listview_str = listview_str.replace("widget.args.currentUserId", "currentUserId")
    listview_str = listview_str.replace("widget.args.matchId", "state.matchId") # assuming state has it, if not will fix later
    listview_str = listview_str.replace("_scrollController", "scrollController")
    listview_str = listview_str.replace("widget.args.otherName", "otherName")
    
    out_lines.append(listview_str)
    out_lines.append("  }\n\n")

    # Add methods inside class
    for m in methods.keys():
        m_str = "".join(methods[m])
        m_str = m_str.replace("widget.args.currentUserId", "currentUserId")
        m_str = m_str.replace("widget.args.matchId", "state.matchId")
        m_str = m_str.replace("widget.args.otherName", "otherName")
        out_lines.append(m_str)
        out_lines.append("\n")

    out_lines.append("}\n\n")
    
    out_lines.extend(load_more_indicator)

    with open(dst, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)

    print("Extracted chat_message_list.dart")

if __name__ == '__main__':
    extract()
