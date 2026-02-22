import os
import re
import json

arb_path = "lib/l10n/app_en.arb"
target_dir = "lib/features/"

# Load existing arb
with open(arb_path, "r") as f:
    arb_data = json.load(f)

# Group 1: optional 'const '
# Group 2: string content inside single quotes
text_pattern = re.compile(r"(const\s+)?Text\(\s*'([^']*)'(?:\s*,\s*)?\)")

dart_files = []
for root, dirs, files in os.walk(target_dir):
    if "presentation" in root:
        for file in files:
            if file.endswith(".dart"):
                dart_files.append(os.path.join(root, file))

def to_camel_case(s):
    # Remove punctuation, split by space
    s = re.sub(r'[^\w\s]', '', s)
    words = s.split()
    if not words: return "emptyString"
    return words[0].lower() + ''.join(w.capitalize() for w in words[1:5]) 

replacements = 0
for filepath in dart_files:
    with open(filepath, "r") as f:
        content = f.read()

    new_content = content
    matches = list(text_pattern.finditer(content))
    needs_import = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" in content
    
    # Process from right to left to avoid messing up indices
    for match in reversed(matches):
        full_match = match.group(0)
        has_const = match.group(1)
        string_val = match.group(2)
        
        # skip interpolations and empty strings
        if not string_val or '{' in string_val or '$' in string_val:
            continue 
            
        key = to_camel_case(string_val)
        
        # Ensure unique key
        original_key = key
        counter = 1
        while key in arb_data and arb_data[key] != string_val:
            key = f"{original_key}{counter}"
            counter += 1
            
        arb_data[key] = string_val
        
        # Replace in dart file
        # 'const Text('Hello')' -> 'Text(AppLocalizations.of(context)!.hello)'
        replacement = f"Text(AppLocalizations.of(context)!.{key})"
        
        # Slice out the old and slice in the new
        start, end = match.span()
        new_content = new_content[:start] + replacement + new_content[end:]
        needs_import = True
        replacements += 1

    if new_content != content:
        if not "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" in new_content:
            # prepend import after the last import
            lines = new_content.split('\n')
            insert_idx = 0
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    insert_idx = i + 1
            lines.insert(insert_idx, "import 'package:flutter_gen/gen_l10n/app_localizations.dart';")
            new_content = '\n'.join(lines)
            
        with open(filepath, "w") as f:
            f.write(new_content)

with open(arb_path, "w") as f:
    json.dump(arb_data, f, indent=2)

print(f"Extracted and replaced {replacements} strings.")
