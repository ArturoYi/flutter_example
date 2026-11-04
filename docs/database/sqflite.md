---
description: 我用 sqflite 自己写 SQL。
---

# sqflite

我用 [sqflite](https://pub.dev/packages/sqflite) ^2.4.5 自己写 SQL，结果是 `Map`，再转成对象。代码在 `sqflite_example/`。桌面另加 `sqflite_common_ffi` ^2.4.5。Flutter 3.47 以上（Dart ^3.13.5）。没有代码生成。

Android、iOS、macOS 走插件。Linux 和 Windows 我改用 `sqfliteFfiInit()`，并把 `databaseFactory` 设成 `databaseFactoryFfi`。

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
);
```

新文件只走 `onCreate`，旧文件版本更低才走 `onUpgrade`。这两个回调已经在事务里，我不再套一层。用户输入放进 `whereArgs`。插入时不带 `id`。

完成状态我存 0 和 1，时间存毫秒。标题用 `CHECK` 限制长度。文件在文档目录，叫 `sqflite-example.db`。

它没有 `watch`。我在写入成功后自己再查一次。事务回调里只用参数 `txn`，不要拿外面的 `db`。

```bash
./scripts/demo.sh install sqflite_example
./scripts/demo.sh run sqflite_example
```

测试把 `databaseFactory` 换成 `databaseFactoryFfiNoIsolate`，每个测试用自己的临时文件。别共用 `:memory:`，连接会按路径缓存。这里没有接 Web。

类型安全的写法在 [Drift](/database/drift)。
