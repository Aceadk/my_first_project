import os

target_dir = "lib/features/"

for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r") as f:
                content = f.read()

            if "AppLocalizations" in content:
                content = content.replace('const Row(', 'Row(')
                content = content.replace('const Column(', 'Column(')
                content = content.replace('const SnackBar(', 'SnackBar(')
                content = content.replace('const [', '[')
                content = content.replace('const Center(', 'Center(')
                content = content.replace('const Padding(', 'Padding(')
                content = content.replace('const Align(', 'Align(')
                content = content.replace('child: const Text', 'child: Text')
                content = content.replace('title: const Text', 'title: Text')
                content = content.replace('label: const Text', 'label: Text')
                with open(filepath, "w") as f:
                    f.write(content)
