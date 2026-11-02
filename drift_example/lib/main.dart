import 'package:drift_example/database/app_database.dart';
import 'package:drift_example/repositories/todo_repository.dart';
import 'package:flutter/material.dart';

late final TodoRepository todoRepository;

Future<void> main() async {
  // Drift 要先拿到应用支持目录，用来放数据库文件。
  WidgetsFlutterBinding.ensureInitialized();

  todoRepository = TodoRepository(AppDatabase());
  await todoRepository.seedIfEmpty();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drift',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _titleController = TextEditingController();

  /// `watchTodos` 在表变化时再次发出，所以列表不用手动 setState。
  late final Stream<List<TodoListEntry>> _todos = todoRepository.watchTodos();

  List<TodoCategory> _categories = [];
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await todoRepository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _categoryId ??= categories.isEmpty ? null : categories.first.id;
    });
  }

  Future<void> _addTodo() async {
    final title = _titleController.text.trim();
    final categoryId = _categoryId;
    if (title.isEmpty || categoryId == null) return;

    try {
      await todoRepository.addTodo(title: title, categoryId: categoryId);
      _titleController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('没有保存：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drift')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('input'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '输入新任务',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 112,
                  child: DropdownButton<int>(
                    key: const Key('category'),
                    isExpanded: true,
                    value: _categoryId,
                    hint: const Text('分类'),
                    items: [
                      for (final category in _categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '选择分类后回车，或点加号添加',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TodoListEntry>>(
              stream: _todos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('读取失败：${snapshot.error}'));
                }
                final todos = snapshot.data;
                if (todos == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (todos.isEmpty) {
                  return const Center(child: Text('还没有任务'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: todos.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = todos[index];
                    final item = entry.item;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  key: Key('list_item_$index'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isCompleted
                                        ? Colors.black45
                                        : null,
                                  ),
                                ),
                                if (item.content != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.content!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.category.name}  ·  id ${item.id}  ·  ${_formatCreatedAt(item.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: item.isCompleted,
                            onChanged: (value) {
                              todoRepository.setCompleted(item.id, value);
                            },
                          ),
                          IconButton(
                            onPressed: () => todoRepository.deleteTodo(item.id),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('submit'),
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _formatCreatedAt(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}
