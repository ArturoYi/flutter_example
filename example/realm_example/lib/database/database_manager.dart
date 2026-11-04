import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:realm/realm.dart';
import 'package:realm_example/models/person.dart';

class DatabaseManager {
  /// 数据库文件名。旧示例的 `default.realm` 主键是 String，这里改用 ObjectId，所以单独建库。
  static const realmFileName = 'realm-example.realm';

  final Realm realm;

  DatabaseManager._(this.realm);

  static DatabaseManager open() {
    final realm = Realm(_localConfiguration());
    if (kDebugMode) {
      debugPrint('Opened Realm at ${realm.config.path}');
    }
    return DatabaseManager._(realm);
  }

  /// 测试用的内存库。不落盘，也不会写入首次示例数据。
  @visibleForTesting
  factory DatabaseManager.inMemory() {
    return DatabaseManager._(
      Realm(
        Configuration.inMemory(
          [Person.schema, Address.schema],
          path: 'person-test-${ObjectId()}.realm',
        ),
      ),
    );
  }

  static LocalConfiguration _localConfiguration() {
    return Configuration.local(
      [Person.schema, Address.schema],
      path: p.join(Configuration.defaultStoragePath, realmFileName),
      schemaVersion: 1,
      migrationCallback: _migrate,
      initialDataCallback: _seed,
    );
  }

  /// 只有磁盘上的 schemaVersion 低于配置里的版本时才会调用。
  /// 新增或删除字段时，提高 [schemaVersion] 即可。
  /// 重命名字段不会自动对应，要在这里写 `renameProperty`。
  static void _migrate(Migration migration, int oldSchemaVersion) {
    debugPrint(
      'Migrate Realm from version $oldSchemaVersion. '
      'Schema has ${migration.newRealm.schema.length} types.',
    );
  }

  /// 仅在数据库文件第一次创建时执行，并且此时已经处于写入事务中。
  static void _seed(Realm realm) {
    realm.add(
      Person(
        ObjectId(),
        '张三',
        25,
        email: 'zhangsan@example.com',
        address: Address(
          ObjectId(),
          '某某路某某号',
          '上海',
          '中国',
          postalCode: '200000',
        ),
      ),
    );
  }

  void close() => realm.close();
}
