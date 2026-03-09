import os

files_to_fix = [
    "lib/features/chat/presentation/screens/chat_screen.dart",
    "lib/features/chat/presentation/screens/matches_screen.dart",
    "lib/features/chat/presentation/screens/message_requests_screen.dart",
    "lib/features/chat/presentation/widgets/chat_header.dart",
    "lib/features/settings/presentation/screens/privacy_settings_screen.dart"
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            content = f.read()
            
        # Strip const from common widgets that might wrap AppLocalizations in these files
        content = content.replace('const PopupMenuItem', 'PopupMenuItem')
        content = content.replace('const Tab', 'Tab')
        content = content.replace('const ListTile', 'ListTile')
        
        with open(filepath, "w") as f:
            f.write(content)

