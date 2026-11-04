import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<CatalogController>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Provider',
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

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    final time = context.watch<DateTime>();
    return Text(formatTime(time));
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tip = context.watch<LabTip>().text;
    return PageBody(
      children: [
        const BriefView(
          version: 'provider 6.1.5+1',
          summary: 'Provider 把 InheritedWidget 包成可读、可监听、可释放的依赖。状态跟着 widget 子树走，离开这棵子树就会 dispose。',
          strengths: [
            'API 薄，和 Flutter 的 widget 树、生命周期一致，上手快。',
            'ChangeNotifierProvider、Provider、FutureProvider、StreamProvider 能分别放可变状态、普通依赖、一次性异步值和流。',
            'context.select、Selector 可以只订阅一个字段，避免整页重建。',
            'MultiProvider 和 ChangeNotifierProxyProvider 能注入依赖，并让购物车跟着登录状态更新。',
            '页面内创建的 Provider 会随路由弹出而 dispose，作用域自然。',
          ],
          weaknesses: [
            '没有统一的事件和异步状态机，loading、error、重试都要自己写在 ChangeNotifier 里。',
            '没有 BlocListener 这种副作用组件，SnackBar 需要自己 addListener。',
            'context.watch 如果写在过大的 build 上，会把整页连在一起重建。',
            '依赖靠类型查找。同一个子树里放两个相同类型的 Provider 时，会读到更近的那个。',
            '项目变大以后，容易堆出很多互相调用的 ChangeNotifier，约束比 Bloc、Riverpod 弱。',
          ],
          scenarios: [
            'Provider 注入 CatalogApi / AuthApi。',
            'ChangeNotifier 加 context.read、context.watch、context.select。',
            'Selector 按未完成数量和列表分别重建。',
            'ChangeNotifierProxyProvider：购物车依赖会话，登出时清空。',
            'StreamProvider 驱动顶栏时钟，FutureProvider 提供下面这句提示。',
            '路由里新建 DraftCounter，弹出后 dispose。',
          ],
        ),
        Note(text: tip),
        const Note(
          text: '另外五个示例做同一组任务。主题切换会重建 MaterialApp 下面的子树，这是 Flutter 自己的行为。',
        ),
      ],
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      children: [
        Note(
          text: '这一页的骨架不订阅计数。点加减时，只有读了 count 的子组件重建。切换主题会从 MaterialApp 重建整棵子树，骨架的次数也会增加。',
        ),
        RebuildProbe(label: '刷新页骨架'),
        _CountText(),
        _DoubledText(),
        _CounterButtons(),
        _ThemeSwitch(),
      ],
    );
  }
}

class _CountText extends StatelessWidget {
  const _CountText();

  @override
  Widget build(BuildContext context) {
    final count = context.select<CounterController, int>((c) => c.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('计数 $count', style: Theme.of(context).textTheme.headlineMedium),
        const RebuildProbe(label: '已订阅的计数'),
      ],
    );
  }
}

class _DoubledText extends StatelessWidget {
  const _DoubledText();

  @override
  Widget build(BuildContext context) {
    return Selector<CounterController, int>(
      selector: (_, controller) => controller.count * 2,
      builder: (context, doubled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selector 读到的双倍 $doubled'),
            const RebuildProbe(label: '双倍'),
          ],
        );
      },
    );
  }
}

class _CounterButtons extends StatelessWidget {
  const _CounterButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(
          onPressed: () => context.read<CounterController>().increment(),
          child: const Text('加一'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => context.read<CounterController>().decrement(),
          child: const Text('减一'),
        ),
      ],
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, theme, _) {
        return Row(
          children: [
            const Text('暗色'),
            Switch(
              value: theme.mode == ThemeMode.dark,
              onChanged: (_) => theme.toggle(),
            ),
          ],
        );
      },
    );
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(text: '搜索在控制器里防抖。切换筛选时，未完成数量没变，就不会重建那一块。'),
        const _Remaining(),
        QueryField(
          onChanged: (value) => context.read<TodoController>().setQuery(value),
        ),
        const _Filter(),
        TitleField(
          onSubmit: (title) => context.read<TodoController>().add(title),
        ),
        const _TodoList(),
      ],
    );
  }
}

class _Remaining extends StatelessWidget {
  const _Remaining();

  @override
  Widget build(BuildContext context) {
    return Selector<TodoController, int>(
      selector: (_, controller) => controller.remaining,
      builder: (context, remaining, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('未完成 $remaining'),
            const RebuildProbe(label: '未完成计数'),
          ],
        );
      },
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter();

