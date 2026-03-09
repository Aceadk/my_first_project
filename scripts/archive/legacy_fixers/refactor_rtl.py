import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace EdgeInsets.only
    def replace_edge_insets_only(match):
        inner = match.group(1)
        inner = re.sub(r'\bleft\s*:', 'start:', inner)
        inner = re.sub(r'\bright\s*:', 'end:', inner)
        return f'EdgeInsetsDirectional.only({inner})'

    content = re.sub(r'EdgeInsets\.only\((.*?)\)', replace_edge_insets_only, content, flags=re.DOTALL)

    # Replace EdgeInsets.fromLTRB
    content = re.sub(r'EdgeInsets\.fromLTRB', 'EdgeInsetsDirectional.fromSTEB', content)

    # Replace Positioned( ... left/right ... ) -> PositionedDirectional( ... start/end ... )
    # This might be tricky if it spans multiple lines.
    # Let's use a regex that finds Positioned(...) and replaces if it has left or right.
    # To be safe and simple, we can find Positioned( ... ) honoring balanced parentheses
    # but regex for balanced parentheses is hard. Let's do a simple heuristic
    # finding `Positioned(` and replacing `left:` and `right:` inside it until the matching closing parenthesis.
    
    # We can write a simple parser for Positioned(...)
    
    def process_positioned(text):
        idx = 0
        while True:
            idx = text.find('Positioned(', idx)
            if idx == -1:
                break
            
            # find matching parenthesis
            open_parens = 1
            close_idx = idx + 11
            while close_idx < len(text) and open_parens > 0:
                if text[close_idx] == '(':
                    open_parens += 1
                elif text[close_idx] == ')':
                    open_parens -= 1
                close_idx += 1
            
            if open_parens == 0:
                inner = text[idx+11:close_idx-1]
                if 'left:' in inner or 'right:' in inner:
                    new_inner = re.sub(r'\bleft\s*:', 'start:', inner)
                    new_inner = re.sub(r'\bright\s*:', 'end:', new_inner)
                    text = text[:idx] + 'PositionedDirectional(' + new_inner + ')' + text[close_idx:]
                    idx = idx + 22 + len(new_inner) # advance paste
                else:
                    idx = close_idx
            else:
                idx += 11
        return text

    content = process_positioned(content)
    
    # Also fix Positioned.fill(left: ..., right: ...) if that exists? Wait, Positioned.fill doesn't take left/right, it takes left/top/right/bottom.
    # Actually PositionedDirectional.fill does not exist maybe, let's not touch Positioned.fill
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

def main():
    lib_dir = '/Users/ace/my_first_project/lib'
    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
