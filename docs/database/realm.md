---
description: 我用 Realm 把人员和地址存在本地。
---

# Realm

我用 [realm](https://pub.dev/packages/realm) ^20.2.0 做本地对象存储，代码在 `example/realm_example/`。20.0 起没有 Atlas Device Sync，我只打开本地文件。Flutter 3.27 以上（Dart ^3.6.0）。

模型类以 `_` 开头，标上 `@RealmModel()`。生成出来的是去掉下划线的 `Person`、`Address`。一对一关系必须是可选的。

```dart
@RealmModel()
class _Person {
  @PrimaryKey()
  late ObjectId id;

  late String name;
  late _Address? address;
}
```

打开时我带上 schema、版本、迁移和首次填充。`initialDataCallback` 里事务已经开好，直接 `realm.add`。增删改都放在 `realm.write` 里。查询写成 `r'name == $0'`，再用 `changes` 听结果。

删人时要先解开和地址的关系，再删地址。它不会自动级联删除。

模型变了我就把 `schemaVersion` 加一。加字段、删字段它可以自己处理。改名要在 `migrationCallback` 里 `renameProperty`。主键不能从 `String` 改成 `ObjectId`，所以文件名叫 `realm-example.realm`。

`build.yaml` 把生成限制在 `lib/models`。这个版本的 analyzer 扫整份工程会失败。

```bash
./scripts/demo.sh install realm_example
./scripts/demo.sh generate realm_example
./scripts/demo.sh run realm_example
```

测试前先 `dart run realm install`，再 `flutter test`。生成的 `person.realm.dart` 我一并提交。
