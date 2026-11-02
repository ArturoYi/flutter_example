import 'dart:async';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';

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
      unawaited(_loadCatalog());
    });
  }

  Future<void> _loadCatalog() async {
    await context.dispatch(LoadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Async Redux',
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
    final time = context.select((AppState state) => state.now);
    return Text(formatTime(time));
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const BriefView(
          version: 'async_redux 29.2.3',
          summary: 'pub.dev 上的 redux 5.0.0、flutter_redux 0.10.0 和 redux_thunk 0.4.0 都把 SDK 限制在 Dart 3 之前，当前 Flutter 无法解析。这个示例用仍在维护的 Async Redux，它保留了单一状态树、动作和 reducer，并补上了异步动作。',
          strengths: [
            '整个应用一份不可变状态，变化只来自动作，流程好追踪。',
            'reduce 可以是同步的，也可以直接返回 Future，不必再接 thunk 中间件。',
            'context.select 用深度相等比较选中的值，新的列表如果内容和原来一样，不会重建。',
            'isWaiting、isFailed、UserException 和 UserExceptionDialog 处理请求中的等待和错误。',
            'Evt 是一次性事件，适合 SnackBar，不会在下次重建时再弹出。',
            'ActionObserver 可以做动作日志，而不必把日志写进状态。',
          ],
          weaknesses: [
            '经典 redux 包没有 Dart 3 版本。要看原版 Store、Reducer 和 Middleware，只能读旧文档。',
            '状态默认是全局的。离开页面不会销毁草稿，必须自己派发 ResetDraft。',
            '状态类和 copyWith 会随着功能变大。',
            'isWaiting 会在任意状态变化时重建调用它的组件，时钟每秒都会碰到它。',
            'reducer 应保持纯净。搜索防抖这种计时不能写进 reducer，这个示例放在页面里。',
          ],
          scenarios: [
            'Store、不可变 AppState、同步动作和异步动作。',
            'context.select 只订阅计数、列表或时钟。',
            'NonReentrant 避免目录和登录重复进入。',
            'UserException 加 UserExceptionDialog。',
            'environment 注入 CatalogApi 和 AuthApi。',
            '登出动作在同一个 reducer 里清会话和购物车。',
            'Evt 触发临时页 SnackBar。',
            'ActionObserver 记录最近的动作，并跳过每秒一次的 TickClock。',
          ],
        ),
        const Note(text: '最近的动作：'),
        ValueListenableBuilder<List<String>>(
          valueListenable: actionLog.entries,
          builder: (context, entries, _) {
            if (entries.isEmpty) return const Text('还没有动作');
            return Text(entries.join('\n'));
          },
        ),
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
        const Note(text: '这一页不 select 任何字段。点按钮只 dispatch，骨架不会重建。'),
        const RebuildProbe(label: '刷新页骨架'),
        const _CountText(),
        const _DoubledText(),
        Row(
          children: [
            FilledButton(
              onPressed: () => context.dispatch(IncrementCount()),
              child: const Text('加一'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.dispatch(DecrementCount()),
              child: const Text('减一'),
            ),
          ],
        ),
        const _ThemeSwitch(),
      ],
    );
  }
}

class _CountText extends StatelessWidget {
  const _CountText();

  @override
  Widget build(BuildContext context) {
    final count = context.select((AppState state) => state.count);
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
    final doubled = context.select((AppState state) => state.count * 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('双倍 $doubled'),
        const RebuildProbe(label: '双倍'),
      ],
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context) {
    final mode = context.select((AppState state) => state.themeMode);
    return Row(
      children: [
        const Text('暗色'),
        Switch(
          value: mode == ThemeMode.dark,
          onChanged: (_) => context.dispatch(ToggleTheme()),
        ),
      ],
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.dispatch(SetQuery(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(text: '防抖计时放在页面里。SetQuery 的 reducer 只负责把已经稳定的字符串写进状态。'),
        const _Remaining(),
        QueryField(onChanged: _onQuery),
        const _Filter(),
        TitleField(onSubmit: (title) => context.dispatch(AddTodo(title))),
        const _TodoList(),
      ],
    );
  }
}

class _Remaining extends StatelessWidget {
  const _Remaining();

