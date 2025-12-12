import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/di.dart';
import 'logic/theme/theme_cubit.dart';

class CrushApp extends StatelessWidget {
  const CrushApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: CrushDI.buildRepositories(),
      child: MultiBlocProvider(
        providers: CrushDI.buildBlocs(preferences: preferences),
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'CrushHour',
              theme: CrushTheme.light(),
              darkTheme: CrushTheme.dark(),
              themeMode: themeMode,
              onGenerateRoute: CrushRoutes.onGenerateRoute,
              initialRoute: CrushRoutes.splash,
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
