import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  runApp(const SignalsExampleApp());
}

class SignalsExampleApp extends StatelessWidget {
  const SignalsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        return MaterialApp(
          title: 'Signals',
          theme: labTheme(Colors.green, Brightness.light),
          darkTheme: labTheme(Colors.green, Brightness.dark),
          themeMode: signals.themeMode.value,
          home: const Shell(),
        );
      },
    );
  }
}
