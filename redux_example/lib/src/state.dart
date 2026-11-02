import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class Services {
  const Services({
    this.catalogApi = const CatalogApi(),
    this.authApi = const AuthApi(),
  });

  final CatalogApi catalogApi;
  final AuthApi authApi;
}

class AppState {
  AppState({
    required this.count,
    required this.themeMode,
    required this.todos,
    required this.filter,
    required this.query,
    required this.products,
    required this.catalogFailNext,
    required this.session,
    required this.cart,
    required this.draftCount,
    required this.now,
    required this.notice,
  });

  factory AppState.initial() {
    return AppState(
      count: 0,
      themeMode: ThemeMode.light,
      todos: seedTodos(),
      filter: TodoFilter.all,
      query: '',
      products: const [],
      catalogFailNext: false,
      session: null,
      cart: const {},
      draftCount: 0,
      now: DateTime.now(),
      notice: Evt(''),
    );
  }

  final int count;
  final ThemeMode themeMode;
  final List<Todo> todos;
  final TodoFilter filter;
  final String query;
  final List<Product> products;
  final bool catalogFailNext;
  final Session? session;
  final Map<String, int> cart;
  final int draftCount;
  final DateTime now;
  final Evt<String> notice;

  List<Todo> get visible => visibleTodos(todos, filter, query);

  int get remaining => remainingCount(todos);

  AppState copyWith({
    int? count,
    ThemeMode? themeMode,
    List<Todo>? todos,
    TodoFilter? filter,
    String? query,
    List<Product>? products,
    bool? catalogFailNext,
    Session? session,
    bool clearSession = false,
    Map<String, int>? cart,
    int? draftCount,
    DateTime? now,
    Evt<String>? notice,
  }) {
    return AppState(
      count: count ?? this.count,
      themeMode: themeMode ?? this.themeMode,
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      products: products ?? this.products,
      catalogFailNext: catalogFailNext ?? this.catalogFailNext,
      session: clearSession ? null : (session ?? this.session),
      cart: cart ?? this.cart,
      draftCount: draftCount ?? this.draftCount,
      now: now ?? this.now,
      notice: notice ?? this.notice,
    );
  }
}

abstract class AppAction extends ReduxAction<AppState> {
  Services get services => store.environment as Services;
}

class ActionLog extends ActionObserver<AppState> {
  final entries = ValueNotifier<List<String>>(const []);

  @override
  void observe(
    ReduxAction<AppState> action,
    int dispatchCount, {
    required bool ini,
  }) {
    if (!ini || action is TickClock) return;
    final next = [action.toString(), ...entries.value];
    entries.value = next.length > 8 ? next.sublist(0, 8) : next;
  }
}

final actionLog = ActionLog();

Store<AppState> createStore({
  AppState? initialState,
  Services? services,
  List<ActionObserver<AppState>>? actionObservers,
}) {
  return Store<AppState>(
    initialState: initialState ?? AppState.initial(),
    environment: services ?? const Services(),
    actionObservers: actionObservers,
  );
}

extension AppContext on BuildContext {
  R select<R>(R Function(AppState state) selector) {
    return getSelect<AppState, R>(selector);
  }

  R? takeEvent<R>(Evt<R> Function(AppState state) selector) {
    return getEvent<AppState, R>(selector);
  }
}

class IncrementCount extends AppAction {
  @override
  AppState reduce() => state.copyWith(count: state.count + 1);

  @override
  String toString() => 'IncrementCount';
}

class DecrementCount extends AppAction {
  @override
  AppState reduce() => state.copyWith(count: state.count - 1);

  @override
  String toString() => 'DecrementCount';
}

class ToggleTheme extends AppAction {
  @override
  AppState reduce() {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    return state.copyWith(themeMode: next);
  }

  @override
  String toString() => 'ToggleTheme';
}

class TickClock extends AppAction {
  TickClock(this.now);

  final DateTime now;

  @override
  AppState reduce() => state.copyWith(now: now);
}

class AddTodo extends AppAction {
  AddTodo(this.title);

  final String title;

  @override
  AppState? reduce() {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    return state.copyWith(
      todos: [
        Todo(id: newId(), title: trimmed),
        ...state.todos,
      ],
    );
  }

  @override
  String toString() => 'AddTodo($title)';
}

class ToggleTodo extends AppAction {
  ToggleTodo(this.id);

  final String id;

  @override
  AppState reduce() {
    return state.copyWith(
      todos: [
        for (final todo in state.todos)
          if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
      ],
    );
  }
}

class RemoveTodo extends AppAction {
  RemoveTodo(this.id);

  final String id;

  @override
  AppState reduce() {
    return state.copyWith(
      todos: [
        for (final todo in state.todos)
          if (todo.id != id) todo,
      ],
    );
  }
}

class SetFilter extends AppAction {
  SetFilter(this.filter);

  final TodoFilter filter;

  @override
  AppState reduce() => state.copyWith(filter: filter);
}

class SetQuery extends AppAction {
  SetQuery(this.query);

  final String query;

  @override
  AppState reduce() => state.copyWith(query: query);

  @override
  String toString() => 'SetQuery($query)';
}

class SetCatalogFail extends AppAction {
  SetCatalogFail(this.value);

  final bool value;

  @override
  AppState reduce() => state.copyWith(catalogFailNext: value);
}

class LoadCatalog extends AppAction with NonReentrant {
  @override
  Future<AppState?> reduce() async {
    try {
      final products = await services.catalogApi.fetch(
        fail: state.catalogFailNext,
      );
      return state.copyWith(products: products);
    } catch (error) {
      throw UserException(errorText(error));
    }
  }

  @override
  String toString() => 'LoadCatalog';
}

class Login extends AppAction with NonReentrant {
  Login(this.email, this.password);

  final String email;
  final String password;

  @override
  Future<AppState?> reduce() async {
    try {
      final session = await services.authApi.login(
        email: email,
        password: password,
      );
      return state.copyWith(session: session);
    } catch (error) {
      throw UserException(errorText(error));
    }
  }

  @override
  String toString() => 'Login';
}

class Logout extends AppAction {
  @override
  AppState reduce() => state.copyWith(clearSession: true, cart: const {});

  @override
  String toString() => 'Logout';
}

class AddToCart extends AppAction {
  AddToCart(this.productId);

  final String productId;

  @override
  AppState? reduce() {
    if (state.session == null) return null;
    final next = Map<String, int>.of(state.cart);
    next[productId] = (next[productId] ?? 0) + 1;
    return state.copyWith(cart: next);
  }

  @override
  String toString() => 'AddToCart($productId)';
}

class IncrementDraft extends AppAction {
  @override
  AppState reduce() {
    final next = state.draftCount + 1;
    return state.copyWith(
      draftCount: next,
      notice: next == 5 ? Evt('临时计数到了 5') : state.notice,
    );
  }
}

class ResetDraft extends AppAction {
  @override
  AppState reduce() => state.copyWith(draftCount: 0);

  @override
  String toString() => 'ResetDraft';
}
