import os

# di.dart fix method names
di_file = "lib/core/di.dart"
if os.path.exists(di_file):
    with open(di_file, "r") as f:
        content = f.read()
    # the method names inside CrushDI were called StubCallManagerRepository() but they might just be StubCallRepository()
    content = content.replace("callRepo = StubCallManagerRepository();", "callRepo = StubCallRepository();")
    content = content.replace("callRepo = FirebaseCallManagerRepository();", "callRepo = FirebaseCallRepository();")
    content = content.replace("callRepo = HttpCallManagerRepository(apiClient: client);", "callRepo = HttpCallRepository(apiClient: client);")
    content = content.replace("CallBloc(callRepository: context.read<CallManagerRepository>()),", "CallBloc(callRepository: context.read<CallRepository>()),")
    content = content.replace("RepositoryProvider<CallManagerRepository>", "RepositoryProvider<CallRepository>")
    content = content.replace("final CallManagerRepository callRepo;", "final CallRepository callRepo;")
    with open(di_file, "w") as f:
        f.write(content)

# states_showcase.dart
states = "lib/dev/widget_catalog/showcases/states_showcase.dart"
if os.path.exists(states):
    with open(states, "r") as f:
        lines = f.readlines()
    
    # Just fix lines 128-132 directly or replace the whole showcase item
    with open(states, "w") as f:
        for i, line in enumerate(lines):
            line_num = i + 1
            if line_num == 128 and "EmptyState" in line:
                line = line.replace("(", "(message: 'No data',")
            if line_num == 130 and "EmptyState" in line: # actually child is required?
                line = line.replace("(", "(child: const SizedBox(), message: 'No data',")
            f.write(line)

