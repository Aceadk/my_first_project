import re

with open("lib/features/chat/presentation/screens/chat_screen.dart", "r") as f:
    text = f.read()

# Remove unused imports
unused_imports = [
    "dart:io",
    "package:crushhour/core/app_logger.dart",
    "package:crushhour/core/services/haptic_service.dart",
    "package:crushhour/design_system/theme/theme_extensions.dart",
    "package:crushhour/design_system/tokens/radius.dart",
    "package:crushhour/design_system/tokens/spacing.dart",
    "package:crushhour/design_system/widgets/glass_button.dart",
    "package:crushhour/design_system/widgets/glass_skeleton.dart",
    "package:crushhour/features/calls/presentation/screens/video_call_screen.dart",
    "package:crushhour/presentation/widgets/plus_feature_gate.dart",
    "package:crushhour/shared/widgets/cached_image.dart",
    "package:flutter/services.dart",
    "package:image_picker/image_picker.dart",
    "package:url_launcher/url_launcher.dart"
]

for imp in unused_imports:
    pattern = f"import '{imp}';\n"
    text = text.replace(pattern, "")

# Remove _isTyping
text = re.sub(r'bool _isTyping = false;\n?', '', text)

if "import 'package:crushhour/features/chat/presentation/widgets/chat_message_list.dart';" not in text:
    text = "import 'package:crushhour/features/chat/presentation/widgets/chat_message_list.dart';\n" + text

with open("lib/features/chat/presentation/screens/chat_screen.dart", "w") as f:
    f.write(text)

