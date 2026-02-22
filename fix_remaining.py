import os
import re

target_dir = "lib/features/"

for root, dirs, files in os.walk(target_dir):
    if "presentation" in root:
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()

                changed = False
                
                # Verify import
                if "AppLocalizations.of" in content:
                    # Sometimes the previous script inserted a bad URI or failed to add it
                    if "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" not in content:
                        lines = content.split('\n')
                        insert_idx = 0
                        for i, line in enumerate(lines):
                            if line.startswith('import '):
                                insert_idx = i + 1
                        lines.insert(insert_idx, "import 'package:flutter_gen/gen_l10n/app_localizations.dart';")
                        content = '\n'.join(lines)
                        changed = True
                    
                    # More aggressive 'const ' removal
                    # A common issue is: child: const Text(AppLocalizations...)
                    # We'll just replace 'const Text(AppLocalizations'
                    if 'const Text(AppLocalizations' in content:
                        content = content.replace('const Text(AppLocalizations', 'Text(AppLocalizations')
                        changed = True
                        
                    # Also 'const SomeWidget(child: Text(AppLocalizations...))'
                    # Regex to remove const if the line has AppLocalizations
                    new_lines = []
                    for line in content.split('\n'):
                        if 'AppLocalizations' in line and 'const ' in line:
                            # only remove 'const ' if it's acting as a modifier, not part of a string
                            if 'const ' in line:
                                line = line.replace('const ', '')
                                changed = True
                        new_lines.append(line)
                    content = '\n'.join(new_lines)

                if changed:
                    with open(filepath, "w") as f:
                        f.write(content)

