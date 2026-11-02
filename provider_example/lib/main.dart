import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  runApp(const ProviderExampleApp());
}

class ProviderExampleApp extends StatelessWidget {
  const ProviderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CatalogApi>(create: (_) => const CatalogApi()),
        Provider<AuthApi>(create: (_) => const AuthApi()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => CounterController()),
        ChangeNotifierProvider(create: (_) => TodoController()),
        ChangeNotifierProvider(
          create: (context) => CatalogController(context.read<CatalogApi>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SessionController(context.read<AuthApi>()),
        ),
        ChangeNotifierProxyProvider<SessionController, CartController>(
          create: (_) => CartController(),
          update: (_, session, cart) {
            cart!.updateSession(session.session);
            return cart;
          },
        ),
        StreamProvider<DateTime>(
          initialData: DateTime.now(),
          create: (_) async* {
            yield DateTime.now();
            yield* Stream<DateTime>.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            );
          },
        ),
        FutureProvider<LabTip>(
          initialData: const LabTip('正在准备一句提示…'),
          create: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            return const LabTip(
              'FutureProvider 适合读一次的异步值。要手动重试时，ChangeNotifier 更直接。',
            );
          },
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'Provider',
      theme: labTheme(Colors.teal, Brightness.light),
      darkTheme: labTheme(Colors.teal, Brightness.dark),
      themeMode: mode,
      home: const Shell(),
    );
  }
}
