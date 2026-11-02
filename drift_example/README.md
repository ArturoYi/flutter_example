# Drift 数据库示例

这是一个使用 [Drift](https://pub.dev/packages/drift) 的 Flutter 待办示例。Drift 在 SQLite 上提供类型安全的表、查询和自动刷新的结果流。

建议顺着这几个文件读：

1. `lib/database/app_database.dart`：表、数据库文件、版本和迁移
2. `lib/repositories/todo_repository.dart`：插入、更新、删除、JOIN 和 `watch`
3. `lib/main.dart`：界面如何消费结果流
4. `test/todo_repository_test.dart`：内存库里的增删改查

## 项目简介

Drift 把 SQLite 包成 Dart API，适合已经想用关系模型的本地数据：

- **表就是 Dart 类**：列、默认值、长度和外键写在 getter 上
- **编译期检查查询**：生成器根据表产生行类型和查询代码
- **结果可以监听**：`watch()` 在相关表变化后再次发出
- **查询在后台 isolate**：`drift_flutter` 打开数据库时不会堵在界面线程上

底层仍然是 SQLite。布尔值会存成 0 和 1，日期存成 Unix 时间戳，精度到秒。

## 功能特性

- 待办和分类两张表，待办通过外键指向分类
- 添加、切换完成状态、删除
- 列表按创建时间倒序，并带上分类名称
- 空库时写入三行示例数据
- `schemaVersion`、`onCreate` 和打开连接时启用外键

## 应用界面

- 输入标题，选择分类，回车或点加号添加
- 列表显示标题、说明、分类、id 和创建时间
- 开关切换完成状态，删除图标移除待办

## 技术栈

- **Flutter**: 3.47+
- **Drift**: 2.35.3
- **drift_flutter**: 0.3.1
- **Dart**: 3.13+

## 安装与运行

### 环境要求

- Flutter SDK ≥ 3.47（Dart SDK ≥ 3.13）
- Android Studio / VS Code

### 安装步骤

1. **进入示例**

```bash
cd drift_example
```

2. **安装依赖**

```bash
flutter pub get
```

3. **生成数据库代码**

`@DriftDatabase` 和表类要经过生成器，才会出现 `TodoItem`、`TodoItemsCompanion` 这些类型。生成文件是 `lib/database/app_database.g.dart`，和源码一起保留。

```bash
dart run build_runner build
```

改了表或 `@DriftDatabase` 之后重新执行这条命令。

4. **运行项目**

```bash
flutter run
```

跑测试：

```bash
flutter test
```

测试使用 `NativeDatabase.memory()`，不写设备上的数据库文件。

## 项目结构

```
drift_example/
├── lib/
│   ├── main.dart
│   ├── database/
│   │   ├── app_database.dart      # 表、连接、迁移
│   │   └── app_database.g.dart    # 生成代码，不要手改
│   └── repositories/
│       └── todo_repository.dart   # 增删改查和监听
├── test/
│   └── todo_repository_test.dart
├── pubspec.yaml
└── README.md
```

## 核心写法

### 1. 用类描述表

```dart
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get content => text().named('body').nullable()();
  IntColumn get categoryId => integer().references(
    TodoCategories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}
```

类名 `TodoItems` 会变成表名 `todo_items`。`named('body')` 让 Dart 字段叫 `content`，SQLite 列名仍然是 `body`。

### 2. 打开数据库

```dart
@DriftDatabase(tables: [TodoCategories, TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}
```

设备上的文件在应用支持目录，名字是 `drift-example.sqlite`。测试传入 `NativeDatabase.memory()`。

### 3. 插入和局部更新

插入用 Companion。没写的字段走列上的默认值；`Value(null)` 才会把可空列写成 NULL。

```dart
await db.into(db.todoItems).insert(
  TodoItemsCompanion.insert(
    title: title,
    categoryId: categoryId,
    content: Value(content),
  ),
);
```

更新时 Companion 里只放要改的列，其余列保持原值：

```dart
await (db.update(db.todoItems)..where((row) => row.id.equals(id))).write(
  TodoItemsCompanion(isCompleted: Value(isCompleted)),
);
```

### 4. 监听 JOIN 结果

```dart
final query = db.select(db.todoItems).join([
  innerJoin(
    db.todoCategories,
    db.todoCategories.id.equalsExp(db.todoItems.categoryId),
  ),
]);

query.watch();
```

`watch()` 会占用这条查询，直到界面取消监听。

## 版本和约束

- 改表之后把 `schemaVersion` 加 1。新安装走 `onCreate`，直接得到最新的表
- 已安装用户走 `onUpgrade`。新增列用 `migrator.addColumn`
- SQLite 默认不检查外键。`beforeOpen` 里执行 `PRAGMA foreign_keys = ON`
- 删除仍被待办引用的分类会失败，因为外键动作是 `restrict`

`transaction()` 的回调里继续使用同一个 `AppDatabase`。Drift 会把这些调用收进当前事务。

## 和其他示例的差别

| | Drift | sqflite | ObjectBox / Realm |
| --- | --- | --- | --- |
| 数据模型 | 关系表 | 自己写 SQL | 对象 |
| 类型从哪来 | 生成器 | `Map` 和自己的类 | 生成器或对象类 |
| 列表刷新 | `watch()` | 写入后自己再查 | 查询监听 |

同仓库的 sqflite 示例用了同一组待办和分类，方便对照 JOIN、外键和事务写法。

## 注意事项

1. 修改表后运行 `dart run build_runner build`，并保留生成的 `app_database.g.dart`
2. 生成文件里的 `TodoItemsCompanion.insert` 会把必填列收成普通参数，可空列和带默认值的列仍然是 `Value`
3. 这个示例没有接 Web。Web 需要额外的 sqlite3 Wasm 和 drift worker
4. 日期精度是秒。界面上的分钟显示不受影响

## 相关资源

- [drift 2.35.3](https://pub.dev/packages/drift)
- [Drift 安装说明](https://drift.simonbinder.eu/setup/)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 许可证

本项目采用 MIT 许可证。

---

**返回 [项目总览](../README.md)**
