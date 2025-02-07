import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox.g.dart';
import 'package:objectbox_example/objectbox/database_manager.dart';

class TaskRepository {
  final DatabaseManager _databaseManager;

  TaskRepository(this._databaseManager);

  // 创建任务
  int addTask(Task task) => _databaseManager.box<Task>().put(task);

  // 批量创建任务
  List<int> addTasks(List<Task> tasks) =>
      _databaseManager.box<Task>().putMany(tasks);

  // 获取所有任务
  List<Task> getAllTasks() => _databaseManager.box<Task>().getAll();

  // 根据ID获取任务
  Task? getTask(int id) => _databaseManager.box<Task>().get(id);

  // 更新任务
  int updateTask(Task task) => _databaseManager.box<Task>().put(task);

  // 删除任务
  bool deleteTask(int id) => _databaseManager.box<Task>().remove(id);

  // 删除所有任务
  int deleteAllTasks() => _databaseManager.box<Task>().removeAll();

  // 获取未完成的任务
  List<Task> getIncompleteTasks() {
    final query = _databaseManager
        .box<Task>()
        .query(Task_.isCompleted.equals(false))
        .build();
    return query.find();
  }

  // 获取已完成的任务
  List<Task> getCompletedTasks() {
    final query = _databaseManager
        .box<Task>()
        .query(Task_.isCompleted.equals(true))
        .build();
    return query.find();
  }

  // 在事务中执行批量操作
  Future<void> executeInTransaction(TxMode mode, void Function() action) async {
    await _databaseManager.transaction(mode, action);
  }
}
