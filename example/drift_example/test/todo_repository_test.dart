import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_example/database/app_database.dart';
import 'package:drift_example/main.dart';
import 'package:drift_example/repositories/todo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late TodoRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TodoRepository(database);
  });

  tearDown(() async {
    await repository.close();
  });

  test('seeds, updates and deletes todos', () async {
    expect(await repository.getTodos(), isEmpty);

    await repository.seedIfEmpty();
    await repository.seedIfEmpty();

    final todos = await repository.getTodos();
    expect(todos.map((entry) => entry.item.title), [
      '点删除图标移除任务',
      '用开关切换完成状态',
      '输入标题后回车，或点加号添加任务',
    ]);
    expect(todos.first.category.name, '学习');
    expect(todos[1].item.isCompleted, isTrue);
    expect(todos[2].item.content, '列表按创建时间倒序');

    final id = todos[1].item.id;
    expect(await repository.setCompleted(id, false), 1);
    final updated = await repository.getTodos();
    expect(
      updated.firstWhere((entry) => entry.item.id == id).item.isCompleted,
      isFalse,
    );

    expect(await repository.deleteTodo(id), 1);
    expect(
      (await repository.getTodos()).map((entry) => entry.item.id),
      isNot(contains(id)),
    );
  });

  test('rejects an empty title and a missing category', () async {
    await repository.seedIfEmpty();
    final categoryId = (await repository.getCategories()).first.id;

    await expectLater(
      repository.addTodo(title: '', categoryId: categoryId),
      throwsA(isA<InvalidDataException>()),
    );
    await expectLater(
      repository.addTodo(title: '坏外键', categoryId: 99999),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('FOREIGN KEY'),
          '外键约束失败',
        ),
      ),
    );
  });

  test('watch emits the current rows and later writes', () async {
    await repository.seedIfEmpty();
    expect(
      await _lengthsAfterWrite(repository, () async {
        final categoryId = (await repository.getCategories()).first.id;
        await repository.addTodo(title: '新的任务', categoryId: categoryId);
      }),
      [3, 4],
    );
  });

  testWidgets('shows seeded todos and adds one from the field', (tester) async {
    await repository.seedIfEmpty();
    todoRepository = repository;

    try {
      await tester.pumpWidget(const MainApp());
      await _pumpUntil(tester, find.text('点删除图标移除任务'));

      expect(find.text('用开关切换完成状态'), findsOneWidget);
      expect(find.text('列表按创建时间倒序'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input')), '买菜');
      await tester.tap(find.byKey(const Key('submit')));
      await _pumpUntil(tester, find.text('买菜'));
    } finally {
      // Drift 在取消监听后会留一个很短的缓存定时器。
      // 先关掉数据库，组件卸载时就不会再排这个定时器。
      await repository.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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

Future<List<int>> _lengthsAfterWrite(
  TodoRepository repository,
  Future<void> Function() write,
) async {
  final updates = StreamController<int>.broadcast();
  final subscription = repository.watchTodos().listen(
    (rows) => updates.add(rows.length),
  );
  addTearDown(subscription.cancel);
  addTearDown(updates.close);

  final first = updates.stream.first;
  final second = updates.stream.skip(1).first;
  final initial = await first;
  await write();
  return [initial, await second];
}
