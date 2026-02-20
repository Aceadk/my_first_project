import json
import os
import re

def generate_pseudo_locale():
    source_path = '/Users/ace/my_first_project/lib/l10n/app_en.arb'
    target_path = '/Users/ace/my_first_project/lib/l10n/app_en_XA.arb'
    
    with open(source_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    pseudo_data = {}
    
    for key, value in data.items():
        if key == '@@locale':
            pseudo_data[key] = 'en_XA'
            continue
            
        if key.startswith('@@') and key != '@@locale':
            pseudo_data[key] = value
            continue
            
        if key.startswith('@') and key != '@@locale':
            pseudo_data[key] = value
            continue
            
        if isinstance(value, str):
            if 'plural,' in value:
                # Plural string: {count, plural, =1{1 minute ago} other{{count} minutes ago}}
                # Just add length to the entire string instead of modifying inner braces
                # But that must be done OUTSIDE the outermost {} if possible.
                # Actually, flutter ICU supports text after the closing brace of the plural block.
                pseudo_data[key] = value + " (expanded string to test overflow xxxx)"
            else:
                target_len = int(len(value) * 1.4)
                added_len = target_len - len(value)
                if added_len < 5:
                    added_len = 5
                
                expansion = " " + ("x" * (added_len - 1))
                pseudo_data[key] = value + expansion
        else:
            pseudo_data[key] = value
            
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(pseudo_data, f, ensure_ascii=False, indent=2)
        
    print(f"Generated {target_path}")

if __name__ == '__main__':
    generate_pseudo_locale()
