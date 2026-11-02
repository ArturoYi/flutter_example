import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  Bloc.observer = LabBlocObserver();
  runApp(const BlocExampleApp());
}

class BlocExampleApp extends StatelessWidget {
  const BlocExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogApi>(create: (_) => const CatalogApi()),
        RepositoryProvider<AuthApi>(create: (_) => const AuthApi()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => CounterCubit()),
          BlocProvider(create: (_) => TodoBloc()),
          BlocProvider(
            create: (context) => CatalogCubit(context.read<CatalogApi>()),
          ),
          BlocProvider(create: (context) => AuthCubit(context.read<AuthApi>())),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ClockCubit()),
        ],
        child: const _ThemedApp(),
      ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return MaterialApp(
          title: 'Bloc',
          theme: labTheme(Colors.blue, Brightness.light),
          darkTheme: labTheme(Colors.blue, Brightness.dark),
          themeMode: mode,
          home: const Shell(),
        );
      },
    );
  }
}
