import os

def build_widget():
    # We want lines 3 to 549 from chat_list_dump.dart
    with open('chat_list_dump.dart', 'r') as f:
        lines = f.readlines()
        
    list_body_lines = lines[2:549] # index 2 is : messages.isEmpty
    list_body_lines[0] = list_body_lines[0].replace(r"                          : ", "return ")
    # ensure it ends cleanly
    list_body_lines[-1] = list_body_lines[-1].rstrip()
    if list_body_lines[-1].endswith(","):
        list_body_lines[-1] = list_body_lines[-1][:-1] + ";"
    else:
        list_body_lines[-1] = list_body_lines[-1] + ";"
    list_body = "".join(list_body_lines)
        
    with open('methods_dump.dart', 'r') as f:
        methods_body = f.read()

    classes_body = ""
    # Split out nested classes
    if "class _LoadMoreIndicator" in methods_body:
        parts = methods_body.split("class _LoadMoreIndicator")
        methods_body = parts[0]
        classes_body = "class _LoadMoreIndicator" + parts[1]

    # Apply all references fixes
    list_body = list_body.replace("widget.args.", "")
    methods_body = methods_body.replace("widget.args.", "")
    
    list_body = list_body.replace("controller: _scrollController", "controller: scrollController")
    list_body = list_body.replace("onRefresh: _refreshIceBreakers", "onRefresh: onRefreshIceBreakers")
    list_body = list_body.replace("suggestions: _iceBreakerSuggestions", "suggestions: iceBreakerSuggestions")
    list_body = list_body.replace("onSuggestionTap: _onIceBreakerTap", "onSuggestionTap: onIceBreakerTap")

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
import 'package:crushhour/features/chat/domain/models/message.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_widgets.dart';
import 'package:crushhour/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:crushhour/features/premium/presentation/widgets/plus_feature_gate.dart';
import 'package:crushhour/shared/utils/date_formatter.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:crushhour/shared/utils/secure_clipboard.dart';

class ChatMessageList extends StatelessWidget {{
  final ChatState state;
  final ScrollController scrollController;
  final String currentUserId;
  final String otherName;
  final String matchId;
  final VoidCallback onRefreshIceBreakers;
  final Function(String) onIceBreakerTap;
  final List<String> iceBreakerSuggestions;

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
{methods_body}

    final messages = state.allMessages;
    
    {list_body}
  }}
}}

{classes_body}
"""
    with open('lib/features/chat/presentation/widgets/chat_message_list.dart', 'w') as f:
        f.write(dart_code)
        
build_widget()
