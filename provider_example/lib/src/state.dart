import 'dart:async';

import 'package:flutter/material.dart';

import 'common.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  void toggle() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class CounterController extends ChangeNotifier {
  int count = 0;

  void increment() {
    count += 1;
    notifyListeners();
  }

  void decrement() {
    count -= 1;
    notifyListeners();
  }
}

class TodoView {
  const TodoView(this.todos, this.filter, this.query);

  final List<Todo> todos;
  final TodoFilter filter;
  final String query;

  List<Todo> get visible => visibleTodos(todos, filter, query);

  @override
  bool operator ==(Object other) {
    return other is TodoView &&
        other.filter == filter &&
        other.query == query &&
        listEqualsTodo(other.todos, todos);
  }

  @override
  int get hashCode => Object.hash(filter, query, Object.hashAll(todos));
}

bool listEqualsTodo(List<Todo> a, List<Todo> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class TodoController extends ChangeNotifier {
  TodoController() : todos = seedTodos();

  List<Todo> todos;
  TodoFilter filter = TodoFilter.all;
  String query = '';
  Timer? _debounce;

  int get remaining => remainingCount(todos);

  void setFilter(TodoFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      query = value;
      notifyListeners();
    });
  }

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    todos = [Todo(id: newId(), title: trimmed), ...todos];
    notifyListeners();
  }

  void toggle(String id) {
    todos = [
      for (final todo in todos)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
    notifyListeners();
  }

  void remove(String id) {
    todos = [
      for (final todo in todos)
        if (todo.id != id) todo,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class CatalogController extends ChangeNotifier {
  CatalogController(this.api);

  final CatalogApi api;
  List<Product> products = const [];
  bool loading = false;
  String? error;
  bool failNext = false;
  bool _disposed = false;

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = await api.fetch(fail: failNext);
      if (_disposed) return;
      products = next;
    } catch (error) {
      if (_disposed) return;
      this.error = errorText(error);
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void setFailNext(bool value) {
    failNext = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SessionController extends ChangeNotifier {
  SessionController(this.api);

  final AuthApi api;
  Session? session;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<void> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = await api.login(email: email, password: password);
      if (_disposed) return;
      session = next;
    } catch (error) {
      if (_disposed) return;
      this.error = errorText(error);
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void logout() {
    session = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class CartController extends ChangeNotifier {
  Session? _session;
  Map<String, int> lines = const {};

  bool get signedIn => _session != null;
  int get count => cartCount(lines);
  int get totalCents => cartTotalCents(lines);

  void updateSession(Session? session) {
    final loggedOut = _session != null && session == null;
    final changed = _session != session;
    _session = session;
    if (loggedOut && lines.isNotEmpty) {
      lines = const {};
      notifyListeners();
    } else if (changed) {
      notifyListeners();
    }
  }

  void add(String productId) {
    if (_session == null) return;
    final next = Map<String, int>.of(lines);
    next[productId] = (next[productId] ?? 0) + 1;
    lines = next;
    notifyListeners();
  }
}

class LabTip {
  const LabTip(this.text);

  final String text;
}

class DraftCounter extends ChangeNotifier {
  static int disposedCount = 0;

  int count = 0;

  void increment() {
    count += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    disposedCount += 1;
    super.dispose();
  }
}
