import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox.g.dart';
import 'package:objectbox_example/objectbox/database_manager.dart';

class TaskRepository {
  final DatabaseManager _databaseManager;

  TaskRepository(this._databaseManager);

  Future<void> seedIfEmpty() async {
    final box = _databaseManager.box<Task>();
    if (box.isEmpty()) {
      await box.putManyAsync([
        Task(title: '输入标题后回车，或点加号添加任务'),
        Task(title: '用开关切换完成状态'),
        Task(title: '点删除图标移除任务'),
      ]);
    }
  }

  Future<int> addTask(Task task) => _databaseManager.box<Task>().putAsync(task);

  Future<List<int>> addTasks(List<Task> tasks) =>
      _databaseManager.box<Task>().putManyAsync(tasks);

  List<Task> getAllTasks() => _find();

  Task? getTask(int id) => _databaseManager.box<Task>().get(id);

  Future<int> updateTask(Task task) =>
      _databaseManager.box<Task>().putAsync(task);

  Future<bool> deleteTask(int id) =>
      _databaseManager.box<Task>().removeAsync(id);

  Future<int> deleteAllTasks() => _databaseManager.box<Task>().removeAllAsync();

  List<Task> getIncompleteTasks() =>
      _find(condition: Task_.isCompleted.equals(false));

  List<Task> getCompletedTasks() =>
      _find(condition: Task_.isCompleted.equals(true));

  /// 按创建时间倒序监听全部任务，数据变化后会再次发出。
  Stream<List<Task>> watchAllTasks() {
    final builder = _databaseManager.box<Task>().query().order(
      Task_.createdAt,
      flags: Order.descending,
    );
    return builder.watch(triggerImmediately: true).map((query) => query.find());
  }

  Future<void> executeInTransaction(TxMode mode, void Function() action) async {
    await _databaseManager.transaction(mode, action);
  }

  List<Task> _find({Condition<Task>? condition}) {
    final query =
        _databaseManager
            .box<Task>()
            .query(condition)
            .order(Task_.createdAt, flags: Order.descending)
            .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
