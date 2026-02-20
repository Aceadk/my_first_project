import os
import re

def refactor():
    path = '/Users/ace/my_first_project/lib/features/chat/presentation/screens/chat_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    i = 0
    import_added = False
    
    methods_to_delete = [
        "  KeyEventResult _handleKeyEvent(",
        "  Widget _buildInput(",
        "  Widget _buildMediaButton(",
        "  void _showMediaPickerOptions(",
        "  Future<void> _pickAndSendImage(",
        "  Future<void> _pickAndSendVideo(",
        "  Future<void> _startVoiceRecording(",
        "  void _sendVoiceNote(String filePath)",
        "  void _onTextChanged(",
    ]

    while i < len(lines):
        line = lines[i]

        # Insert import
        if not import_added and line.startswith("import 'package:crushhour/features/chat/presentation/widgets/chat_header.dart';"):
            out_lines.append(line)
            out_lines.append("import 'package:crushhour/features/chat/presentation/widgets/chat_input_bar.dart';\n")
            import_added = True
            i += 1
            continue

        # Remove single line variables
        if "final _controller =" in line or "final _picker =" in line or "final _inputFocusNode =" in line or "bool _isRecordingVoice =" in line or "bool _isPickingMedia =" in line or "bool _hasInputText =" in line:
            # Note: _hasInputText might be multi-line in dart formatting. But it was just "_hasInputText =" 
            pass
            i += 1
            if "_hasInputText =" in line and "false;" not in line:
                 # it spanned 2 lines, skip the next line too
                 i += 1
            continue
            
        # Remove event listener bindings in initState
        if "_controller.addListener(_onTextChanged);" in line or "_inputFocusNode.onKeyEvent = _handleKeyEvent;" in line:
            i += 1
            continue
            
        # Remove disposal
        if "_controller.dispose();" in line or "_inputFocusNode.dispose();" in line:
            i += 1
            continue

        # Replace _buildInput usage
        if "                  _buildInput(" in line:
            out_lines.append("""                  ChatInputBar(
                    state: state,
                    isBlocked: isBlocked,
                    canMessage: canMessage,
                    isUnmatched: state.isUnmatched,
                    completeness: completeness,
                    currentUserId: widget.args.currentUserId,
                    otherUserId: widget.args.otherUserId,
                    otherName: widget.args.otherName,
                    matchId: widget.args.matchId,
                    onEnsureMessagingAllowed: _ensureBackendAllowsMessaging,
                    onShowMessagingIncomplete: _showMessagingIncomplete,
                  ),\n""")
            # fast forward 6 lines to skip the rest of the old `_buildInput` arguments
            i += 7
            continue

        # Remove entire methods
        is_deleting_method = False
        for method_sig in methods_to_delete:
            if line.startswith(method_sig):
                is_deleting_method = True
                break
                
        if is_deleting_method:
            bracket_count = 0
            if "{" in line:
                bracket_count += line.count("{") - line.count("}")
                
            i += 1
            
            # Special case for method signature separated from its body brackets
            while i < len(lines) and bracket_count == 0 and "{" not in lines[i] and not lines[i].strip() == "":
                i += 1
                
            if i < len(lines) and "{" in lines[i] and bracket_count == 0:
                bracket_count += lines[i].count("{") - lines[i].count("}")
                i += 1

            while i < len(lines) and bracket_count > 0:
                bracket_count += lines[i].count("{") - lines[i].count("}")
                i += 1
            continue

        out_lines.append(line)
        i += 1

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
    
    print("Refactored chat screen for input bar")

if __name__ == '__main__':
    refactor()
