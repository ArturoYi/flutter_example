import 'package:realm/realm.dart';
import 'package:realm_example/models/person.dart';

class DatabaseManager {
  static DatabaseManager? _instance;
  late final Realm _realm;

  DatabaseManager._() {
    final config = Configuration.local(
      [Person.schema, Address.schema],
      schemaVersion: 1,
      migrationCallback: (migration, oldSchemaVersion) {
        // 这里实现版本迁移
      },
    );
    _realm = Realm(config);
  }

  static Future<DatabaseManager> getInstance() async {
    _instance ??= DatabaseManager._();
    return _instance!;
  }

  Realm get realm => _realm;

  void close() {
    _realm.close();
  }
}
