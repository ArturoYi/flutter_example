import 'dart:async';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  final store = createStore(actionObservers: [actionLog]);
  Timer.periodic(const Duration(seconds: 1), (_) {
    store.dispatch(TickClock(DateTime.now()));
  });
  runApp(StoreProvider<AppState>(store: store, child: const ReduxExampleApp()));
}

class ReduxExampleApp extends StatelessWidget {
  const ReduxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select((AppState state) => state.themeMode);
    return MaterialApp(
      title: 'Async Redux',
      theme: labTheme(Colors.deepOrange, Brightness.light),
      darkTheme: labTheme(Colors.deepOrange, Brightness.dark),
      themeMode: mode,
      home: UserExceptionDialog<AppState>(
        useLocalContext: true,
        child: const Shell(),
      ),
    );
  }
}
