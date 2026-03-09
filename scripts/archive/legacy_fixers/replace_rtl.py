import os
import re

target_dirs = ["lib/features/", "lib/design_system/"]

for target_dir in target_dirs:
    for root, dirs, files in os.walk(target_dir):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()
                
                original_content = content
                
                # Replace EdgeInsets.only(left: -> EdgeInsetsDirectional.only(start:
                # Need regex to handle spacing and multiple parameters
                content = re.sub(r'EdgeInsets\.only\s*\(([^)]*)left\s*:', r'EdgeInsetsDirectional.only(\1start:', content)
                content = re.sub(r'EdgeInsets\.only\s*\(([^)]*)right\s*:', r'EdgeInsetsDirectional.only(\1end:', content)
                
                # If both left and right are present:
                # The above might run twice.

                content = re.sub(r'EdgeInsets\.fromLTRB', r'EdgeInsetsDirectional.fromSTEB', content)
                
                # Positioned left -> start, right -> end
                content = re.sub(r'Positioned\s*\(([^)]*)left\s*:', r'PositionedDirectional(\1start:', content)
                content = re.sub(r'Positioned\s*\(([^)]*)right\s*:', r'PositionedDirectional(\1end:', content)
                
                # Also change Positioned to PositionedDirectional if start or end are used
                # Actually, if we changed left/right to start/end, we already changed Positioned to PositionedDirectional across those calls!
                # Wait, what if both left and right were present in Positioned?
                content = re.sub(r'PositionedDirectional\s*\(([^)]*)right\s*:', r'PositionedDirectional(\1end:', content)
                content = re.sub(r'EdgeInsetsDirectional\.only\s*\(([^)]*)right\s*:', r'EdgeInsetsDirectional.only(\1end:', content)
                content = re.sub(r'EdgeInsetsDirectional\.only\s*\(([^)]*)left\s*:', r'EdgeInsetsDirectional.only(\1start:', content)
                content = re.sub(r'PositionedDirectional\s*\(([^)]*)left\s*:', r'PositionedDirectional(\1start:', content)

                # Alignment
                content = re.sub(r'Alignment\.topLeft', r'AlignmentDirectional.topStart', content)
                content = re.sub(r'Alignment\.topRight', r'AlignmentDirectional.topEnd', content)
                content = re.sub(r'Alignment\.bottomLeft', r'AlignmentDirectional.bottomStart', content)
                content = re.sub(r'Alignment\.bottomRight', r'AlignmentDirectional.bottomEnd', content)
                content = re.sub(r'Alignment\.centerLeft', r'AlignmentDirectional.centerStart', content)
                content = re.sub(r'Alignment\.centerRight', r'AlignmentDirectional.centerEnd', content)
                
                if content != original_content:
                    with open(filepath, "w") as f:
                        f.write(content)

