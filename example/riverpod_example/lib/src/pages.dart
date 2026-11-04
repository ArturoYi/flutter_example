import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      title: 'Riverpod',
      clock: const _Clock(),
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

class _Clock extends ConsumerWidget {
  const _Clock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(clockProvider).value ?? DateTime.now();
    return Text(formatTime(time));
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      children: [
        BriefView(
          version: 'flutter_riverpod 3.4.3',
          summary: 'Riverpod 3 把依赖声明成全局的 Provider，读的时候才创建。推荐用 Notifier 和 AsyncNotifier。StateProvider 还在，但已经挪到 legacy.dart，这个示例不用它。',
          strengths: [
            '不依赖 BuildContext，组件、测试和别的 Provider 都能读。',
            'ref.watch 会自动建立依赖，select 只在选中的值变化时重建。',
            'AsyncNotifier 把 loading、error、data 收成 AsyncValue，还可以 invalidate 重来。',
            'autoDispose 在没有监听者时释放；family 按参数分出不同的值。',
            '失败的 Provider 默认会退避重试。这个示例把目录的重试关掉，错误才会停在界面上。',
            '测试可以用 ProviderContainer，并用 overrideWithValue 换掉 API。',
          ],
          weaknesses: [
            '概念比 Provider 多：Provider、Notifier、family、autoDispose、AsyncValue、retry。',
            '不写代码生成时，NotifierProvider 的类型参数比较长。写代码生成就要多跑 build_runner。',
            '3.0 和 2.x 不兼容，旧的 StateNotifier、AutoDisposeNotifier 要迁移。',
            '默认重试会让“失败后停住等用户重试”的交互失效，需要显式关掉。',
            '这个示例没有使用仍标记为实验性质的离线缓存和 Mutation。',
          ],
          scenarios: [
            'Provider 注入 API，NotifierProvider 放计数、主题、待办、登录和购物车。',
            'AsyncNotifier 加 AsyncValue，目录请求关闭自动重试。',
            'StreamProvider 做时钟。',
            'ref.watch.select 分开刷新未完成数量和列表。',
            'Provider.family 按商品 id 读取。',
            'ref.listen 在登出时清空购物车，也在临时页弹 SnackBar。',
            'NotifierProvider.autoDispose 和 ref.onDispose。',
            'ref.mounted 避免登录请求回来时 Provider 已经释放。',
          ],
        ),
      ],
    );
  }
}

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const Note(text: '这一页自己不 watch 计数。数字放在更小的 Consumer 里，点按钮只用 ref.read。'),
        const RebuildProbe(label: '刷新页骨架'),
        const _CountText(),
        const _DoubledText(),
        Row(
          children: [
            FilledButton(
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Text('加一'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => ref.read(counterProvider.notifier).decrement(),
              child: const Text('减一'),
            ),
          ],
        ),
        const _ThemeSwitch(),
      ],
    );
  }
}

class _CountText extends ConsumerWidget {
  const _CountText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('计数 $count', style: Theme.of(context).textTheme.headlineMedium),
        const RebuildProbe(label: '已订阅的计数'),
      ],
    );
  }
}

class _DoubledText extends ConsumerWidget {
  const _DoubledText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doubled = ref.watch(counterProvider.select((count) => count * 2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('select 读到的双倍 $doubled'),
        const RebuildProbe(label: '双倍'),
      ],
    );
  }
}

class _ThemeSwitch extends ConsumerWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return Row(
      children: [
        const Text('暗色'),
        Switch(
          value: mode == ThemeMode.dark,
          onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
        ),
      ],
    );
  }
}

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageBody(
      children: [
        const Note(text: '筛选不会改变未完成数量，select 到 int 的那一块就不重建。'),
        const _Remaining(),
        QueryField(
          onChanged: (value) => ref.read(todoProvider.notifier).setQuery(value),
        ),
        const _Filter(),
        TitleField(
          onSubmit: (title) => ref.read(todoProvider.notifier).add(title),
        ),
        const _TodoList(),
      ],
    );
  }
}

