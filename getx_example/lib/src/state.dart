import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'common.dart';

class ThemeController extends GetxController {
  final mode = ThemeMode.light.obs;

  void toggle() {
    mode.value = mode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}

class CounterController extends GetxController {
  final count = 0.obs;

  void increment() => count.value += 1;

  void decrement() => count.value -= 1;
}

class ManualCounterController extends GetxController {
  int count = 0;

  void increment() {
    count += 1;
    update(['count']);
  }
}

class TodoController extends GetxController {
  final todos = seedTodos().obs;
  final filter = TodoFilter.all.obs;
  final input = ''.obs;
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(
      input,
      (value) => query.value = value,
      time: const Duration(milliseconds: 300),
    );
  }

  int get remaining => remainingCount(todos);

  List<Todo> get visible => visibleTodos(todos, filter.value, query.value);

  void setFilter(TodoFilter value) => filter.value = value;

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    todos.insert(0, Todo(id: newId(), title: trimmed));
  }

  void toggle(String id) {
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    todos[index] = todos[index].copyWith(done: !todos[index].done);
  }

  void remove(String id) {
    todos.removeWhere((todo) => todo.id == id);
  }
}

class CatalogController extends GetxController {
  CatalogController({CatalogApi? api}) : api = api ?? const CatalogApi();

  final CatalogApi api;
  final products = <Product>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final failNext = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      final next = await api.fetch(fail: failNext.value);
      if (isClosed) return;
      products.assignAll(next);
    } catch (error) {
      if (isClosed) return;
      this.error.value = errorText(error);
    } finally {
      if (!isClosed) loading.value = false;
    }
  }
}

class AuthController extends GetxController {
  AuthController({AuthApi? api}) : api = api ?? const AuthApi();

  final AuthApi api;
  final session = Rxn<Session>();
  final busy = false.obs;
  final error = RxnString();

  Future<void> login(String email, String password) async {
    busy.value = true;
    error.value = null;
    try {
      final next = await api.login(email: email, password: password);
      if (isClosed) return;
      session.value = next;
    } catch (error) {
      if (isClosed) return;
      this.error.value = errorText(error);
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  void logout() => session.value = null;
}

class CartController extends GetxController {
  final lines = <String, int>{}.obs;

  int get count => cartCount(lines);

  int get totalCents => cartTotalCents(lines);

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.session, (session) {
      if (session == null) lines.clear();
    });
    once(lines, (_) {
      if (lines.isNotEmpty && !Get.testMode) {
        Get.snackbar('购物车', '第一次放入商品');
      }
    });
  }

  void add(String productId) {
    if (Get.find<AuthController>().session.value == null) return;
    lines[productId] = (lines[productId] ?? 0) + 1;
  }
}

class ClockService extends GetxService {
  final now = DateTime.now().obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class DraftCounterController extends GetxController {
  static int closedCount = 0;

  final count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(count, (value) {
      if (value == 5) {
        Get.snackbar('作用域', '临时计数到了 5');
      }
    });
  }

  void increment() => count.value += 1;

  @override
  void onClose() {
    closedCount += 1;
    super.onClose();
  }
}

void registerControllers() {
  Get.put(ThemeController());
  Get.put(CounterController());
  Get.put(ManualCounterController());
  Get.lazyPut(TodoController.new);
  Get.put(CatalogController());
  Get.put(AuthController());
  Get.put(CartController());
  Get.put(ClockService(), permanent: true);
}
