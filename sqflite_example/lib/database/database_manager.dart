import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;
import 'package:sqflite_example/models/todo.dart';

/// 打开 SQLite 文件，并在第一次创建时建表。
///
/// sqflite 在 Android、iOS、macOS 上走插件，数据库操作在后台线程执行。
/// Linux 和 Windows 没有这个插件，要换成 `sqflite_common_ffi`。
class DatabaseManager {
  DatabaseManager._(this._database, this.path);

  /// 写在 SQLite 的 `user_version` 里。
  ///
  /// 打开时如果文件里的版本更低，sqflite 调用 [_onUpgrade]。
  /// 新文件只会走 [_onCreate]，直接得到当前这版表。
  static const schemaVersion = 1;

  final Database _database;
  final String path;

  Database get database => _database;

  static Future<DatabaseManager> open({String? path}) async {
    _useFfiOnDesktop();
    final resolved = path ?? await _defaultPath();
    final database = await openDatabase(
      resolved,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        if (kDebugMode) {
          debugPrint('Opened sqflite ${await db.getVersion()} at $resolved');
        }
      },
    );
    return DatabaseManager._(database, resolved);
  }

  /// 应用支持目录下的 `sqflite-example.db`。
  ///
  /// 这里不用 `getDatabasesPath()`。FFI 实现给出的默认目录不稳定，
  /// `path_provider` 在手机和桌面上都有明确位置。
  static Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'sqflite-example.db');
  }

  static void _useFfiOnDesktop() {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// 外键开关属于连接，必须在建表和查询之前设置。
  /// SQLite 默认不检查 FOREIGN KEY。
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// 只在数据库文件第一次创建时执行。
  ///
  /// sqflite 已经把它包进事务，这里再调用 `transaction` 会卡住。
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE ${Categories.table} (
  ${Categories.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${Categories.name} TEXT NOT NULL UNIQUE
)
''');

    await db.execute('''
CREATE TABLE ${Todos.table} (
  ${Todos.id} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${Todos.title} TEXT NOT NULL CHECK (
    length(${Todos.title}) BETWEEN 1 AND 80
  ),
  ${Todos.content} TEXT,
  ${Todos.categoryId} INTEGER NOT NULL,
  ${Todos.isCompleted} INTEGER NOT NULL DEFAULT 0,
  ${Todos.createdAt} INTEGER NOT NULL,
  FOREIGN KEY (${Todos.categoryId})
    REFERENCES ${Categories.table} (${Categories.id})
)
''');

    // 列表按创建时间排序，给这个列一个索引。
    await db.execute('''
CREATE INDEX idx_todos_created_at
  ON ${Todos.table} (${Todos.createdAt})
''');

    if (kDebugMode) {
      debugPrint('Created sqflite schema version $version');
    }
  }

  /// 已安装用户的 `user_version` 低于 [schemaVersion] 时执行。
  ///
  /// 新增列的写法：
  /// `if (oldVersion < 2) await db.execute('ALTER TABLE todos ADD COLUMN note TEXT');`
  /// 执行完后 sqflite 会把 `user_version` 写成这次打开用的版本。
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('Upgrade sqflite from $oldVersion to $newVersion (${db.path})');
  }

  Future<void> close() => _database.close();
}
