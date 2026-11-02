import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'common.dart';
import 'state.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Signals',
      clock: SignalBuilder(
        builder: (context) {
          final time = signals.clock.value.value ?? DateTime.now();
          return Text(formatTime(time));
        },
      ),
      index: _index,
      onSelected: (index) => setState(() => _index = index),
      body: IndexedStack(
        index: _index,
        children: const [
          OverviewPage(),
          CounterPage(),
          TodoPage(),
          CatalogPage(),
          ShopPage(),
          ScopePage(),
        ],
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      children: [
        BriefView(
          version: 'signals 7.1.0',
          summary: 'Signals 用 signal、computed 和 effect 描述依赖。Widget 在 build 或 SignalBuilder 里读到哪个 .value，就只订阅哪个。',
          strengths: [
            '粒度细。读到 count 的组件不会因为 taps 单独变化而重建，反过来也一样。',
            'computed 懒计算，只有真正被读到时才跑，依赖变了才重新算。',
            'effect 可以返回清理函数，搜索防抖的 Timer 会在下一次输入或销毁时取消。',
            'batch 把多次写入合成一次通知。',
            'futureSignal 和 streamSignal 把 Future、Stream 收成 AsyncState。',
            'SignalEffect 跑副作用，不重建 child。局部 signal 可以放在 State 里，跟页面一起销毁。',
          ],
          weaknesses: [
            '依赖是运行时追踪的。写在 if 里的读取，分支变了，订阅也会变。',
            '库不管依赖注入。这个示例用一个全局 LabSignals，测试时要另外 new 一份。',
            'effect 里如果同步改被自己读取的 signal，可能打成循环。',
            '大型项目里全局 signal 容易变成隐式共享状态，约定要自己定。',
            '和 Bloc、Riverpod 相比，团队规范和 DevTools 生态还更年轻。',
          ],
          scenarios: [
            'signal、computed、effect、batch、peek、untracked。',
            'SignalBuilder 做外科手术式刷新。',
            'effect 清理函数做 300ms 搜索防抖。',
            'futureSignal.reload 手动重试；untracked 读取失败开关，避免一切换就重新请求。',
            'streamSignal 做时钟。',
            'batch 在登出时同时清会话和购物车。',
            'SignalStatefulWidget 持有页面级 signal，SignalEffect 在数到 5 时弹 SnackBar。',
          ],
        ),
        Note(text: 'peek 读到的是当时的值，但不会建立订阅。刷新页里那一行在你只点加号时保持第一次构建的数字。'),
      ],
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '分两次写会通知两次。batch 把 count 和 taps 合成一次通知，同时读这两个值的组件只构建一次。',
        ),
        const RebuildProbe(label: '刷新页骨架'),
        Text('peek 看到的计数 ${signals.count.peek()}'),
        SignalBuilder(
          builder: (context) {
            final count = signals.count.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '计数 $count',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const RebuildProbe(label: '只读取 count'),
              ],
            );
          },
        ),
        SignalBuilder(
          builder: (context) {
            final count = signals.count.value;
            final taps = signals.taps.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('count $count / taps $taps / 双倍 ${signals.doubled.value}'),
                const RebuildProbe(label: '同时读取 count 和 taps'),
              ],
            );
          },
        ),
        Row(
          children: [
            FilledButton(
              onPressed: signals.increment,
              child: const Text('只加 count'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: signals.decrement,
              child: const Text('减 count'),
            ),
          ],
        ),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: signals.incrementSplit,
              child: const Text('分两次加'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: signals.incrementBatch,
              child: const Text('batch 一起加'),
            ),
          ],
        ),
        SignalBuilder(
          builder: (context) {
            return Row(
              children: [
                const Text('暗色'),
                Switch(
                  value: signals.themeMode.value == ThemeMode.dark,
                  onChanged: (_) => signals.toggleTheme(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: 'remaining 这个 computed 只读 todos。切换筛选不会让它重新计算，对应的 SignalBuilder 也不重建。',
        ),
        SignalBuilder(
          builder: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('未完成 ${signals.remaining.value}'),
                const RebuildProbe(label: '未完成计数'),
              ],
            );
          },
        ),
        QueryField(onChanged: signals.setQueryInput),
        SignalBuilder(
          builder: (context) {
            return FilterChips(
              filter: signals.filter.value,
              onChanged: signals.setFilter,
            );
          },
        ),
        TitleField(onSubmit: signals.addTodo),
        SignalBuilder(
          builder: (context) {
            final todos = signals.visible.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RebuildProbe(label: '待办列表'),
                if (todos.isEmpty) const Text('没有符合条件的待办'),
                for (final todo in todos)
                  TodoTile(
                    todo: todo,
                    onToggle: () => signals.toggleTodo(todo.id),
                    onRemove: () => signals.removeTodo(todo.id),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(text: '失败开关用 untracked 读进 futureSignal。拨动开关不会自动重请求，要点重新加载。'),
        SignalBuilder(
          builder: (context) {
            final loading =
                signals.catalog.value.isLoading &&
                !signals.catalog.value.hasValue;
            return Row(
              children: [
                const Text('下次请求失败'),
                Switch(
                  value: signals.failNext.value,
                  onChanged: loading
                      ? null
                      : (value) => signals.failNext.value = value,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: loading
                      ? null
                      : () => unawaited(signals.reloadCatalog()),
                  child: const Text('重新加载'),
                ),
              ],
            );
          },
        ),
        SignalBuilder(
          builder: (context) {
            return signals.catalog.value.map(
              loading: () => const LinearProgressIndicator(),
              error: (error) => Text(errorText(error ?? '未知错误')),
              data: (products) => Column(
                children: [
                  for (final product in products)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product.name),
                      subtitle: Text(product.priceLabel),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '登出用 batch，一次写入里清掉会话和购物车。addToCart 用 peek 读会话，避免按钮回调里的读取被谁订阅。',
        ),
        SignalBuilder(
          builder: (context) {
            final session = signals.session.value;
            if (session == null) {
              return LoginForm(
                busy: signals.authBusy.value,
                error: signals.authError.value,
                onSubmit: (email, password) =>
                    unawaited(signals.login(email, password)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你好，${session.name}'),
                OutlinedButton(
                  onPressed: signals.logout,
                  child: const Text('登出'),
                ),
              ],
            );
          },
        ),
        SignalBuilder(
          builder: (context) {
            final products = signals.catalog.value.value ?? const <Product>[];
            final signedIn = signals.session.value != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '购物车 ${signals.cartItemCount.value} 件，合计 ${centsLabel(signals.cartTotal.value)}',
                ),
                for (final product in products)
                  ProductTile(
                    product: product,
                    quantity: signals.cart.value[product.id] ?? 0,
                    enabled: signedIn,
                    onAdd: () => signals.addToCart(product.id),
                  ),
                if (!signedIn) const Note(text: '登录后才能把商品放进购物车。'),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ScopePage extends StatefulWidget {
  const ScopePage({super.key});

  @override
  State<ScopePage> createState() => _ScopePageState();
}

class _ScopePageState extends State<ScopePage> {
  Future<void> _open() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const DraftPage()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '临时页是 SignalStatefulWidget。count 和 doubled 是 State 自己的字段，弹出页面时 dispose。它们不属于上面的全局 LabSignals。',
        ),
        Text('已经释放 ${DraftPage.disposedCount} 次'),
        FilledButton(onPressed: _open, child: const Text('进入临时页')),
      ],
    );
  }
}

class DraftPage extends SignalStatefulWidget {
  const DraftPage({super.key});

  static int disposedCount = 0;

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  final count = signal(0);
  late final doubled = computed(() => count.value * 2);

  @override
  void dispose() {
    DraftPage.disposedCount += 1;
    doubled.dispose();
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('临时计数')),
      body: SignalEffect(
        effect: (context) {
          if (count.value == 5) {
            showLabSnackBar(context, '临时计数到了 5');
          }
          return null;
        },
        child: PageBody(
          children: [
            const Note(
              text: 'SignalEffect 读 count，数到 5 时弹 SnackBar，child 不会因为 effect 再构建。',
            ),
            Text(
              '临时计数 ${count.value}，双倍 ${doubled.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            FilledButton(
              onPressed: () => count.value += 1,
              child: const Text('加一'),
            ),
          ],
        ),
      ),
    );
  }
}
