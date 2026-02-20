import os

di_file = "lib/core/di.dart"
if os.path.exists(di_file):
    with open(di_file, "r") as f:
        content = f.read()
    # Turn everything back to CallManagerRepository
    content = content.replace("CallRepository callRepo", "CallManagerRepository callRepo")
    content = content.replace("RepositoryProvider<CallRepository>", "RepositoryProvider<CallManagerRepository>")
    content = content.replace("context.read<CallRepository>()", "context.read<CallManagerRepository>()")
    with open(di_file, "w") as f:
        f.write(content)

