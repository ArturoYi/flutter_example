/// 表名和列名。
///
/// sqflite 的参数是字符串，列名散落在 SQL 和 Map 里时很容易写错。
/// 建表、插入、查询都用这里的常量。
abstract final class Categories {
  static const table = 'categories';
  static const id = 'id';
  static const name = 'name';
}

abstract final class Todos {
  static const table = 'todos';
  static const id = 'id';
  static const title = 'title';
  static const content = 'content';
  static const categoryId = 'category_id';
  static const isCompleted = 'is_completed';
  static const createdAt = 'created_at';
}

/// 分类。sqflite 读出来的是 Map，这里把它收成一个普通对象。
class Category {
  const Category({required this.id, required this.name});

  final int id;
  final String name;
}

/// 一条待办。
///
/// SQLite 只能直接存整数、小数、字符串和二进制。
/// [isCompleted] 在库里是 INTEGER，0 表示未完成，1 表示完成。
/// [createdAt] 在库里是 INTEGER，单位是毫秒。
class Todo {
  const Todo({
    this.id,
    required this.title,
    this.content,
    required this.categoryId,
    this.isCompleted = false,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String? content;
  final int categoryId;
  final bool isCompleted;
  final DateTime createdAt;

  /// 插入用的 Map。不包含 [id]，让 SQLite 自己分配自增主键。
  Map<String, Object?> toInsertMap() {
    return {
      Todos.title: title,
      Todos.content: content,
      Todos.categoryId: categoryId,
      Todos.isCompleted: isCompleted ? 1 : 0,
      Todos.createdAt: createdAt.millisecondsSinceEpoch,
    };
  }

  factory Todo.fromMap(Map<String, Object?> map) {
    return Todo(
      id: map[Todos.id] as int,
      title: map[Todos.title] as String,
      content: map[Todos.content] as String?,
      categoryId: map[Todos.categoryId] as int,
      isCompleted: map[Todos.isCompleted] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[Todos.createdAt] as int,
      ),
    );
  }
}

/// 列表里的一行：待办加上分类名称。
///
/// 分类名称来自 JOIN，不是 `todos` 表里的列。
class TodoListEntry {
  const TodoListEntry({required this.todo, required this.categoryName});

  static const categoryNameColumn = 'category_name';

  final Todo todo;
  final String categoryName;

  factory TodoListEntry.fromMap(Map<String, Object?> map) {
    return TodoListEntry(
      todo: Todo.fromMap(map),
      categoryName: map[categoryNameColumn] as String,
    );
  }
}
