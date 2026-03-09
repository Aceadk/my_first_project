import os

showcase = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(showcase):
    with open(showcase, "r") as f:
        content = f.read()
    
    content = content.replace("import 'package:crushhour/design_system/widgets/crush_empty_state.dart';", "")
    if "import 'package:crushhour/design_system/widgets/empty_state.dart';" not in content:
        content = "import 'package:crushhour/design_system/widgets/empty_state.dart';\n" + content
    
    with open(showcase, "w") as f:
        f.write(content)

