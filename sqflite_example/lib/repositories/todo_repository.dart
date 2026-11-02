import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/database/database_manager.dart';
import 'package:sqflite_example/models/todo.dart';

/// 待办的增删改查。
///
/// sqflite 没有查询监听。这个仓库在自己的写入成功后发一个信号，
/// 再把整张列表读出来。别的进程改了文件时，界面不会自己刷新。
class TodoRepository {
  TodoRepository(this._manager) : _db = _manager.database;

  final DatabaseManager _manager;
  final Database _db;
  final _changes = StreamController<void>.broadcast();

  /// 数据库还没有待办时，写入三行示例。
  ///
  /// 回调里的 [txn] 才是这次事务的执行器。
  /// 事务结束前连接是锁住的，再拿外面的 `_db` 发语句会一直等待。
  /// `batch` 先把插入攒起来，随这次事务一起提交。
  Future<void> seedIfEmpty() async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM ${Todos.table}'),
    );
    if (count != null && count > 0) return;

    await _db.transaction((txn) async {
      final workId = await txn.insert(Categories.table, {
        Categories.name: '工作',
      });
      final lifeId = await txn.insert(Categories.table, {
        Categories.name: '生活',
      });
      final studyId = await txn.insert(Categories.table, {
        Categories.name: '学习',
      });

      final batch = txn.batch();
      void add(
        String title,
        int categoryId,
        DateTime createdAt, {
        String? content,
        bool isCompleted = false,
      }) {
        batch.insert(
          Todos.table,
          Todo(
            title: title,
            content: content,
            categoryId: categoryId,
            isCompleted: isCompleted,
            createdAt: createdAt,
          ).toInsertMap(),
        );
      }

      add(
        '输入标题后回车，或点加号添加任务',
        workId,
        DateTime(2026, 1, 1, 9),
        content: '列表按创建时间倒序',
      );
      add('用开关切换完成状态', lifeId, DateTime(2026, 1, 1, 10), isCompleted: true);
      add('点删除图标移除任务', studyId, DateTime(2026, 1, 1, 11));
      await batch.commit(noResult: true);
    });
    _notify();
  }

  /// 插入一条待办，返回 SQLite 分配的 id。
  ///
  /// `insert` 用 `?` 占位，sqflite 负责绑定参数。
  /// 用户输入只放进参数，不拼进 SQL 文本。
  Future<int> addTodo({
    required String title,
    required int categoryId,
    String? content,
    bool isCompleted = false,
    DateTime? createdAt,
  }) async {
    final id = await _db.insert(
      Todos.table,
      Todo(
        title: title,
        content: content,
        categoryId: categoryId,
        isCompleted: isCompleted,
        createdAt: createdAt ?? DateTime.now(),
      ).toInsertMap(),
    );
    _notify();
    return id;
  }

  Future<List<Category>> getCategories() async {
    final rows = await _db.query(
      Categories.table,
      orderBy: '${Categories.id} ASC',
    );
    return [
      for (final row in rows)
        Category(
          id: row[Categories.id] as int,
          name: row[Categories.name] as String,
        ),
    ];
  }

  Future<Todo?> getTodo(int id) async {
    final rows = await _db.query(
      Todos.table,
      where: '${Todos.id} = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Todo.fromMap(rows.first);
  }

  /// 待办 INNER JOIN 分类。分类名用别名 `category_name`，避免和待办列撞名。
  ///
  /// `orderBy` 不能写 `?` 占位符，所以排序列继续用我们自己的常量。
  Future<List<TodoListEntry>> getTodos() async {
    final rows = await _db.rawQuery('''
SELECT
  ${Todos.table}.${Todos.id} AS ${Todos.id},
  ${Todos.table}.${Todos.title} AS ${Todos.title},
  ${Todos.table}.${Todos.content} AS ${Todos.content},
  ${Todos.table}.${Todos.categoryId} AS ${Todos.categoryId},
  ${Todos.table}.${Todos.isCompleted} AS ${Todos.isCompleted},
  ${Todos.table}.${Todos.createdAt} AS ${Todos.createdAt},
  ${Categories.table}.${Categories.name} AS ${TodoListEntry.categoryNameColumn}
FROM ${Todos.table}
INNER JOIN ${Categories.table}
  ON ${Categories.table}.${Categories.id} = ${Todos.table}.${Todos.categoryId}
ORDER BY ${Todos.table}.${Todos.createdAt} DESC, ${Todos.table}.${Todos.id} DESC
''');
    return [for (final row in rows) TodoListEntry.fromMap(row)];
  }

  /// 每个监听者先拿到当前列表。之后每次写入成功，再查一次。
  ///
  /// 先订阅 [_changes]，再读数据库。写入如果发生在这次读取期间，
  /// 信号还在，读完会再查一次，不会把这次变化丢掉。
  Stream<List<TodoListEntry>> watchTodos() {
    final controller = StreamController<List<TodoListEntry>>.broadcast();
    StreamSubscription<void>? changes;
    var latest = 0;

    Future<void> publish() async {
      final token = ++latest;
      try {
        final rows = await getTodos();
        if (token != latest || !controller.hasListener) return;
        controller.add(rows);
      } catch (error, stackTrace) {
        if (token != latest || !controller.hasListener) return;
        controller.addError(error, stackTrace);
      }
    }

    controller
      ..onListen = () {
        changes = _changes.stream.listen((_) {
          publish();
        });
        publish();
      }
      ..onCancel = () {
        changes?.cancel();
      };

    return controller.stream;
  }

  /// Map 里只放要改的列。这次不会动标题和创建时间。
  Future<int> setCompleted(int id, bool isCompleted) async {
    final count = await _db.update(
      Todos.table,
      {Todos.isCompleted: isCompleted ? 1 : 0},
      where: '${Todos.id} = ?',
      whereArgs: [id],
    );
    _notify();
    return count;
  }

  Future<int> deleteTodo(int id) async {
    final count = await _db.delete(
      Todos.table,
      where: '${Todos.id} = ?',
      whereArgs: [id],
    );
    _notify();
    return count;
  }

  var _closed = false;

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_changes.isClosed) {
      await _changes.close();
    }
    await _manager.close();
  }
}
