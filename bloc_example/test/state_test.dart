import 'package:bloc_example/main.dart';
import 'package:bloc_example/src/common.dart';
import 'package:bloc_example/src/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cubit 直接发出新数字', () async {
    final cubit = CounterCubit();
    cubit.increment();
    expect(cubit.state, 1);
    await cubit.close();
  });

  test('Bloc 把添加事件变成新列表', () async {
    final bloc = TodoBloc();
    bloc.add(const TodoAdded('买茶'));
    await bloc.stream.first;
    expect(bloc.state.todos.first.title, '买茶');
    expect(bloc.state.remaining, 3);
    await bloc.close();
  });

  test('登出后由调用方清空购物车', () async {
    final auth = AuthCubit(const AuthApi(delay: Duration.zero));
    final cart = CartCubit();
    await auth.login('lee@example.com', '1234');
    expect(auth.state.session?.name, 'lee');
    cart.add('tea');
    expect(cart.state.count, 1);
    auth.logout();
    cart.clear();
    expect(cart.state.count, 0);
    await auth.close();
    await cart.close();
  });

  test('close 会留下释放次数', () async {
    final before = DraftCubit.closedCount;
    final draft = DraftCubit()..increment();
    expect(draft.state, 1);
    await draft.close();
    expect(DraftCubit.closedCount, before + 1);
  });

  testWidgets('窄屏和宽屏都能构建概览', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BlocExampleApp());
    await tester.pump();
    expect(find.text('Bloc / Cubit'), findsWidgets);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const BlocExampleApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
