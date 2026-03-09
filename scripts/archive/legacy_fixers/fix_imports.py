import os

files = [
    "lib/features/discovery/presentation/widgets/story_ring.dart",
    "lib/features/profile/presentation/widgets/profile_media_picker.dart"
]

for filepath in files:
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            content = f.read()

        if "import 'package:crushhour/l10n/generated/app_localizations.dart';" not in content:
            # find first import
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i, "import 'package:crushhour/l10n/generated/app_localizations.dart';")
                    break
            content = '\n'.join(lines)
            
            with open(filepath, "w") as f:
                f.write(content)

