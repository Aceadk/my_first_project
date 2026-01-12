import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/di.dart';
import 'core/deep_link_bootstrap.dart';
import 'logic/theme/theme_cubit.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';

class CrushApp extends StatelessWidget {
  const CrushApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: CrushDI.buildRepositories(),
      child: MultiBlocProvider(
        providers: CrushDI.buildBlocs(preferences: preferences),
        child: const _RouterHost(),
      ),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost();

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _router = createRouter(authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return DeepLinkBootstrap(
          child: MaterialApp.router(
            title: 'Crush',
            theme: CrushTheme.light(),
            darkTheme: CrushTheme.dark(),
            themeMode: themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
