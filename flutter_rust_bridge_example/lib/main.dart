import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_example/src/lesson_page.dart';
import 'package:flutter_rust_bridge_example/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const RustBridgeApp());
}

class RustBridgeApp extends StatelessWidget {
  const RustBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Rust',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457C5)),
        useMaterial3: true,
      ),
      home: const LessonPage(),
    );
  }
}
