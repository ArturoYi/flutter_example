import 'package:flutter/foundation.dart';
import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseManager {
  /// 必须与 macOS entitlements 里的 App Group 一致。
  static const macosApplicationGroup = 'objectbox.example';

  late final Store _store;
  late final Map<Type, dynamic> _boxes;

  DatabaseManager._create(this._store) {
    _boxes = {Task: Box<Task>(_store)};
  }

  static Future<DatabaseManager> create() async {
    // 桌面端使用独立子目录，避免和其他应用共用同一个库。
    // 沙盒 macOS 还要传 application group，见
    // https://docs.objectbox.io/getting-started
    final store = await openStore(
      directory: p.join(
        (await getApplicationDocumentsDirectory()).path,
        'obx-example',
      ),
      macosApplicationGroup: macosApplicationGroup,
    );

    if (kDebugMode) {
      debugPrint('Using ObjectBox database version ${Store.databaseVersion()}');
    }

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
