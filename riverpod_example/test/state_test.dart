import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_example/main.dart';
import 'package:riverpod_example/src/common.dart';
import 'package:riverpod_example/src/state.dart';

void main() {
  test('计数器通过 ProviderContainer 修改', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(counterProvider), 0);
    container.read(counterProvider.notifier).increment();
    expect(container.read(counterProvider), 1);
  });

  test('登出后 listen 清空购物车', () async {
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(const AuthApi(delay: Duration.zero)),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authProvider.notifier)
        .login('lee@example.com', '1234');
    container.read(cartProvider.notifier).add('tea');
    expect(container.read(cartProvider).count, 1);

    container.read(authProvider.notifier).logout();
    expect(container.read(cartProvider).count, 0);
  });

  test('释放容器时 autoDispose 计数增加', () {
    final before = DraftNotifier.disposedCount;
    final container = ProviderContainer();
    container.read(draftProvider);
    container.dispose();
    expect(DraftNotifier.disposedCount, before + 1);
  });

  testWidgets('窄屏和宽屏都能构建概览', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: RiverpodExampleApp()));
    await tester.pump();
    expect(find.text('Riverpod'), findsWidgets);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(const ProviderScope(child: RiverpodExampleApp()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
