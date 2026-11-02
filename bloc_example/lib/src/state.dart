import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);

  void decrement() => emit(state - 1);
}

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void toggle() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

class ClockCubit extends Cubit<DateTime> {
  ClockCubit() : super(DateTime.now()) {
    _subscription = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).listen(emit);
  }

  late final StreamSubscription<DateTime> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
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

  @override
  bool operator ==(Object other) {
    return other is TodoState &&
        other.filter == filter &&
        other.query == query &&
        listEquals(other.todos, todos);
  }

  @override
  int get hashCode => Object.hash(filter, query, Object.hashAll(todos));

  @override
  String toString() => 'TodoState(${todos.length} 条, $filter, "$query")';
}

sealed class TodoEvent {
  const TodoEvent();
}

class TodoAdded extends TodoEvent {
  const TodoAdded(this.title);

  final String title;
}

class TodoToggled extends TodoEvent {
  const TodoToggled(this.id);

  final String id;
}

class TodoRemoved extends TodoEvent {
  const TodoRemoved(this.id);

  final String id;
}

class TodoFilterChanged extends TodoEvent {
  const TodoFilterChanged(this.filter);

  final TodoFilter filter;
}

class TodoQueryChanged extends TodoEvent {
  const TodoQueryChanged(this.query);

  final String query;
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(TodoState(todos: seedTodos())) {
    on<TodoAdded>(_onAdded);
    on<TodoToggled>(_onToggled);
    on<TodoRemoved>(_onRemoved);
    on<TodoFilterChanged>(_onFilter);
    on<TodoQueryChanged>(_onQuery, transformer: restartable());
  }

  void _onAdded(TodoAdded event, Emitter<TodoState> emit) {
    final title = event.title.trim();
    if (title.isEmpty) return;
    emit(
      state.copyWith(
        todos: [
          Todo(id: newId(), title: title),
          ...state.todos,
        ],
      ),
    );
  }

  void _onToggled(TodoToggled event, Emitter<TodoState> emit) {
    emit(
      state.copyWith(
        todos: [
          for (final todo in state.todos)
            if (todo.id == event.id) todo.copyWith(done: !todo.done) else todo,
        ],
      ),
    );
  }

  void _onRemoved(TodoRemoved event, Emitter<TodoState> emit) {
    emit(
      state.copyWith(
        todos: [
          for (final todo in state.todos)
            if (todo.id != event.id) todo,
        ],
      ),
    );
  }

  void _onFilter(TodoFilterChanged event, Emitter<TodoState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onQuery(TodoQueryChanged event, Emitter<TodoState> emit) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(query: event.query));
  }
}

class CatalogState {
  const CatalogState({
    this.products = const [],
    this.loading = false,
    this.error,
    this.failNext = false,
  });

  final List<Product> products;
  final bool loading;
  final String? error;
  final bool failNext;

  CatalogState copyWith({
    List<Product>? products,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? failNext,
  }) {
    return CatalogState(
      products: products ?? this.products,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      failNext: failNext ?? this.failNext,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogState &&
        other.loading == loading &&
        other.error == error &&
        other.failNext == failNext &&
        listEquals(other.products, products);
  }

  @override
  int get hashCode =>
      Object.hash(loading, error, failNext, Object.hashAll(products));
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this.api) : super(const CatalogState());

  final CatalogApi api;

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final products = await api.fetch(fail: state.failNext);
      if (isClosed) return;
      emit(
        state.copyWith(loading: false, products: products, clearError: true),
      );
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: errorText(error)));
    }
  }

  void setFailNext(bool value) => emit(state.copyWith(failNext: value));
}

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

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.api) : super(const AuthState());

  final AuthApi api;

  Future<void> login(String email, String password) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final session = await api.login(email: email, password: password);
      if (isClosed) return;
      emit(AuthState(session: session));
    } catch (error) {
      if (isClosed) return;
      emit(AuthState(error: errorText(error)));
    }
  }

  void logout() => emit(const AuthState());
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

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void add(String productId) => emit(state.add(productId));

  void clear() => emit(const CartState());
}

class DraftCubit extends Cubit<int> {
  DraftCubit() : super(0);

  static int closedCount = 0;

  void increment() => emit(state + 1);

  @override
  Future<void> close() {
    closedCount += 1;
    return super.close();
  }
}

class LabBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is ClockCubit) return;
    debugPrint('${bloc.runtimeType}: ${change.nextState}');
  }
}