class _Remaining extends ConsumerWidget {
  const _Remaining();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      todoProvider.select((state) => state.remaining),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('未完成 $remaining'),
        const RebuildProbe(label: '未完成计数'),
      ],
    );
  }
}

class _Filter extends ConsumerWidget {
  const _Filter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoProvider.select((state) => state.filter));
    return FilterChips(
      filter: filter,
      onChanged: (value) => ref.read(todoProvider.notifier).setFilter(value),
    );
  }
}

class _TodoList extends ConsumerWidget {
  const _TodoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      todoProvider.select((state) => (state.todos, state.filter, state.query)),
    );
    final todos = visibleTodos(selected.$1, selected.$2, selected.$3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RebuildProbe(label: '待办列表'),
        if (todos.isEmpty) const Text('没有符合条件的待办'),
        for (final todo in todos)
          TodoTile(
            todo: todo,
            onToggle: () => ref.read(todoProvider.notifier).toggle(todo.id),
            onRemove: () => ref.read(todoProvider.notifier).remove(todo.id),
          ),
      ],
    );
  }
}

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final failNext = ref.watch(failNextProvider);
    final loading = catalog.isLoading;
    return PageBody(
      children: [
        const Note(
          text: '目录是 AsyncNotifier。retry 返回 null，失败后停住，等重新加载。失败开关用 ref.read，避免一切换就自动重请求。',
        ),
        Row(
          children: [
            const Text('下次请求失败'),
            Switch(
              value: failNext,
              onChanged: loading
                  ? null
                  : (value) =>
                        ref.read(failNextProvider.notifier).setValue(value),
            ),
            const Spacer(),
            FilledButton(
              onPressed: loading
                  ? null
                  : () => ref.read(catalogProvider.notifier).reload(),
              child: const Text('重新加载'),
            ),
          ],
        ),
        catalog.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(errorText(error)),
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
        ),
      ],
    );
  }
}

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final cart = ref.watch(cartProvider);
    final products = ref.watch(catalogProvider).value ?? const <Product>[];
    final tea = ref.watch(productProvider('tea'));
    return PageBody(
      children: [
        const Note(
          text: '购物车在 build 里 ref.listen 会话。登出后把 lines 设回空。productProvider 是 family，按 id 取一件商品。',
        ),
        Text(tea == null ? 'family(tea) 还没有数据' : 'family(tea) = ${tea.name}'),
        if (auth.session == null)
          LoginForm(
            busy: auth.busy,
            error: auth.error,
            onSubmit: (email, password) {
              ref.read(authProvider.notifier).login(email, password);
            },
          )
        else ...[
          Text('你好，${auth.session!.name}'),
          OutlinedButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: const Text('登出'),
          ),
        ],
        Text('购物车 ${cart.count} 件，合计 ${centsLabel(cart.totalCents)}'),
        for (final product in products)
          ProductTile(
            product: product,
            quantity: cart.lines[product.id] ?? 0,
            enabled: auth.session != null,
            onAdd: () => ref.read(cartProvider.notifier).add(product.id),
          ),
        if (auth.session == null) const Note(text: '登录后才能把商品放进购物车。'),
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
          text: '临时计数是 autoDispose。路由上的页面是唯一的监听者，弹出后 ref.onDispose 会计数。这一页自己不 watch 它。',
        ),
        Text('已经释放 ${DraftNotifier.disposedCount} 次'),
        FilledButton(onPressed: _open, child: const Text('进入临时页')),
      ],
    );
  }
}

class DraftPage extends ConsumerWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(draftProvider, (previous, next) {
      if (next == 5 && previous != 5) {
        showLabSnackBar(context, '临时计数到了 5');
      }
    });
    final count = ref.watch(draftProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('临时计数')),
      body: PageBody(
        children: [
          const Note(
            text: 'ref.listen 在 build 里注册，状态变化时跑副作用，但不会因为 listen 本身再构建一棵新树。',
          ),
          Text(
            '临时计数 $count',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          FilledButton(
            onPressed: () => ref.read(draftProvider.notifier).increment(),
            child: const Text('加一'),
          ),
        ],
      ),
    );
  }
}
