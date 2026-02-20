import sys

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
    "class _LoadMoreIndicator extends StatelessWidget {"
]

with open('lib/features/chat/presentation/screens/chat_screen.dart') as f:
    lines = f.readlines()

methods_str = ""
for prefix in prefixes:
    idx = next((i for i,l in enumerate(lines) if l.startswith(prefix)), None)
    if idx is not None:
        bracket_count = 0
        has_seen_brace = False
        for i in range(idx, len(lines)):
            methods_str += lines[i]
            bracket_count += lines[i].count('{') - lines[i].count('}')
            for j in range(idx, i+1):
                if '{' in lines[j]:
                    has_seen_brace = True
            if has_seen_brace and bracket_count == 0:
                break
        methods_str += '\n\n'

classes_body = ""
if "class _LoadMoreIndicator" in methods_str:
    parts = methods_str.split("class _LoadMoreIndicator")
    methods_str = parts[0]
    classes_body = "class _LoadMoreIndicator" + parts[1]

# Now we construct the file
with open('chat_list_dump.dart', 'r') as f:
    list_lines = f.readlines()
    
list_body_lines = list_lines[2:549]
list_body_lines[0] = list_body_lines[0].replace(r"                          : ", "return ")
list_body_lines[-1] = list_body_lines[-1].rstrip()
if list_body_lines[-1].endswith(","):
    list_body_lines[-1] = list_body_lines[-1][:-1] + ";"
else:
    list_body_lines[-1] = list_body_lines[-1] + ";"
list_body = "".join(list_body_lines)

# Apply fixes
list_body = list_body.replace("widget.args.", "")
list_body = list_body.replace("controller: _scrollController", "controller: scrollController")
list_body = list_body.replace("onRefresh: _refreshIceBreakers", "onRefresh: onRefreshIceBreakers")
list_body = list_body.replace("suggestions: _iceBreakerSuggestions", "suggestions: iceBreakerSuggestions")
list_body = list_body.replace("onSuggestionTap: _onIceBreakerTap", "onSuggestionTap: onIceBreakerTap")

methods_str = methods_str.replace("widget.args.", "")
methods_str = methods_str.replace("if (!mounted) return;", "if (!context.mounted) return;")

# Remove leading underscores for local identifiers
func_names = [
    "_reactionCounts", "_isSameDay", "_shouldShowDateSeparator", "_formatTime",
    "_messageSemanticLabel", "_moderationLabel", "_launchUrl",
    "_buildMediaErrorPlaceholder", "_buildMessageContent", "_toggleReaction",
    "_showEditMessageDialog", "_showMessageActions"
]
for fname in func_names:
    list_body = list_body.replace(fname + "(", fname[1:] + "(")
    methods_str = methods_str.replace(fname + "(", fname[1:] + "(")

dart_code = f"""import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/design_system/theme/app_theme.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/glass_skeleton.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:crushhour/presentation/widgets/plus_feature_gate.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/core/security/clipboard_manager.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/chat/domain/services/ice_breaker_service.dart';

class ChatMessageList extends StatelessWidget {{
  final ChatState state;
  final ScrollController scrollController;
  final String currentUserId;
  final String otherName;
  final String matchId;
  final VoidCallback onRefreshIceBreakers;
  final Function(String) onIceBreakerTap;
  final List<IceBreakerSuggestion> iceBreakerSuggestions;

  const ChatMessageList({{
    super.key,
    required this.state,
    required this.scrollController,
    required this.currentUserId,
    required this.otherName,
    required this.matchId,
    required this.onRefreshIceBreakers,
    required this.onIceBreakerTap,
    required this.iceBreakerSuggestions,
  }});

  @override
  Widget build(BuildContext context) {{
{methods_str}

    final messages = state.allMessages;
    
    {list_body}
  }}
}}

{classes_body}
"""
with open('lib/features/chat/presentation/widgets/chat_message_list.dart', 'w') as f:
    f.write(dart_code)

