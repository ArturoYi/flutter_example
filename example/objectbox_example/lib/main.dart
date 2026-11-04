import 'package:flutter/material.dart';
import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox/database_manager.dart';
import 'package:objectbox_example/repositories/task_repository.dart';

late final TaskRepository taskRepository;

Future<void> main() async {
  // ObjectBox 需要先拿到应用文档目录。
  WidgetsFlutterBinding.ensureInitialized();

  final databaseManager = await DatabaseManager.create();
  taskRepository = TaskRepository(databaseManager);
  await taskRepository.seedIfEmpty();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObjectBox',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const TestObjectBoxWidget(),
    );
  }
}

class TestObjectBoxWidget extends StatefulWidget {
  const TestObjectBoxWidget({super.key});

  @override
  State<TestObjectBoxWidget> createState() => _TestObjectBoxWidgetState();
}

class _TestObjectBoxWidgetState extends State<TestObjectBoxWidget> {
  final _titleController = TextEditingController();
  late final Stream<List<Task>> _tasks = taskRepository.watchAllTasks();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await taskRepository.addTask(Task(title: title));
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ObjectBox')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('input'),
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '输入新任务',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTask(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '回车或点加号添加任务',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _tasks,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('读取失败：${snapshot.error}'));
                }
                final tasks = snapshot.data;
                if (tasks == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tasks.isEmpty) {
                  return const Center(child: Text('还没有任务'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: tasks.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = tasks[index];
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
                                    decoration:
                                        item.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                    color:
                                        item.isCompleted
                                            ? Colors.black45
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'id: ${item.id}  ·  ${_formatCreatedAt(item.createdAt)}',
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
                              item.isCompleted = value;
                              taskRepository.updateTask(item);
                            },
                          ),
                          IconButton(
                            onPressed: () => taskRepository.deleteTask(item.id),
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
        onPressed: _addTask,
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
