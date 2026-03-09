import glob
import re

def find_matching_paren(text, start_idx):
    count = 0
    for i in range(start_idx, len(text)):
        if text[i] == '(':
            count += 1
        elif text[i] == ')':
            count -= 1
            if count == 0:
                return i
    return -1

files = glob.glob('lib/**/*.dart', recursive=True)
count_modified = 0

for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'GestureDetector(' not in content:
         continue
         
    new_content = ""
    idx = 0
    modified = False
    
    while True:
        pos = content.find('GestureDetector(', idx)
        if pos == -1:
            new_content += content[idx:]
            break
            
        # Look behind
        lookback = content[max(0, pos-100):pos]
        if 'Semantics' in lookback:
            new_content += content[idx:pos+len('GestureDetector(')]
            idx = pos + len('GestureDetector(')
            continue
            
        # Ignore global keyboard unfocus gestures
        forward_look = content[pos:min(len(content), pos+200)]
        if 'FocusScope.of(context).unfocus()' in forward_look or 'FocusManager.instance.primaryFocus?.unfocus()' in forward_look:
            new_content += content[idx:pos+len('GestureDetector(')]
            idx = pos + len('GestureDetector(')
            continue
            
        matching_paren = find_matching_paren(content, pos + len('GestureDetector'))
        if matching_paren != -1:
            gesture_body = content[pos:matching_paren+1]
            button_prop = ""
            if 'onTap:' in gesture_body:
                button_prop = "button: true, "
            # We don't want to double wrap if we missed the lookback
            if 'Semantics' in gesture_body: # unlikely but possible
                 new_content += content[idx:matching_paren+1]
            else:
                 new_content += content[idx:pos]
                 new_content += f"Semantics({button_prop}child: " + gesture_body + ")"
                 modified = True
            idx = matching_paren + 1
        else:
            new_content += content[idx:pos+len('GestureDetector(')]
            idx = pos + len('GestureDetector(')
            
    if modified:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count_modified += 1

print(f"Modified {count_modified} files with Semantics wrappers.")
