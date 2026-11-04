import 'package:flutter/material.dart';

enum TodoFilter { all, active, done }

class Todo {
  const Todo({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Todo copyWith({bool? done}) {
    return Todo(id: id, title: title, done: done ?? this.done);
  }

  @override
  bool operator ==(Object other) {
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.done == done;
  }

  @override
  int get hashCode => Object.hash(id, title, done);
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
  });

  final String id;
  final String name;
  final int priceCents;

  String get priceLabel => centsLabel(priceCents);

  @override
  bool operator ==(Object other) {
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.priceCents == priceCents;
  }

  @override
  int get hashCode => Object.hash(id, name, priceCents);
}

class Session {
  const Session({required this.name, required this.email});

  final String name;
  final String email;

  @override
  bool operator ==(Object other) {
    return other is Session && other.name == name && other.email == email;
  }

  @override
  int get hashCode => Object.hash(name, email);
}

const sampleProducts = <Product>[
  Product(id: 'tea', name: '龙井', priceCents: 2800),
  Product(id: 'cup', name: '青瓷杯', priceCents: 4600),
  Product(id: 'book', name: '状态管理笔记', priceCents: 5200),
];

List<Todo> seedTodos() => const [
  Todo(id: 'seed-1', title: '阅读本页的优势和劣势'),
  Todo(id: 'seed-2', title: '试一次局部刷新'),
];

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

String centsLabel(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

String errorText(Object error) {
  const prefix = 'Exception: ';
  final text = error.toString();
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}

String formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

List<Todo> visibleTodos(List<Todo> todos, TodoFilter filter, String query) {
  final keyword = query.trim().toLowerCase();
  return [
    for (final todo in todos)
      if (_matches(todo, filter, keyword)) todo,
  ];
}

bool _matches(Todo todo, TodoFilter filter, String keyword) {
  final matchesQuery =
      keyword.isEmpty || todo.title.toLowerCase().contains(keyword);
  final matchesFilter = switch (filter) {
    TodoFilter.all => true,
    TodoFilter.active => !todo.done,
    TodoFilter.done => todo.done,
  };
  return matchesQuery && matchesFilter;
}

int remainingCount(List<Todo> todos) {
  return todos.where((todo) => !todo.done).length;
}

int cartCount(Map<String, int> lines) {
  return lines.values.fold(0, (sum, quantity) => sum + quantity);
}

int cartTotalCents(Map<String, int> lines) {
  var total = 0;
  for (final entry in lines.entries) {
    final product = sampleProducts
        .where((item) => item.id == entry.key)
        .firstOrNull;
    if (product != null) {
      total += product.priceCents * entry.value;
    }
  }
  return total;
}

class CatalogApi {
  const CatalogApi({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;

  Future<List<Product>> fetch({bool fail = false}) async {
    await Future<void>.delayed(delay);
    if (fail) {
      throw Exception('网络不可用');
    }
    return sampleProducts;
  }
}

class AuthApi {
  const AuthApi({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;

  Future<Session> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final trimmed = email.trim();
    if (!trimmed.contains('@')) {
      throw Exception('邮箱格式不正确');
    }
    if (password.length < 4) {
      throw Exception('密码至少 4 位');
    }
    return Session(name: trimmed.split('@').first, email: trimmed);
  }
}

class RebuildProbe extends StatelessWidget {
  const RebuildProbe({super.key, required this.label});

  final String label;

  static final counts = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final next = (counts[label] ?? 0) + 1;
    counts[label] = next;
    return Text('$label 构建 $next 次');
  }
}

class LabScaffold extends StatelessWidget {
  const LabScaffold({
    super.key,
    required this.title,
    required this.clock,
    required this.index,
    required this.onSelected,
    required this.body,
  });

  final String title;
  final Widget clock;
  final int index;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: clock),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onSelected,
            labelBehavior: compact
                ? NavigationDestinationLabelBehavior.alwaysHide
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                label: '概览',
              ),
              NavigationDestination(icon: Icon(Icons.speed), label: '刷新'),
              NavigationDestination(icon: Icon(Icons.checklist), label: '待办'),
              NavigationDestination(
                icon: Icon(Icons.cloud_outlined),
                label: '异步',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined),
                label: '组合',
              ),
              NavigationDestination(
                icon: Icon(Icons.layers_outlined),
                label: '作用域',
              ),
            ],
          );
        },
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

class Note extends StatelessWidget {
  const Note({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class BriefView extends StatelessWidget {
  const BriefView({
    super.key,
    required this.version,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.scenarios,
  });

  final String version;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> scenarios;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(version, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(summary),
        const SizedBox(height: 16),
        const Text('优势'),
        const SizedBox(height: 4),
        for (final item in strengths) Text('· $item'),
        const SizedBox(height: 12),
        const Text('劣势'),
        const SizedBox(height: 4),
        for (final item in weaknesses) Text('· $item'),
        const SizedBox(height: 12),
        const Text('这个示例覆盖的用法'),
        const SizedBox(height: 4),
        for (final item in scenarios) Text('· $item'),
      ],
    );
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.filter, required this.onChanged});

  final TodoFilter filter;
  final ValueChanged<TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TodoFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: TodoFilter.all, label: Text('全部')),
        ButtonSegment(value: TodoFilter.active, label: Text('未完成')),
        ButtonSegment(value: TodoFilter.done, label: Text('已完成')),
      ],
      selected: {filter},
      onSelectionChanged: (value) => onChanged(value.first),
    );
  }
}

class QueryField extends StatefulWidget {
  const QueryField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<QueryField> createState() => _QueryFieldState();
}

class _QueryFieldState extends State<QueryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: '搜索标题，停止输入 300ms 后过滤',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class TitleField extends StatefulWidget {
  const TitleField({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '新的待办',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _submit, icon: const Icon(Icons.add)),
      ],
    );
  }
}

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onRemove,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(value: todo.done, onChanged: (_) => onToggle()),
      title: Text(
        todo.title,
        style: todo.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.enabled,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text(product.priceLabel),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quantity > 0) Text('×$quantity'),
          IconButton(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  final bool busy;
  final String? error;
  final void Function(String email, String password) onSubmit;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController(text: 'lee@example.com');
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '邮箱',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码，至少 4 位',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: widget.busy ? null : _submit,
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('登录'),
        ),
      ],
    );
  }

  void _submit() => widget.onSubmit(_email.text, _password.text);
}

void showLabSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

ThemeData labTheme(Color seed, Brightness brightness) {
  return ThemeData(colorSchemeSeed: seed, brightness: brightness);
}
