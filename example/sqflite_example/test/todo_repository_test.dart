import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfiNoIsolate, sqfliteFfiInit;
import 'package:sqflite_example/database/database_manager.dart';
import 'package:sqflite_example/main.dart';
import 'package:sqflite_example/repositories/todo_repository.dart';

void main() {
  late Directory tempDir;
  late TodoRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    // 组件测试里再开 isolate 跑 SQLite 会挂住，所以用同一进程里的 FFI 实现。
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    // sqflite 按路径缓存连接。每个测试用自己的临时文件，避免互相看见数据。
    tempDir = await Directory.systemTemp.createTemp('sqflite_example_');
    repository = TodoRepository(
      await DatabaseManager.open(path: p.join(tempDir.path, 'test.db')),
    );
  });

  tearDown(() async {
    await repository.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seeds, updates and deletes todos', () async {
    expect(await repository.getTodos(), isEmpty);

    await repository.seedIfEmpty();
    await repository.seedIfEmpty();

    final todos = await repository.getTodos();
    expect(todos.map((entry) => entry.todo.title), [
      '点删除图标移除任务',
      '用开关切换完成状态',
      '输入标题后回车，或点加号添加任务',
    ]);
    expect(todos.first.categoryName, '学习');
    expect(todos[1].todo.isCompleted, isTrue);
    expect(todos[2].todo.content, '列表按创建时间倒序');
    expect(todos.first.todo.createdAt, DateTime(2026, 1, 1, 11));

    final id = todos[1].todo.id!;
    expect(await repository.setCompleted(id, false), 1);
    expect((await repository.getTodo(id))?.isCompleted, isFalse);
    expect((await repository.getTodo(id))?.title, '用开关切换完成状态');

    expect(await repository.deleteTodo(id), 1);
    expect(await repository.getTodo(id), isNull);
  });

  test('rejects an empty title and a missing category', () async {
    await repository.seedIfEmpty();
    final categoryId = (await repository.getCategories()).first.id;

    await expectLater(
      repository.addTodo(title: '', categoryId: categoryId),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      repository.addTodo(title: '坏外键', categoryId: 99999),
      throwsA(isA<DatabaseException>()),
    );
    expect((await repository.getTodos()).length, 3);
  });

  test('watch emits the current rows and later writes', () async {
    await repository.seedIfEmpty();

    final first = Completer<int>();
    final afterWrite = Completer<int>();
    var writing = false;
    final subscription = repository.watchTodos().listen((rows) {
      final target = writing ? afterWrite : first;
      if (!target.isCompleted) target.complete(rows.length);
    });
    addTearDown(subscription.cancel);

    expect(await first.future, 3);

    writing = true;
    final categoryId = (await repository.getCategories()).first.id;
    await repository.addTodo(title: '新的任务', categoryId: categoryId);
    expect(await afterWrite.future, 4);
  });

  testWidgets('shows seeded todos and adds one from the field', (tester) async {
    await repository.seedIfEmpty();
    todoRepository = repository;

    await tester.pumpWidget(const MainApp());
    await _pumpUntil(tester, find.text('点删除图标移除任务'));

    expect(find.text('用开关切换完成状态'), findsOneWidget);
    expect(find.text('列表按创建时间倒序'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input')), '买菜');
    await tester.tap(find.byKey(const Key('submit')));
    await _pumpUntil(tester, find.text('买菜'));
  });
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }
  fail('未出现 $finder');
}

