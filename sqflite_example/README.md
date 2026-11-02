# sqflite 数据库示例

这是一个使用 [sqflite](https://pub.dev/packages/sqflite) 的 Flutter 待办示例。sqflite 是 SQLite 的 Flutter 插件：SQL 自己写，结果是 `Map`，再转成 Dart 对象。

建议顺着这几个文件读：

1. `lib/models/todo.dart`：表名、列名，以及 `Map` 和对象的转换
2. `lib/database/database_manager.dart`：打开文件、版本、建表、外键
3. `lib/repositories/todo_repository.dart`：增删改查、JOIN 和刷新
4. `lib/main.dart`：界面
5. `test/todo_repository_test.dart`

## 项目简介

sqflite 把 SQLite 的语句发到后台执行，适合想直接控制 SQL 的本地存储：

- **SQL 写在代码里**：建表、索引、外键和 CHECK 都看得见
- **参数用 `?` 绑定**：用户输入放进 `whereArgs`，不拼进 SQL 文本
- **结果是 Map**：布尔值和时间要自己约定存储方式
- **没有查询监听**：插件不会在表变化时回调，本示例在写入成功后重新查询

Android、iOS、macOS 使用 sqflite 插件。Linux 和 Windows 没有这个插件，示例在这两个平台改用 `sqflite_common_ffi`。

## 功能特性

- `categories` 和 `todos` 两张表，待办通过外键指向分类
- 添加、切换完成状态、删除
- 列表按创建时间倒序，并 JOIN 出分类名称
- 空库时用事务和 `batch` 写入三行示例数据
- `version`、`onCreate`、`onUpgrade`，打开连接时启用外键

## 应用界面

- 输入标题，选择分类，回车或点加号添加
- 列表显示标题、说明、分类、id 和创建时间
- 开关切换完成状态，删除图标移除待办

## 技术栈

- **Flutter**: 3.47+
- **sqflite**: 2.4.5
- **sqflite_common_ffi**: 2.4.5
- **Dart**: 3.13+

## 安装与运行

### 环境要求

- Flutter SDK ≥ 3.47（Dart SDK ≥ 3.13）
- Android Studio / VS Code

### 安装步骤

1. **进入示例**

```bash
cd sqflite_example
```

2. **安装依赖**

```bash
flutter pub get
```

sqflite 没有代码生成。

3. **运行项目**

```bash
flutter run
```

跑测试：

```bash
flutter test
```

测试把全局 `databaseFactory` 换成 `databaseFactoryFfiNoIsolate`，这样不依赖手机或模拟器。每个测试使用自己的临时数据库文件。sqflite 会按路径缓存连接，多个测试共用 `:memory:` 时可能看到同一份数据。

## 项目结构

```
sqflite_example/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── todo.dart                 # 列名和 Map 转换
│   ├── database/
│   │   └── database_manager.dart     # 打开数据库和建表
│   └── repositories/
│       └── todo_repository.dart      # 增删改查
├── test/
│   └── todo_repository_test.dart
├── pubspec.yaml
└── README.md
```

## 核心写法

### 1. SQLite 能存什么

SQLite 直接存储整数、小数、字符串和二进制。这个示例的约定是：

- `is_completed`：`INTEGER`，0 未完成，1 完成
- `created_at`：`INTEGER`，毫秒时间戳
- 标题：`TEXT NOT NULL`，并用 `CHECK (length(title) BETWEEN 1 AND 80)` 限制长度

查询返回的 Map 是只读的。要改字段时构造新的 Map，或改 Dart 对象后再写回。

### 2. 打开数据库

```dart
await openDatabase(
  path,
  version: 1,
  onConfigure: (db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  },
  onCreate: (db, version) async {
    await db.execute('CREATE TABLE ...');
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE todos ADD COLUMN note TEXT');
    // }
  },
);
```

`version` 存在 SQLite 的 `user_version` 里。新文件只走 `onCreate`。已安装用户的版本更低时走 `onUpgrade`，然后 sqflite 把 `user_version` 写成这次的 `version`。

`onCreate` 和 `onUpgrade` 已经在事务里，回调内部不要再包一层 `transaction`。

设备上的文件在应用文档目录，名字是 `sqflite-example.db`。

### 3. 写入和查询

```dart
final id = await db.insert('todos', todo.toInsertMap());

final rows = await db.query(
  'todos',
  where: 'id = ?',
  whereArgs: [id],
);

await db.update(
  'todos',
  {'is_completed': isCompleted ? 1 : 0},
  where: 'id = ?',
  whereArgs: [id],
);
```

`insert` 返回新行的 id。更新用的 Map 里只放要改的列。

列表查询把 `todos` 和 `categories` 做 `INNER JOIN`，分类名用别名 `category_name`。`orderBy` 不能使用 `?` 占位符，排序列来自代码里的常量，不来自用户输入。

### 4. 事务

```dart
await db.transaction((txn) async {
  final categoryId = await txn.insert('categories', {'name': '工作'});
  final batch = txn.batch();
  batch.insert('todos', {'title': '示例', 'category_id': categoryId});
  await batch.commit(noResult: true);
});
```

回调里只用 `txn`。事务结束前连接是锁住的，再拿外面的 `db` 发语句会一直等待。

### 5. 让界面刷新

sqflite 没有 `watch`。仓库在插入、更新、删除成功后发出信号，监听者再执行一次 JOIN。别的进程改了数据库文件时，这个信号不会出现。

## 版本和约束

- 改表之后把 `schemaVersion` 加 1，并在 `_onUpgrade` 里补 `ALTER TABLE`
- 新安装不会走升级逻辑，所以 `_onCreate` 要直接创建最新的表
- 外键默认关闭。`onConfigure` 比 `onCreate` 更早，适合执行 `PRAGMA foreign_keys = ON`
- 标题长度由 SQL `CHECK` 约束。Drift 示例里同类规则写在列的 `withLength` 上

## 和其他示例的差别

| | sqflite | Drift |
| --- | --- | --- |
| 查询 | SQL 字符串 | 生成的 Dart 查询 |
| 行 | `Map<String, Object?>` | 生成的 `TodoItem` |
| 刷新 | 写入后自己再查 | `watch()` |
| 事务里用谁 | 回调参数 `txn` | 原来的数据库对象 |

同仓库的 Drift 示例保存同一组待办数据。ObjectBox 和 Realm 示例则是对象数据库，不写 SQL。

## 注意事项

1. 插入时不要带上 `id`，让 `AUTOINCREMENT` 分配主键
2. Linux / Windows 需要 `sqfliteFfiInit()`，并把 `databaseFactory` 设为 `databaseFactoryFfi`
3. 组件测试使用 `databaseFactoryFfiNoIsolate`。FFI 默认实现会再开 isolate，组件测试里容易挂住
4. 这个示例没有接 Web。Web 需要实验性的 `sqflite_common_ffi_web`

## 相关资源

- [sqflite 2.4.5](https://pub.dev/packages/sqflite)
- [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)
- [Flutter：用 SQLite 持久化数据](https://docs.flutter.dev/cookbook/persistence/sqlite)

## 许可证

本项目采用 MIT 许可证。

---

**返回 [项目总览](../README.md)**
