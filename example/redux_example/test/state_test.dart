import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux_example/main.dart';
import 'package:redux_example/src/common.dart';
import 'package:redux_example/src/state.dart';

void main() {
  test('添加和查询都通过动作修改状态', () async {
    final store = createStore();
    await store.dispatchAndWait(AddTodo('买茶'));
    await store.dispatchAndWait(SetQuery('茶'));
    expect(store.state.visible.map((todo) => todo.title), ['买茶']);
  });

  test('登出动作同时清空会话和购物车', () async {
    final store = createStore(
      services: const Services(authApi: AuthApi(delay: Duration.zero)),
    );
    await store.dispatchAndWait(Login('lee@example.com', '1234'));
    await store.dispatchAndWait(AddToCart('tea'));
    expect(store.state.session?.name, 'lee');
    expect(cartCount(store.state.cart), 1);

    await store.dispatchAndWait(Logout());
    expect(store.state.session, isNull);
    expect(cartCount(store.state.cart), 0);
  });

  test('登录失败不写入会话', () async {
    final store = createStore(
      services: const Services(authApi: AuthApi(delay: Duration.zero)),
    );
    await store.dispatchAndWait(Login('bad', '1234'));
    expect(store.state.session, isNull);
  });

  testWidgets('窄屏和宽屏都能构建概览', (tester) async {
    final store = createStore(
      services: const Services(catalogApi: CatalogApi(delay: Duration.zero)),
    );
    addTearDown(store.shutdown);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      StoreProvider<AppState>(store: store, child: const ReduxExampleApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Async Redux'), findsWidgets);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(
      StoreProvider<AppState>(store: store, child: const ReduxExampleApp()),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
