import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'src/common.dart';
import 'src/pages.dart';
import 'src/state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerControllers();
  runApp(const GetxExampleApp());
}

class GetxExampleApp extends StatelessWidget {
  const GetxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return Obx(() {
      return GetMaterialApp(
        title: 'GetX',
        theme: labTheme(Colors.deepPurple, Brightness.light),
        darkTheme: labTheme(Colors.deepPurple, Brightness.dark),
        themeMode: theme.mode.value,
        home: const Shell(),
      );
    });
  }
}
