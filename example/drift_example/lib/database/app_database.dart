import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 待办分类。
///
/// Drift 用继承 [Table] 的类描述表，每个 getter 是一列。
/// 类名 `TodoCategories` 默认变成 SQLite 表名 `todo_categories`。
class TodoCategories extends Table {
  /// `autoIncrement()` 同时表示整数主键和自动递增。
  /// 插入时不用给这个字段赋值。
  IntColumn get id => integer().autoIncrement()();

  /// `unique()` 生成 UNIQUE 约束，同名分类不能插两次。
  TextColumn get name => text().unique()();
}

/// 待办。
///
/// 这是 Drift 入门文档里的 todo 表，补了完成状态和分类外键。
/// 修改列之后，在本目录执行：
/// `dart run build_runner build`
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `withLength` 会在插入前检查字符串长度，并在 SQLite 里写成 CHECK。
  TextColumn get title => text().withLength(min: 1, max: 80)();

  /// Dart 里叫 [content]，数据库列名是 `body`。
  /// `named` 用来对齐已经存在、不方便改名的列。
  TextColumn get content => text().named('body').nullable()();

  /// 指向 [TodoCategories.id]。
  /// `restrict` 表示这个分类下还有待办时，删除分类会失败。
  IntColumn get categoryId =>
      integer().references(TodoCategories, #id, onDelete: KeyAction.restrict)();

  /// SQLite 没有布尔类型。Drift 写入时转成 0 或 1，读出来再变回 bool。
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// 插入行没有写创建时间时，用调用瞬间的本地时间。
  /// 这个值在 Dart 侧补上，再交给 Drift 存进 SQLite。
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

/// 整个数据库的入口。
///
/// `@DriftDatabase` 告诉生成器要为哪些表生成代码。生成文件里会有：
/// - 行类型 [TodoItem]、[TodoCategory]
/// - 插入和局部更新用的 `TodoItemsCompanion`、`TodoCategoriesCompanion`
/// - 查询里用的列，例如 `todoItems.title`
@DriftDatabase(tables: [TodoCategories, TodoItems])
class AppDatabase extends _$AppDatabase {
  /// [executor] 留空时打开设备上的数据库文件。
  /// 测试传入 `NativeDatabase.memory()`，数据只活在这次进程里。
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// 当前表结构的版本。
  ///
  /// 改了列或表之后把这里加 1。新安装只会走 [migration] 的 `onCreate`，
  /// 直接得到最新的表。以前安装过的用户会走 `onUpgrade`。
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        // 按上面的表类创建全部表和约束。
        await migrator.createAll();
      },
      // 已有用户升级时再打开这段。例如新增一列：
      // onUpgrade: (migrator, from, to) async {
      //   if (from < 2) {
      //     await migrator.addColumn(todoItems, todoItems.content);
      //   }
      // },
      beforeOpen: (details) async {
        // SQLite 默认不检查外键。这个开关属于连接，每次打开都要设置。
        await customStatement('PRAGMA foreign_keys = ON');
        if (kDebugMode) {
          debugPrint(
            'Opened drift schema $schemaVersion '
            '(created now: ${details.wasCreated})',
          );
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    // drift_flutter 在后台 isolate 里打开 SQLite，查询不会堵在界面线程上。
    // 文件位于应用支持目录，文件名是 drift-example.sqlite。
    return driftDatabase(
      name: 'drift-example',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
