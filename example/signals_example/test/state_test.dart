import 'package:flutter_test/flutter_test.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals_example/src/common.dart';
import 'package:signals_example/src/state.dart';

void main() {
  test('computed 在筛选变化时给出新列表', () {
    final lab = LabSignals();
    addTearDown(lab.dispose);
    lab.addTodo('买茶');
    lab.setFilter(TodoFilter.done);
    expect(lab.visible.value, isEmpty);
    lab.setFilter(TodoFilter.all);
    expect(lab.visible.value.first.title, '买茶');
  });

  test('batch 只触发一次 effect', () {
    final lab = LabSignals();
    addTearDown(lab.dispose);
    var runs = 0;
    final stop = effect(() {
      lab.count.value;
      lab.taps.value;
      runs += 1;
    });
    addTearDown(stop);
    final before = runs;
    lab.incrementBatch();
    expect(runs, before + 1);

    lab.incrementSplit();
    expect(runs, before + 3);
  });

  test('登出同时清空会话和购物车', () async {
    final lab = LabSignals(authApi: const AuthApi(delay: Duration.zero));
    addTearDown(lab.dispose);
    await lab.login('lee@example.com', '1234');
    lab.addToCart('tea');
    expect(lab.cartItemCount.value, 1);
    lab.logout();
    expect(lab.session.value, isNull);
    expect(lab.cartItemCount.value, 0);
  });
}