  @override
  Widget build(BuildContext context) {
    final filter = context.select<TodoController, TodoFilter>((c) => c.filter);
    return FilterChips(
      filter: filter,
      onChanged: (value) => context.read<TodoController>().setFilter(value),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList();

  @override
  Widget build(BuildContext context) {
    return Selector<TodoController, TodoView>(
      selector: (_, controller) =>
          TodoView(controller.todos, controller.filter, controller.query),
      builder: (context, view, _) {
        final todos = view.visible;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RebuildProbe(label: '待办列表'),
            if (todos.isEmpty) const Text('没有符合条件的待办'),
            for (final todo in todos)
              TodoTile(
                todo: todo,
                onToggle: () => context.read<TodoController>().toggle(todo.id),
                onRemove: () => context.read<TodoController>().remove(todo.id),
              ),
          ],
        );
      },
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    return PageBody(
      children: [
        const Note(
          text: '目录的 loading、error、data 都放在一个 ChangeNotifier 里。Provider 不会替你生成这三种状态。',
        ),
        Row(
          children: [
            const Text('下次请求失败'),
            Switch(
              value: catalog.failNext,
              onChanged: catalog.loading ? null : catalog.setFailNext,
            ),
            const Spacer(),
            FilledButton(
              onPressed: catalog.loading
                  ? null
                  : () => unawaited(catalog.load()),
              child: const Text('重新加载'),
            ),
          ],
        ),
        if (catalog.loading) const LinearProgressIndicator(),
        if (catalog.error != null) Text(catalog.error!),
        for (final product in catalog.products)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(product.name),
            subtitle: Text(product.priceLabel),
          ),
      ],
    );
  }
}

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final cart = context.watch<CartController>();
    final products = context.select<CatalogController, List<Product>>(
      (c) => c.products,
    );
    return PageBody(
      children: [
        const Note(
          text: 'CatalogApi 和 AuthApi 用普通 Provider 注入。CartController 由 ChangeNotifierProxyProvider 接在会话后面，登出时清空。',
        ),
        if (session.session == null)
          LoginForm(
            busy: session.busy,
            error: session.error,
            onSubmit: (email, password) =>
                unawaited(session.login(email, password)),
          )
        else ...[
          Text('你好，${session.session!.name}'),
          OutlinedButton(onPressed: session.logout, child: const Text('登出')),
        ],
        Text('购物车 ${cart.count} 件，合计 ${centsLabel(cart.totalCents)}'),
        for (final product in products)
          ProductTile(
            product: product,
            quantity: cart.lines[product.id] ?? 0,
            enabled: cart.signedIn,
            onAdd: () => cart.add(product.id),
          ),
        if (!cart.signedIn) const Note(text: '登录后才能把商品放进购物车。'),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => DraftCounter(),
          child: const DraftPage(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '临时计数器创建在路由里。路由弹出后，Provider 会 dispose 它。这里的次数来自 DraftCounter.dispose。',
        ),
        Text('已经释放 ${DraftCounter.disposedCount} 次'),
        FilledButton(onPressed: _open, child: const Text('进入临时页')),
      ],
    );
  }
}

class DraftPage extends StatelessWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DraftListener(
      child: Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              Note(
                text: '数到 5 时，页面上的 listener 会弹出 SnackBar。这个监听挂在 State 上，并在 dispose 时摘掉。',
              ),
              _DraftCount(),
              _DraftButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftListener extends StatefulWidget {
  const _DraftListener({required this.child});

  final Widget child;

  @override
  State<_DraftListener> createState() => _DraftListenerState();
}

class _DraftListenerState extends State<_DraftListener> {
  DraftCounter? _counter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<DraftCounter>();
    if (!identical(next, _counter)) {
      _counter?.removeListener(_onCount);
      _counter = next..addListener(_onCount);
    }
  }

  void _onCount() {
    if (_counter?.count == 5 && mounted) {
      showLabSnackBar(context, '临时计数到了 5');
    }
  }

  @override
  void dispose() {
    _counter?.removeListener(_onCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DraftCount extends StatelessWidget {
  const _DraftCount();

  @override
  Widget build(BuildContext context) {
    final count = context.select<DraftCounter, int>((c) => c.count);
    return Text(
      '临时计数 $count',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _DraftButton extends StatelessWidget {
  const _DraftButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.read<DraftCounter>().increment(),
      child: const Text('加一'),
    );
  }
}
