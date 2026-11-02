import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_example/main.dart';
import 'package:provider_example/src/common.dart';
import 'package:provider_example/src/state.dart';

void main() {
  test('计数器通知新的值', () {
    final counter = CounterController();
    counter.increment();
    expect(counter.count, 1);
    counter.decrement();
    expect(counter.count, 0);
  });

  test('待办筛选只看标题和状态', () {
    final todos = TodoController()..add('买茶');
    todos.toggle(todos.todos.last.id);
    todos.setFilter(TodoFilter.done);
    expect(todos.remaining, 2);
    expect(visibleTodos(todos.todos, todos.filter, '').single.title, '试一次局部刷新');
  });

  test('登出后购物车被清空', () async {
    final session = SessionController(const AuthApi(delay: Duration.zero));
    final cart = CartController();
    await session.login('lee@example.com', '1234');
    cart.updateSession(session.session);
    cart.add('tea');
    expect(cart.count, 1);

    session.logout();
    cart.updateSession(session.session);
    expect(cart.count, 0);
  });

  test('草稿计数器 dispose 时计数', () {
    final before = DraftCounter.disposedCount;
    final draft = DraftCounter()..increment();
    expect(draft.count, 1);
    draft.dispose();
    expect(DraftCounter.disposedCount, before + 1);
  });

  testWidgets('窄屏和宽屏都能构建概览', (tester) async {
    await _pumpSized(tester, const Size(390, 844), const ProviderExampleApp());
    expect(find.text('概览'), findsWidgets);
    await _pumpSized(tester, const Size(1200, 800), const ProviderExampleApp());
    expect(find.text('Provider'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpSized(WidgetTester tester, Size size, Widget app) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pump();
}
