import glob
import re

files = glob.glob('docs/TODO_*.md')
removed_count = 0

for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if "## (Auto-Merged from V2 Audit Directive)" in content:
        # Regex to strip the old headers/tasks but retain the new ones
        # We will split at the V2 divider and keep only the V2 block
        parts = content.split("## (Auto-Merged from V2 Audit Directive)")
        if len(parts) > 1:
            clean_v2_content = parts[1].strip()
            # Write back strictly the V2 content
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(clean_v2_content)
            removed_count += 1
            
print(f"Cleaned legacy clutter from {removed_count} unified V2 Audit files.")
