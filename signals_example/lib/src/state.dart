import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'common.dart';

class LabSignals {
  LabSignals({CatalogApi? catalogApi, AuthApi? authApi})
    : catalogApi = catalogApi ?? const CatalogApi(),
      authApi = authApi ?? const AuthApi() {
    doubled = computed(() => count.value * 2);
    remaining = computed(() => remainingCount(todos.value));
    visible = computed(
      () => visibleTodos(todos.value, filter.value, query.value),
    );
    cartItemCount = computed(() => cartCount(cart.value));
    cartTotal = computed(() => cartTotalCents(cart.value));
    _debounce = effect(() {
      final value = queryInput.value;
      final timer = Timer(const Duration(milliseconds: 300), () {
        query.value = value;
      });
      return timer.cancel;
    });
    catalog = futureSignal(() {
      final fail = untracked(() => failNext.value);
      return this.catalogApi.fetch(fail: fail);
    });
    clock = streamSignal(() async* {
      yield DateTime.now();
      yield* Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      );
    });
  }

  final CatalogApi catalogApi;
  final AuthApi authApi;

  final count = signal(0);
  final taps = signal(0);
  late final Computed<int> doubled;
  final themeMode = signal(ThemeMode.light);

  final todos = signal(seedTodos());
  final filter = signal(TodoFilter.all);
  final queryInput = signal('');
  final query = signal('');
  late final Computed<int> remaining;
  late final Computed<List<Todo>> visible;

  final failNext = signal(false);
  late final FutureSignal<List<Product>> catalog;

  final session = signal<Session?>(null);
  final authBusy = signal(false);
  final authError = signal<String?>(null);
  final cart = signal<Map<String, int>>(const {});
  late final Computed<int> cartItemCount;
  late final Computed<int> cartTotal;

  late final StreamSignal<DateTime> clock;
  late final EffectCleanup _debounce;

  void increment() => count.value += 1;

  void decrement() => count.value -= 1;

  void incrementSplit() {
    count.value += 1;
    taps.value += 1;
  }

  void incrementBatch() {
    batch(() {
      count.value += 1;
      taps.value += 1;
    });
  }

  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void addTodo(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    todos.value = [Todo(id: newId(), title: trimmed), ...todos.value];
  }

  void toggleTodo(String id) {
    todos.value = [
      for (final todo in todos.value)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
  }

  void removeTodo(String id) {
    todos.value = [
      for (final todo in todos.value)
        if (todo.id != id) todo,
    ];
  }

  void setFilter(TodoFilter value) => filter.value = value;

  void setQueryInput(String value) => queryInput.value = value;

  Future<void> reloadCatalog() => catalog.reload();

  Future<void> login(String email, String password) async {
    authBusy.value = true;
    authError.value = null;
    try {
      session.value = await authApi.login(email: email, password: password);
    } catch (error) {
      authError.value = errorText(error);
    } finally {
      authBusy.value = false;
    }
  }

  void logout() {
    batch(() {
      session.value = null;
      cart.value = const {};
    });
  }

  void addToCart(String productId) {
    if (session.peek() == null) return;
    final next = Map<String, int>.of(cart.peek());
    next[productId] = (next[productId] ?? 0) + 1;
    cart.value = next;
  }

  void dispose() {
    _debounce();
    catalog.dispose();
    clock.dispose();
  }
}

LabSignals? _instance;

LabSignals get signals => _instance ??= LabSignals();
