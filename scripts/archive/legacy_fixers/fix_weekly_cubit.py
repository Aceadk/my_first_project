with open("lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart", "r") as f:
    text = f.read()

# Fix the final _service initialization
if "  WeeklyPicksCubit({required AuthRepository authRepository})" in text:
    text = text.replace(
        "  WeeklyPicksCubit({required AuthRepository authRepository})",
        "  WeeklyPicksCubit({required AuthRepository authRepository, required WeeklyPicksRepository weeklyPicksRepository}) : _service = weeklyPicksRepository, "
    )
elif "  WeeklyPicksCubit({required AuthRepository authRepository})\n      :" in text:
    text = text.replace(
        "  WeeklyPicksCubit({required AuthRepository authRepository})\n      :",
        "  WeeklyPicksCubit({required AuthRepository authRepository, required WeeklyPicksRepository weeklyPicksRepository})\n      : _service = weeklyPicksRepository,"
    )

with open("lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart", "w") as f:
    f.write(text)

with open("lib/features/discovery/presentation/screens/weekly_picks_screen.dart", "r") as f:
    screen = f.read()

# Fix the duplicate @override
screen = screen.replace("  late final _service = context.read<WeeklyPicksRepository>();\n\n  @override\n  void initState() {", "  late final _service = context.read<WeeklyPicksRepository>();\n  void initState() {")
# Wait, I had: "  late final _service = context.read<WeeklyPicksRepository>();\n\n  @override\n  void initState() {"
# It complained about override on non-overriding member, which implies "late final _service" got the @override?
# Oh! The original file had:
#   @override
#   void initState() {
# And I replaced "  void initState() {" with "  late final _service = ...  @override  void initState() {"
# Which resulted in:
#   @override
#   late final _service = ...
#   @override
#   void initState() {
# I will just write a regex to fix it.

import re
screen = re.sub(r'@override\s*late final _service = context\.read<WeeklyPicksRepository>\(\);\s*@override', r'late final _service = context.read<WeeklyPicksRepository>();\n  @override', screen)

if "import 'package:flutter_bloc/flutter_bloc.dart';" not in screen:
    screen = "import 'package:flutter_bloc/flutter_bloc.dart';\n" + screen

with open("lib/features/discovery/presentation/screens/weekly_picks_screen.dart", "w") as f:
    f.write(screen)
