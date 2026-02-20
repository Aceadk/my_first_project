import os

# Remove export
ds_file = "lib/design_system/design_system.dart"
if os.path.exists(ds_file):
    with open(ds_file, "r") as f:
        text = f.read()
    text = text.replace("export 'widgets/crush_empty_state.dart';\n", "")
    with open(ds_file, "w") as f:
        f.write(text)

# Replace in states_showcase
showcase = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(showcase):
    with open(showcase, "r") as f:
        content = f.read()
    content = content.replace("CrushEmptyState", "DsEmptyState")
    
    # Check if DsEmptyState needs to be imported
    if "import" in content and "DsEmptyState" in content and "empty_state.dart" not in content and "design_system.dart" not in content:
        content = "import 'package:crushhour/design_system/widgets/empty_state.dart';\n" + content
    
    with open(showcase, "w") as f:
        f.write(content)

# Delete file
empty_state_file = "lib/design_system/widgets/crush_empty_state.dart"
if os.path.exists(empty_state_file):
    os.remove(empty_state_file)
