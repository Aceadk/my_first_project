import os

files_to_fix = [
    "lib/features/calls/presentation/screens/call_screen.dart",
    "lib/features/chat/presentation/screens/chat_list_screen.dart",
    "lib/features/chat/presentation/screens/chat_screen.dart",
    "lib/features/chat/presentation/screens/matches_screen.dart",
    "lib/features/chat/presentation/screens/message_requests_screen.dart",
    "lib/features/chat/presentation/widgets/chat_header.dart",
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            content = f.read()
        
        content = content.replace('const SizedBox', 'SizedBox')
        content = content.replace('const Container', 'Container')
        content = content.replace('const Scaffold', 'Scaffold')
        content = content.replace('const TabBar', 'TabBar')
        content = content.replace('const AppBar', 'AppBar')
        content = content.replace('const Drawer', 'Drawer')
        content = content.replace('const IconButton', 'IconButton')
        content = content.replace('const Icon', 'Icon')
        
        with open(filepath, "w") as f:
            f.write(content)
