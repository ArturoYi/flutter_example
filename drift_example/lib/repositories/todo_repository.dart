import 'package:drift/drift.dart';
import 'package:drift_example/database/app_database.dart';

/// 一条列表数据：待办行，以及 JOIN 出来的分类。
class TodoListEntry {
  const TodoListEntry({required this.item, required this.category});

  final TodoItem item;
  final TodoCategory category;
}

/// 待办的增删改查。
///
/// 界面只依赖这个类，不直接拼查询。表结构仍然看 [AppDatabase]。
class TodoRepository {
  TodoRepository(this._db);

  final AppDatabase _db;

  /// 数据库还没有待办时，写入三行示例。
  ///
  /// [AppDatabase.transaction] 的回调里继续用 `_db`。
  /// Drift 会把这些调用收进同一个事务：回调正常结束就提交，抛异常就整段回滚。
  Future<void> seedIfEmpty() async {
    final existing = await _db.select(_db.todoItems).get();
    if (existing.isNotEmpty) return;

    await _db.transaction(() async {
      final workId = await _addCategory('工作');
      final lifeId = await _addCategory('生活');
      final studyId = await _addCategory('学习');

      await addTodo(
        title: '输入标题后回车，或点加号添加任务',
        categoryId: workId,
        content: '列表按创建时间倒序',
        createdAt: DateTime(2026, 1, 1, 9),
      );
      await addTodo(
        title: '用开关切换完成状态',
        categoryId: lifeId,
        isCompleted: true,
        createdAt: DateTime(2026, 1, 1, 10),
      );
      await addTodo(
        title: '点删除图标移除任务',
        categoryId: studyId,
        createdAt: DateTime(2026, 1, 1, 11),
      );
    });
  }

  Future<int> _addCategory(String name) {
    return _db
        .into(_db.todoCategories)
        .insert(TodoCategoriesCompanion.insert(name: name));
  }

  /// 插入一条待办，返回新行的 id。
  ///
  /// 这里用 Companion，而不是直接构造 [TodoItem]。
  /// Companion 的每个字段都是 [Value]：没写的字段用列上的默认值。
  /// [Value.absent] 表示这次不写；`Value(null)` 才会把可空列写成 NULL。
  Future<int> addTodo({
    required String title,
    required int categoryId,
    String? content,
    bool isCompleted = false,
    DateTime? createdAt,
  }) {
    return _db
        .into(_db.todoItems)
        .insert(
          TodoItemsCompanion.insert(
            title: title,
            categoryId: categoryId,
            content: Value(content),
            isCompleted: Value(isCompleted),
            createdAt: createdAt == null
                ? const Value.absent()
                : Value(createdAt),
          ),
        );
  }

  Future<List<TodoCategory>> getCategories() {
    final query = _db.select(_db.todoCategories)
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    return query.get();
  }

  Future<List<TodoListEntry>> getTodos() => watchTodos().first;

  /// 先发出当前结果，之后表里的相关数据变化时再发。
  ///
  /// `watch` 会占用这条查询，直到调用方取消监听。
  /// 界面上的 [StreamBuilder] 销毁时会取消，查询随之关掉。
  Stream<List<TodoListEntry>> watchTodos() {
    final query =
        _db.select(_db.todoItems).join([
          innerJoin(
            _db.todoCategories,
            _db.todoCategories.id.equalsExp(_db.todoItems.categoryId),
          ),
        ])..orderBy([
          OrderingTerm.desc(_db.todoItems.createdAt),
          OrderingTerm.desc(_db.todoItems.id),
        ]);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          TodoListEntry(
            item: row.readTable(_db.todoItems),
            category: row.readTable(_db.todoCategories),
          ),
      ];
    });
  }

  /// 只更新完成状态。
  ///
  /// Companion 里没有出现的列保持原值。这次不会改标题，也不会改创建时间。
  Future<int> setCompleted(int id, bool isCompleted) {
    final statement = _db.update(_db.todoItems)
      ..where((row) => row.id.equals(id));
    return statement.write(TodoItemsCompanion(isCompleted: Value(isCompleted)));
  }

  Future<int> deleteTodo(int id) {
    final statement = _db.delete(_db.todoItems)
      ..where((row) => row.id.equals(id));
    return statement.go();
  }

  var _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _db.close();
  }
}
