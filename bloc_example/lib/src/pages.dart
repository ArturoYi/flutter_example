import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      unawaited(context.read<CatalogCubit>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Bloc / Cubit',
      clock: BlocBuilder<ClockCubit, DateTime>(
        builder: (context, time) => Text(formatTime(time)),
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
          version: 'bloc 9.2.1 / flutter_bloc 9.1.1',
          summary: 'Cubit 直接暴露方法并 emit 新状态。Bloc 先接收事件，再在事件处理函数里决定状态。两者都要求新状态和旧状态用 == 比较。',
          strengths: [
            '事件到状态的方向固定，BlocObserver 能看到每一次变化。',
            'Cubit 适合计数、主题、请求这种直接动作；Bloc 适合待办这种想留下事件、还要处理并发的流程。',
            'BlocBuilder、BlocSelector、BlocListener、BlocConsumer 把重建和副作用分开。',
            'bloc_concurrency 的 restartable 可以取消过期的搜索请求。',
            'RepositoryProvider 负责注入 API，BlocProvider 负责创建和 close。',
          ],
          weaknesses: [
            'Bloc 的事件类比直接改状态啰嗦，小功能会显得重。',
            '状态类必须正确实现 ==。漏写时该跳过的刷新不会跳过，写错时该刷新的界面会卡住。',
            'loading 和 error 仍然要自己放进状态，没有 Riverpod 那种现成的 AsyncValue。',
            '一个功能常常拆成 event、state、bloc 三个类型，文件会变多。',
          ],
          scenarios: [
            'Cubit：计数、主题、时钟、目录、登录、购物车、临时页。',
            'Bloc：待办的添加、勾选、删除、筛选和搜索。',
            '搜索事件使用 restartable，连续输入只会留下最后一次。',
            'BlocSelector 分开刷新未完成数量和列表。',
            'BlocListener 在登出时清空购物车，BlocConsumer 在临时页弹 SnackBar。',
            'RepositoryProvider 注入 API，路由上的 BlocProvider 在弹出时 close。',
            'LabBlocObserver 把除时钟以外的状态变化打到调试控制台。',
          ],
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
        const Note(text: '骨架不读 Cubit。加减调用的是 context.read，不会让这一页的 build 再跑一遍。'),
        const RebuildProbe(label: '刷新页骨架'),
        BlocSelector<CounterCubit, int, int>(
          selector: (count) => count,
          builder: (context, count) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '计数 $count',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const RebuildProbe(label: '已订阅的计数'),
              ],
            );
          },
        ),
        BlocSelector<CounterCubit, int, int>(
          selector: (count) => count * 2,
          builder: (context, doubled) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('双倍 $doubled'),
                const RebuildProbe(label: '双倍'),
              ],
            );
          },
        ),
        Row(
          children: [
            FilledButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: const Text('加一'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.read<CounterCubit>().decrement(),
              child: const Text('减一'),
            ),
          ],
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return Row(
              children: [
                const Text('暗色'),
                Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (_) => context.read<ThemeCubit>().toggle(),
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
          text: '筛选只改 filter。未完成数量没变时，BlocSelector 不会重建那一块。搜索事件被 restartable 取消前一次延时。',
        ),
        BlocSelector<TodoBloc, TodoState, int>(
          selector: (state) => state.remaining,
          builder: (context, remaining) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('未完成 $remaining'),
                const RebuildProbe(label: '未完成计数'),
              ],
            );
          },
        ),
        QueryField(
          onChanged: (value) =>
              context.read<TodoBloc>().add(TodoQueryChanged(value)),
        ),
        BlocSelector<TodoBloc, TodoState, TodoFilter>(
          selector: (state) => state.filter,
          builder: (context, filter) {
            return FilterChips(
              filter: filter,
              onChanged: (value) =>
                  context.read<TodoBloc>().add(TodoFilterChanged(value)),
            );
          },
        ),
        TitleField(
          onSubmit: (title) => context.read<TodoBloc>().add(TodoAdded(title)),
        ),
        BlocSelector<TodoBloc, TodoState, (List<Todo>, TodoFilter, String)>(
          selector: (state) => (state.todos, state.filter, state.query),
          builder: (context, selected) {
            final todos = visibleTodos(selected.$1, selected.$2, selected.$3);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RebuildProbe(label: '待办列表'),
                if (todos.isEmpty) const Text('没有符合条件的待办'),
                for (final todo in todos)
                  TodoTile(
                    todo: todo,
                    onToggle: () =>
                        context.read<TodoBloc>().add(TodoToggled(todo.id)),
                    onRemove: () =>
                        context.read<TodoBloc>().add(TodoRemoved(todo.id)),
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
        const Note(
          text: '目录是 Cubit。状态里同时放着列表、loading、error 和失败开关。API 来自 RepositoryProvider。',
        ),
        BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('下次请求失败'),
                    Switch(
                      value: state.failNext,
                      onChanged: state.loading
                          ? null
                          : (value) =>
                                context.read<CatalogCubit>().setFailNext(value),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: state.loading
                          ? null
                          : () => context.read<CatalogCubit>().load(),
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
                if (state.loading) const LinearProgressIndicator(),
                if (state.error != null) Text(state.error!),
                for (final product in state.products)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: Text(product.priceLabel),
                  ),
              ],
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
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, next) =>
          previous.session != null && next.session == null,
      listener: (context, state) => context.read<CartCubit>().clear(),
      child: PageBody(
        children: [
          const Note(text: '登出本身只清会话。BlocListener 听到会话消失后，再让购物车 Cubit 清空。'),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) {
              if (auth.session == null) {
                return LoginForm(
                  busy: auth.busy,
                  error: auth.error,
                  onSubmit: (email, password) {
                    unawaited(context.read<AuthCubit>().login(email, password));
                  },
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('你好，${auth.session!.name}'),
                  OutlinedButton(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    child: const Text('登出'),
                  ),
                ],
              );
            },
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              final signedIn = context.select<AuthCubit, bool>(
                (cubit) => cubit.state.session != null,
              );
              final products = context.select<CatalogCubit, List<Product>>(
                (cubit) => cubit.state.products,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('购物车 ${cart.count} 件，合计 ${centsLabel(cart.totalCents)}'),
                  for (final product in products)
                    ProductTile(
                      product: product,
                      quantity: cart.lines[product.id] ?? 0,
                      enabled: signedIn,
                      onAdd: () => context.read<CartCubit>().add(product.id),
                    ),
                  if (!signedIn) const Note(text: '登录后才能把商品放进购物车。'),
                ],
              );
            },
          ),
        ],
      ),
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
        builder: (_) =>
            BlocProvider(create: (_) => DraftCubit(), child: const DraftPage()),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '临时 Cubit 建在路由的 BlocProvider 里。路由弹出时 BlocProvider 会 close 它。',
        ),
        Text('已经释放 ${DraftCubit.closedCount} 次'),
        FilledButton(onPressed: _open, child: const Text('进入临时页')),
      ],
    );
  }
}

class DraftPage extends StatelessWidget {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('临时计数')),
      body: PageBody(
        children: [
          const Note(
            text: 'BlocConsumer 同时负责显示数字和在变成 5 时弹 SnackBar。listenWhen 保证只在进入 5 时触发。',
          ),
          BlocConsumer<DraftCubit, int>(
            listenWhen: (previous, next) => next == 5 && previous != 5,
            listener: (context, state) => showLabSnackBar(context, '临时计数到了 5'),
            builder: (context, count) {
              return Text(
                '临时计数 $count',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),
          FilledButton(
            onPressed: () => context.read<DraftCubit>().increment(),
            child: const Text('加一'),
          ),
        ],
      ),
    );
  }
}
