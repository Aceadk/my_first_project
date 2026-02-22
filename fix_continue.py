import os
import json

arb_path = "lib/l10n/app_en.arb"

with open(arb_path, "r") as f:
    arb_data = json.load(f)

# Change 'continue' to 'continueLabel'
if "continue" in arb_data:
    val = arb_data["continue"]
    del arb_data["continue"]
    arb_data["continueLabel"] = val

with open(arb_path, "w") as f:
    json.dump(arb_data, f, indent=2)

# Fix dart files using 'continue'
target_dir = "lib/features/"
for root, dirs, files in os.walk(target_dir):
    if "presentation" in root:
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()
                
                if ".continue" in content:
                    content = content.replace(".continue)", ".continueLabel)")
                    content = content.replace(".continue,", ".continueLabel,")
                    with open(filepath, "w") as f:
                        f.write(content)

