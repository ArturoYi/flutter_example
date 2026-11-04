import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  runApp(const ProviderScope(child: RiverpodExampleApp()));
}

class RiverpodExampleApp extends ConsumerWidget {
  const RiverpodExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Riverpod',
      theme: labTheme(Colors.indigo, Brightness.light),
      darkTheme: labTheme(Colors.indigo, Brightness.dark),
      themeMode: mode,
      home: const Shell(),
    );
  }
}
