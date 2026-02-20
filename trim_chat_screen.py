import os

def refactor():
    path = '/Users/ace/my_first_project/lib/features/chat/presentation/screens/chat_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    i = 0
    
    # 1. Add import
    import_added = False

    while i < len(lines):
        line = lines[i]
        
        # Insert import
        if not import_added and line.startswith("import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';"):
            out_lines.append(line)
            out_lines.append("import 'package:crushhour/features/chat/presentation/widgets/chat_header.dart';\n")
            import_added = True
            i += 1
            continue
            
        # Replace _buildGlassAppBar usage
        if "appBar: _buildGlassAppBar(" in line:
            # We know it spans 8 lines
            out_lines.append("""              appBar: ChatHeader(
                state: state,
                isBlocked: isBlocked,
                messagesMuted: messagesMuted,
                callsMuted: callsMuted,
                safetyCubit: safety,
                otherName: widget.args.otherName,
                currentUserId: widget.args.currentUserId,
                otherUserId: widget.args.otherUserId,
                matchId: widget.args.matchId,
                onNavigateToProfile: _navigateToProfile,
                onStartAudioCall: _startAudioCall,
                onSafetyAction: (action) => _handleSafetyAction(
                  context,
                  safety,
                  isBlocked: isBlocked,
                  messagesMuted: messagesMuted,
                  callsMuted: callsMuted,
                  action: action,
                ),
              ),\n""")
            i += 8
            continue

        # Rename _ChatSafetyAction usage in method signature
        if "required _ChatSafetyAction action," in line:
            out_lines.append("    required ChatSafetyAction action,\n")
            i += 1
            continue
            
        # Rename _ChatSafetyAction usage in enum case statements
        if "case _ChatSafetyAction." in line:
            out_lines.append(line.replace("_ChatSafetyAction", "ChatSafetyAction"))
            i += 1
            continue

        # Remove _buildGlassAppBar declaration
        if "PreferredSizeWidget _buildGlassAppBar(" in line:
            # Skip until we hit the end of the method
            # The next method is `void _showMessageActions(`
            while i < len(lines) and "void _showMessageActions(" not in lines[i]:
                i += 1
            # keep i pointing to `void _showMessageActions(` so it gets appended next iteration
            continue

        # Remove enum _ChatSafetyAction definition completely
        if "enum _ChatSafetyAction {" in line:
            while i < len(lines) and "}" not in lines[i]:
                i += 1
            i += 1 # skip the closing brace too
            continue

        out_lines.append(line)
        i += 1

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)
    
    print("Refactored chat screen")

if __name__ == '__main__':
    refactor()
