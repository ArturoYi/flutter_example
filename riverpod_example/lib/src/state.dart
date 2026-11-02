import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => const CatalogApi());

final authApiProvider = Provider<AuthApi>((ref) => const AuthApi());

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state += 1;

  void decrement() => state -= 1;
}

class TodoState {
  const TodoState({
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.query = '',
  });

  final List<Todo> todos;
  final TodoFilter filter;
  final String query;

  int get remaining => remainingCount(todos);

  TodoState copyWith({List<Todo>? todos, TodoFilter? filter, String? query}) {
    return TodoState(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
}

final todoProvider = NotifierProvider<TodoNotifier, TodoState>(
  TodoNotifier.new,
);

class TodoNotifier extends Notifier<TodoState> {
  Timer? _debounce;

  @override
  TodoState build() {
    ref.onDispose(() => _debounce?.cancel());
    return TodoState(todos: seedTodos());
  }

  void setFilter(TodoFilter filter) => state = state.copyWith(filter: filter);

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(query: value);
    });
  }

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      todos: [
        Todo(id: newId(), title: trimmed),
        ...state.todos,
      ],
    );
  }

  void toggle(String id) {
    state = state.copyWith(
      todos: [
        for (final todo in state.todos)
          if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
      ],
    );
  }

  void remove(String id) {
    state = state.copyWith(
      todos: [
        for (final todo in state.todos)
          if (todo.id != id) todo,
      ],
    );
  }
}

final failNextProvider = NotifierProvider<FailNextNotifier, bool>(
  FailNextNotifier.new,
);

class FailNextNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setValue(bool value) => state = value;
}

final catalogProvider = AsyncNotifierProvider<CatalogNotifier, List<Product>>(
  CatalogNotifier.new,
  retry: (retryCount, error) => null,
);

class CatalogNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    return ref.read(catalogApiProvider).fetch(fail: ref.read(failNextProvider));
  }

  Future<void> reload() async {
    final fail = ref.read(failNextProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(catalogApiProvider).fetch(fail: fail),
    );
  }
}

final productProvider = Provider.family<Product?, String>((ref, id) {
  final products = ref.watch(catalogProvider).value;
  if (products == null) return null;
  for (final product in products) {
    if (product.id == id) return product;
  }
  return null;
});

final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

class AuthState {
  const AuthState({this.session, this.busy = false, this.error});

  final Session? session;
  final bool busy;
  final String? error;

  AuthState copyWith({
    Session? session,
    bool? busy,
    String? error,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await ref
          .read(authApiProvider)
          .login(email: email, password: password);
      if (!ref.mounted) return;
      state = AuthState(session: session);
    } catch (error) {
      if (!ref.mounted) return;
      state = AuthState(error: errorText(error));
    }
  }

  void logout() => state = const AuthState();
}

class CartState {
  const CartState({this.lines = const {}});

  final Map<String, int> lines;

  int get count => cartCount(lines);

  int get totalCents => cartTotalCents(lines);

  CartState add(String productId) {
    final next = Map<String, int>.of(lines);
    next[productId] = (next[productId] ?? 0) + 1;
    return CartState(lines: next);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    ref.listen(authProvider, (previous, next) {
      if (previous?.session != null && next.session == null) {
        state = const CartState();
      }
    });
    return const CartState();
  }

  void add(String productId) {
    if (ref.read(authProvider).session == null) return;
    state = state.add(productId);
  }
}

final draftProvider = NotifierProvider.autoDispose<DraftNotifier, int>(
  DraftNotifier.new,
);

class DraftNotifier extends Notifier<int> {
  static int disposedCount = 0;

  @override
  int build() {
    ref.onDispose(() => disposedCount += 1);
    return 0;
  }

  void increment() => state += 1;
}
