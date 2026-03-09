import os
import re

# 1. Add implements to WeeklyPicksService
with open("lib/features/discovery/data/services/weekly_picks_service.dart", "r") as f:
    text = f.read()

text = text.replace("class WeeklyPicksService {", "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';\n\nclass WeeklyPicksService implements WeeklyPicksRepository {")
with open("lib/features/discovery/data/services/weekly_picks_service.dart", "w") as f:
    f.write(text)

# 2. Add to di.dart
with open("lib/core/di.dart", "r") as f:
    di_text = f.read()

di_import = "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';\nimport 'package:crushhour/features/discovery/data/services/weekly_picks_service.dart';\n"
if "weekly_picks_repository.dart" not in di_text:
    idx = di_text.find("import 'package:crushhour/features/social/data/services/compatibility_quiz_service.dart';")
    di_text = di_text[:idx] + di_import + di_text[idx:]
    
    provider = "      RepositoryProvider<WeeklyPicksRepository>.value(\n          value: WeeklyPicksService.instance),\n"
    idx2 = di_text.find("RepositoryProvider<CompatibilityQuizRepository>.value")
    di_text = di_text[:idx2] + provider + di_text[idx2:]

with open("lib/core/di.dart", "w") as f:
    f.write(di_text)

# 3. Update Cubit
with open("lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart", "r") as f:
    cubit = f.read()
cubit = cubit.replace(
    "import '../../data/services/weekly_picks_service.dart';",
    "import '../../domain/repositories/weekly_picks_repository.dart';"
)
cubit = cubit.replace("final _service = WeeklyPicksService.instance;", "")
# Since cubit needs the repository injected, actually it's easier to just pass it in constructor!
# But wait, it's a Cubit. Let's just pass `WeeklyPicksRepository` to it.
cubit = cubit.replace("class WeeklyPicksCubit extends Cubit<WeeklyPicksState> {", "class WeeklyPicksCubit extends Cubit<WeeklyPicksState> {\n  final WeeklyPicksRepository _service;\n")
cubit = cubit.replace("WeeklyPicksCubit() : super(WeeklyPicksInitial())", "WeeklyPicksCubit({required WeeklyPicksRepository weeklyPicksRepository}) : _service = weeklyPicksRepository, super(WeeklyPicksInitial())")

if "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';" not in cubit:
    cubit = "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';\n" + cubit

with open("lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart", "w") as f:
    f.write(cubit)

# 4. Update Screen
with open("lib/features/discovery/presentation/screens/weekly_picks_screen.dart", "r") as f:
    screen = f.read()
screen = screen.replace("import '../data/services/weekly_picks_service.dart';", "")
screen = screen.replace("final _service = WeeklyPicksService.instance;", "")
screen = screen.replace("  void initState() {", "  late final _service = context.read<WeeklyPicksRepository>();\n\n  @override\n  void initState() {")
if "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';" not in screen:
    screen = "import 'package:crushhour/features/discovery/domain/repositories/weekly_picks_repository.dart';\n" + screen

with open("lib/features/discovery/presentation/screens/weekly_picks_screen.dart", "w") as f:
    f.write(screen)
