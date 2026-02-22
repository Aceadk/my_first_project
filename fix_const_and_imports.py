import os
import re

target_dir = "lib/features/"
# Find lines with 'error - '
# We'll just aggressively remove 'const ' from lines that use AppLocalizations

for root, dirs, files in os.walk(target_dir):
    if "presentation" in root:
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()

                # Add import if using AppLocalizations
                if "AppLocalizations.of" in content and "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" not in content:
                    lines = content.split('\n')
                    insert_idx = 0
                    for i, line in enumerate(lines):
                        if line.startswith('import '):
                            insert_idx = i + 1
                    lines.insert(insert_idx, "import 'package:flutter_gen/gen_l10n/app_localizations.dart';")
                    content = '\n'.join(lines)
                
                # Try to remove const modifiers before widgets containing AppLocalizations
                # This regex might be a bit wild, let's just do a simpler search and replace for common patterns
                # The dart format will fix indentations later if needed, but we can't easily parse AST in Python.
                # A common error is:
                # const Text(AppLocalizations.of(context)!.key) -> this was fixed by previous script, but what about:
                # const ListTile(title: Text(AppLocalizations...))
                # Let's replace 'const ' with '' on lines having 'AppLocalizations'
                
                new_lines = []
                for line in content.split('\n'):
                    if 'AppLocalizations' in line and 'const ' in line:
                        line = line.replace('const ', '')
                    new_lines.append(line)
                
                content = '\n'.join(new_lines)
                
                # Another pass. Often `const [ Text(...) ]` breaks
                # We'll just rely on dart format and quick fixes if possible, or remove `const ` manually in dart code.
                with open(filepath, "w") as f:
                    f.write(content)

