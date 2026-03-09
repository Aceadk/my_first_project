import glob
import re

dart_files = glob.glob('lib/**/*.dart', recursive=True)

findings = {
    "missing_semantics": [],
    "hardcoded_text_scale": [],
    "missing_image_labels": [],
    "reduced_motion": 0,
    "focus_nodes": 0
}

for fpath in dart_files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Check for InkWell or GestureDetector without semantic labels nearby (heuristic)
        if 'GestureDetector(' in content and 'Semantics(' not in content:
            findings["missing_semantics"].append(fpath)
            
        # Check for disabled text scaling
        if 'textScaleFactor: 1.0' in content or 'textScaler: TextScaler.noScaling' in content:
            findings["hardcoded_text_scale"].append(fpath)
            
        # Check for Image without semanticLabel
        if 'Image.asset' in content and 'semanticLabel:' not in content:
            findings["missing_image_labels"].append(fpath)
            
        if 'disableAnimations' in content:
            findings["reduced_motion"] += 1
            
        if 'FocusNode' in content:
            findings["focus_nodes"] += 1

print("=== ACCESSIBILITY AUDIT SUMMARY ===")
print(f"Files with GestureDetector but no Semantics: {len(findings['missing_semantics'])}")
print(f"Files with hardcoded text scale (preventing dynamic type): {len(findings['hardcoded_text_scale'])}")
if len(findings['hardcoded_text_scale']) > 0:
    for f in findings['hardcoded_text_scale']: print("  -", f)
print(f"Files with Image.asset missing semanticLabel: {len(findings['missing_image_labels'])}")
print(f"Reduced motion checks: {findings['reduced_motion']}")
print(f"FocusNode usages: {findings['focus_nodes']}")