  @override
  Widget build(BuildContext context) {
    final remaining = context.select((AppState state) => state.remaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('未完成 $remaining'),
        const RebuildProbe(label: '未完成计数'),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter();

  @override
  Widget build(BuildContext context) {
    final filter = context.select((AppState state) => state.filter);
    return FilterChips(
      filter: filter,
      onChanged: (value) => context.dispatch(SetFilter(value)),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList();

  @override
  Widget build(BuildContext context) {
    final todos = context.select((AppState state) => state.visible);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RebuildProbe(label: '待办列表'),
        if (todos.isEmpty) const Text('没有符合条件的待办'),
        for (final todo in todos)
          TodoTile(
            todo: todo,
            onToggle: () => context.dispatch(ToggleTodo(todo.id)),
            onRemove: () => context.dispatch(RemoveTodo(todo.id)),
          ),
      ],
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      children: [
        Note(
          text: '下面的请求状态使用了 isWaiting。它会跟着每一次 store 变化重建，所以时钟每秒都会让它的构建次数加一。商品列表只 select 商品，不会跟着加。',
        ),
        _CatalogStatus(),
        _CatalogList(),
      ],
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus();

  @override
  Widget build(BuildContext context) {
    final waiting = context.isWaiting(LoadCatalog);
    final message = context.exceptionFor(LoadCatalog)?.message;
    final failNext = context.select((AppState state) => state.catalogFailNext);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RebuildProbe(label: '请求状态'),
        Row(
          children: [
            const Text('下次请求失败'),
            Switch(
              value: failNext,
              onChanged: waiting
                  ? null
                  : (value) => context.dispatch(SetCatalogFail(value)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: waiting
                  ? null
                  : () {
                      context.clearExceptionFor(LoadCatalog);
                      context.dispatch(LoadCatalog());
                    },
              child: const Text('重新加载'),
            ),
          ],
        ),
        if (waiting) const LinearProgressIndicator(),
        if (message != null) Text(message),
      ],
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList();

  @override
  Widget build(BuildContext context) {
    final products = context.select((AppState state) => state.products);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RebuildProbe(label: '商品列表'),
        for (final product in products)
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
    return const PageBody(
      children: [
        Note(text: 'Logout 在同一个 reducer 里把 session 设为 null，并把 cart 换成空 map。'),
        _LoginPanel(),
        _CartSummary(),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel();

  @override
  Widget build(BuildContext context) {
    final session = context.select((AppState state) => state.session);
    final waiting = context.isWaiting(Login);
    final message = context.exceptionFor(Login)?.message;
    if (session == null) {
      return LoginForm(
        busy: waiting,
        error: message,
        onSubmit: (email, password) {
          context.clearExceptionFor(Login);
          context.dispatch(Login(email, password));
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你好，${session.name}'),
        OutlinedButton(
          onPressed: () => context.dispatch(Logout()),
          child: const Text('登出'),
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((AppState state) => state.session != null);
    final count = context.select((AppState state) => cartCount(state.cart));
    final total = context.select(
      (AppState state) => cartTotalCents(state.cart),
    );
    final products = context.select((AppState state) => state.products);
    final quantities = context.select((AppState state) => state.cart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('购物车 $count 件，合计 ${centsLabel(total)}'),
        for (final product in products)
          ProductTile(
            product: product,
            quantity: quantities[product.id] ?? 0,
            enabled: signedIn,
            onAdd: () => context.dispatch(AddToCart(product.id)),
          ),
        if (!signedIn) const Note(text: '登录后才能把商品放进购物车。'),
      ],
    );
  }
}

class ScopePage extends StatelessWidget {
  const ScopePage({super.key});

  @override
  Widget build(BuildContext context) {
    final draftCount = context.select((AppState state) => state.draftCount);
    return PageBody(
      children: [
        const Note(
          text: '草稿放在全局 AppState 里。离开页面后数字还在。再次进入时才派发 ResetDraft，把它置回 0。',
        ),
        Text('全局里的临时计数现在是 $draftCount'),
        FilledButton(
          onPressed: () {
            context.dispatch(ResetDraft());
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DraftPage()));
          },
          child: const Text('进入并重置'),
        ),
      ],
    );
  }
}

class DraftPage extends StatelessWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select((AppState state) => state.draftCount);
    final message = context.takeEvent((AppState state) => state.notice);
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showLabSnackBar(context, message);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('临时计数')),
      body: PageBody(
        children: [
          const Note(
            text:
                '数到 5 时 reducer 写入一个新的 Evt。takeEvent 把它消费掉，所以 SnackBar 只出现一次。',
          ),
          Text(
            '临时计数 $count',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          FilledButton(
            onPressed: () => context.dispatch(IncrementDraft()),
            child: const Text('加一'),
          ),
        ],
      ),
    );
  }
}
