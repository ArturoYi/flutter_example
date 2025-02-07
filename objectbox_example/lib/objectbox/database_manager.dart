import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox.g.dart';

class DatabaseManager {
  late final Store _store;
  late final Map<Type, dynamic> _boxes;

  DatabaseManager._create(this._store) {
    _boxes = {
      Task: Box<Task>(_store),
      // 在这里添加其他模型的 Box
      // Example: User: Box<User>(_store),
      // Example: Product: Box<Product>(_store),
    };
  }

  static Future<DatabaseManager> create() async {
    final store = await openStore();
    return DatabaseManager._create(store);
  }

  Box<T> box<T>() {
    final box = _boxes[T];
    if (box == null) {
      throw Exception('Box not found for type ${T.toString()}');
    }
    return box as Box<T>;
  }

  Future<R> transaction<R>(TxMode mode, R Function() action) async {
    return _store.runInTransaction(mode, action);
  }

  void close() => _store.close();
}
