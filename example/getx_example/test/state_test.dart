import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_example/main.dart';
import 'package:getx_example/src/common.dart';
import 'package:getx_example/src/state.dart';

void main() {
  tearDown(Get.reset);

  test('响应式计数器修改 .obs', () {
    final counter = CounterController();
    counter.increment();
    expect(counter.count.value, 1);
  });

  test('手动计数只改字段，并按 id 通知', () {
    final counter = ManualCounterController();
    counter.increment();
    expect(counter.count, 1);
  });

  test('待办插入到列表头部', () {
    final todos = TodoController()..add('买茶');
    expect(todos.todos.first.title, '买茶');
    todos.toggle('seed-1');
    expect(todos.remaining, 2);
  });

  test('登出时 ever 清空购物车', () {
    Get.testMode = true;
    final auth = Get.put(
      AuthController(api: const AuthApi(delay: Duration.zero)),
    );
    final cart = Get.put(CartController());
    auth.session.value = const Session(name: 'lee', email: 'lee@example.com');
    cart.add('tea');
    expect(cart.count, 1);

    auth.logout();
    expect(cart.count, 0);
  });

  testWidgets('窄屏和宽屏都能构建概览', (tester) async {
    Get.testMode = true;
    registerControllers();
    addTearDown(() {
      if (Get.isRegistered<ClockService>()) {
        Get.find<ClockService>().onClose();
      }
      Get.reset();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GetxExampleApp());
    await tester.pump();
    expect(find.text('GetX'), findsWidgets);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const GetxExampleApp());
    await tester.pump(const Duration(milliseconds: 800));
    Get.find<ClockService>().onClose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
