import os

ds_file = "lib/design_system/design_system.dart"
if os.path.exists(ds_file):
    with open(ds_file, "r") as f:
        text = f.read()
    text = text.replace("export 'widgets/app_text_field.dart';\n", "")
    with open(ds_file, "w") as f:
        f.write(text)

showcase = "lib/dev/widget_catalog/showcases/inputs_showcase.dart"
if os.path.exists(showcase):
    with open(showcase, "r") as f:
        content = f.read()
    
    # Replace the class
    content = content.replace("AppTextField(", "GlassTextField(")
    content = content.replace("AppTextField", "GlassTextField")
    
    # Replace import
    content = content.replace("import 'package:crushhour/design_system/widgets/app_text_field.dart';", "import 'package:crushhour/design_system/widgets/glass_text_field.dart';")
    
    with open(showcase, "w") as f:
        f.write(content)

empty_state_file = "lib/design_system/widgets/app_text_field.dart"
if os.path.exists(empty_state_file):
    os.remove(empty_state_file)
