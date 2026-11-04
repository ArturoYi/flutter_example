---
description: 我用 Drift 写类型安全的 SQLite 查询。
---

# Drift

我用 [Drift](https://pub.dev/packages/drift) ^2.35.3 和 `drift_flutter` ^0.3.1 在 SQLite 上生成查询，代码在 `drift_example/`。Flutter 3.47 以上（Dart ^3.13.5）。

表是一个类，列是 getter。类名 `TodoItems` 会变成表名 `todo_items`。布尔存成 0 和 1，日期精确到秒。查询在后台 isolate 里跑。

```dart
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  IntColumn get categoryId => integer().references(
    TodoCategories,
    #id,
    onDelete: KeyAction.restrict,
  )();
}
```

插入用 Companion。没写的字段走默认值，想写成 NULL 才用 `Value(null)`。更新时 Companion 里只放要改的列。

列表是待办 JOIN 分类，用 `watch()` 听变化。这条查询会一直占着，直到界面取消监听。事务里我继续用同一个 `AppDatabase`。

文件在应用支持目录，名字是 `drift-example.sqlite`。SQLite 默认不查外键，我在 `beforeOpen` 里打开。改表后把 `schemaVersion` 加一，老用户走 `onUpgrade`。分类下面还有待办时，删除会失败。

生成文件是 `app_database.g.dart`，不要手改。这里没有接 Web。

```bash
./scripts/demo.sh install drift_example
./scripts/demo.sh generate drift_example
./scripts/demo.sh run drift_example
```

和手写 SQL 的对照在 [sqflite](/database/sqflite)。
