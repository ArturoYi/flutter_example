import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      title: 'GetX',
      clock: Obx(() => Text(formatTime(Get.find<ClockService>().now.value))),
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
          version: 'get 4.7.3',
          summary: 'GetX 把响应式状态、依赖注入、路由和 SnackBar 放在一起。稳定版目前是 4.7.3，5.0 仍是预发布版本，这个示例不使用预发布版。',
          strengths: [
            '不需要 BuildContext 就能拿到控制器、打开页面和弹出提示。',
            '.obs 加 Obx 会按读到的响应式变量刷新；GetBuilder 则由 update 手动决定刷新哪一块。',
            'Get.put、Get.lazyPut、Get.create、permanent 和路由 Bindings 覆盖不同的生命周期。',
            'ever、once、debounce、interval 这些 Worker 用来做监听、只跑一次和防抖。',
            '路由 binding 里注册的控制器会在页面弹出时 onClose。',
          ],
          weaknesses: [
            '服务定位器是全局的，依赖关系不写在类型和 widget 树上，读代码时要自己追 Get.find。',
            '约定多，静态分析能帮的忙比 Riverpod、Bloc 少。',
            '业务容易写进巨大的 GetxController，并且到处查找同一个实例。',
            '路由、弹窗和 Flutter 官方 Navigator 的习惯不同，测试时通常要打开 Get.testMode。',
            '刷新范围取决于你有没有在 Obx 里读到那个 .obs。漏读不会报编译错误，只会整块不刷新或抛运行时错误。',
          ],
          scenarios: [
            'GetMaterialApp、Get.to、Get.snackbar。',
            'Obx 响应式计数，以及 GetBuilder 按 id 刷新。',
            'Get.put、Get.lazyPut、GetxService permanent。',
            'debounce 做搜索，ever 在登出时清购物车，once 在第一次加购时提示。',
            'GetView 和路由 Bindings。',
            '页面控制器 onClose。',
          ],
        ),
        Note(
          text: '待办控制器是 lazyPut：第一次被 Get.find 时才创建。时钟是 permanent 的 GetxService，不会跟着普通页面释放。',
        ),
      ],
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = Get.find<CounterController>();
    final manual = Get.find<ManualCounterController>();
    final theme = Get.find<ThemeController>();
    return PageBody(
      children: [
        const Note(
          text:
              'Obx 只重建读到 .obs 的那一块。下面的 GetBuilder 只有 id 为 count 的会跟着 update 走。',
        ),
        const RebuildProbe(label: '刷新页骨架'),
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obx 计数 ${counter.count.value}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const RebuildProbe(label: 'Obx 计数'),
            ],
          );
        }),
        GetBuilder<ManualCounterController>(
          id: 'count',
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GetBuilder 计数 ${controller.count}'),
                const RebuildProbe(label: 'GetBuilder 指定 id'),
              ],
            );
          },
        ),
        GetBuilder<ManualCounterController>(
          id: 'other',
          builder: (_) => const RebuildProbe(label: 'GetBuilder 其他 id'),
        ),
        Row(
          children: [
            FilledButton(
              onPressed: counter.increment,
              child: const Text('响应式加一'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: counter.decrement,
              child: const Text('减一'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: manual.increment,
              child: const Text('手动加一'),
            ),
          ],
        ),
        Obx(() {
          return Row(
            children: [
              const Text('暗色'),
              Switch(
                value: theme.mode.value == ThemeMode.dark,
                onChanged: (_) => theme.toggle(),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class TodoPage extends GetView<TodoController> {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(
          text: '输入框写的是 input。debounce Worker 在 300ms 后把它抄到 query，列表只读 query。',
        ),
        Obx(() {
          final remaining = controller.todos.where((todo) => !todo.done).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('未完成 $remaining'),
              const RebuildProbe(label: '未完成计数'),
            ],
          );
        }),
        QueryField(onChanged: (value) => controller.input.value = value),
        Obx(
          () => FilterChips(
            filter: controller.filter.value,
            onChanged: controller.setFilter,
          ),
        ),
        TitleField(onSubmit: controller.add),
        Obx(() {
          final todos = controller.visible;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RebuildProbe(label: '待办列表'),
              if (todos.isEmpty) const Text('没有符合条件的待办'),
              for (final todo in todos)
                TodoTile(
                  todo: todo,
                  onToggle: () => controller.toggle(todo.id),
                  onRemove: () => controller.remove(todo.id),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class CatalogPage extends GetView<CatalogController> {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(text: '目录在控制器 onInit 里请求。loading、error 和列表都是各自的 .obs。'),
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('下次请求失败'),
                  Switch(
                    value: controller.failNext.value,
                    onChanged: controller.loading.value
                        ? null
                        : (value) => controller.failNext.value = value,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: controller.loading.value
                        ? null
                        : controller.load,
                    child: const Text('重新加载'),
                  ),
                ],
              ),
              if (controller.loading.value) const LinearProgressIndicator(),
              if (controller.error.value != null) Text(controller.error.value!),
              for (final product in controller.products)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text(product.priceLabel),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final cart = Get.find<CartController>();
    final catalog = Get.find<CatalogController>();
    return PageBody(
      children: [
        const Note(text: '购物车用 ever 听会话。会话变成 null 就清空。第一次放入商品时，once 弹出提示。'),
        Obx(() {
          final session = auth.session.value;
          if (session == null) {
            return LoginForm(
              busy: auth.busy.value,
              error: auth.error.value,
              onSubmit: auth.login,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你好，${session.name}'),
              OutlinedButton(onPressed: auth.logout, child: const Text('登出')),
            ],
          );
        }),
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('购物车 ${cart.count} 件，合计 ${centsLabel(cart.totalCents)}'),
              for (final product in catalog.products)
                ProductTile(
                  product: product,
                  quantity: cart.lines[product.id] ?? 0,
                  enabled: auth.session.value != null,
                  onAdd: () => cart.add(product.id),
                ),
              if (auth.session.value == null)
                const Note(text: '登录后才能把商品放进购物车。'),
            ],
          );
        }),
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
    await Get.to(
      () => const DraftPage(),
      binding: BindingsBuilder(() {
        Get.put(DraftCounterController());
      }),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const Note(text: '临时页的控制器由路由 Bindings 注册。页面弹出后 GetX 调用 onClose，计数会增加。'),
        Text('已经释放 ${DraftCounterController.closedCount} 次'),
        FilledButton(onPressed: _open, child: const Text('进入临时页')),
      ],
    );
  }
}

class DraftPage extends GetView<DraftCounterController> {
  const DraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('临时计数')),
      body: PageBody(
        children: [
          const Note(text: 'ever 在计数变成 5 时调用 Get.snackbar，不需要 BuildContext。'),
          Obx(() {
            return Text(
              '临时计数 ${controller.count.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            );
          }),
          FilledButton(
            onPressed: controller.increment,
            child: const Text('加一'),
          ),
        ],
      ),
    );
  }
}
