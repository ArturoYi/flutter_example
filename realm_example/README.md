# Realm 数据库示例

这是一个使用 [Realm](https://pub.dev/packages/realm) 数据库的 Flutter 示例项目，展示如何在 Flutter 应用里做本地对象存储。

## 📋 项目简介

Realm 是直接跑在手机、平板和桌面里的移动数据库，具有以下特点：

- 🎯 **对象 API**：用 Dart 类描述模型，不需要 ORM
- ⚡ **本地读写**：数据写在本机，查询在进程内完成
- 🔄 **结果监听**：查询结果变化后通过 `RealmResults.changes` 通知界面
- 🛡️ **可选加密**：打开数据库时可以传入 64 字节密钥

Realm 20.0 起已经移除 Atlas Device Sync。本示例只演示本地数据库。

## 🚀 功能特性

本示例实现了以下功能：

- ✅ **人员管理**：创建、读取、更新、删除人员
- ✅ **地址关联**：Person 到 Address 的可选一对一关系
- ✅ **数据持久化**：数据写入 `realm-example.realm`
- ✅ **首次填充**：`initialDataCallback` 只在文件第一次创建时写入示例数据
- ✅ **版本迁移**：`schemaVersion` 和 `migrationCallback`
- ✅ **响应式 UI**：监听查询结果，数据变化后自动刷新列表

## 📱 应用界面

- 输入姓名后回车或点加号，添加人员和一条上海地址
- 列表显示姓名、年龄、邮箱、地址和 `ObjectId`
- 编辑会在姓名后加上“(更新)”，并把年龄加 1
- 删除会同时删掉关联的地址

## 🛠️ 技术栈

- **Flutter**: 3.27+
- **Realm**: 20.2.0
- **Dart**: 3.6+

## 📦 安装与运行

### 环境要求
- Flutter SDK ≥ 3.27（Dart SDK ≥ 3.6）
- Android Studio / VS Code

### 安装步骤

1. **进入示例**
```bash
cd realm_example
```

2. **安装依赖**
```bash
flutter pub get
```

3. **生成 Realm 模型**

模型类以 `_` 开头，并标注 `@RealmModel()`。生成命令会写出同目录下的 `person.realm.dart`，这个文件需要提交到版本库。

```bash
dart run realm generate
```

`build.yaml` 把生成范围限定在 `lib/models`。Realm 20.2.0 自带的 analyzer 读不了更新版本 Flutter SDK 里的语法，全量扫描会失败。

4. **运行项目**
```bash
flutter run
```

跑测试前先安装原生库：

```bash
dart run realm install
flutter test
```

## 📁 项目结构

```
realm_example/
├── lib/
│   ├── main.dart                  # 主应用入口
│   ├── models/
│   │   ├── person.dart            # Person、Address 模型
│   │   └── person.realm.dart      # Realm 生成的代码
│   ├── database/
│   │   └── database_manager.dart  # 数据库管理器
│   └── repositories/
│       └── person_repository.dart # Person 仓库类
├── test/
│   └── person_repository_test.dart
├── build.yaml                   # 只为模型文件生成代码
├── pubspec.yaml
└── README.md
```

## 🔧 核心组件

### 1. 数据模型

```dart
@RealmModel()
class _Person {
  @PrimaryKey()
  late ObjectId id;

  late String name;
  late int age;
  String? email;

  // 一对一关系必须是可选的。
  late _Address? address;
}
```

### 2. 打开本地数据库

```dart
final config = Configuration.local(
  [Person.schema, Address.schema],
  schemaVersion: 1,
  migrationCallback: _migrate,
  initialDataCallback: _seed,
);
final realm = Realm(config);
```

`initialDataCallback` 执行时写入事务已经打开，直接调用 `realm.add`。

### 3. 写入、查询和监听

```dart
realm.write(() {
  realm.add(Person(ObjectId(), '李四', 30, email: 'lisi@example.com'));
});

final people = realm.query<Person>(r'name == $0', ['李四']);

people.changes.listen((changes) {
  changes.results; // 当前查询结果
  changes.inserted;
  changes.deleted;
  changes.modified;
});
```

参数占位符直接写 `$0`，例如 `r'name == $0'`。

## 💡 关键特性说明

### 关系
- Person 和 Address 是可选的一对一关系
- 新建人员时把未入库的 `Address` 传给构造函数，`realm.add` 会一起保存
- 删除人员时要先解除关系，再删除地址对象。Realm 不会自动级联删除普通对象

### 版本迁移
- 模型变化后提高 `schemaVersion`
- 新增或删除字段可以由 Realm 自动处理
- 重命名字段要在 `migrationCallback` 里调用 `migration.renameProperty`
- 主键类型不能从旧示例的 `String` 原地改成 `ObjectId`，所以本示例使用新文件 `realm-example.realm`

### 数据文件
数据库位于 `Configuration.defaultStoragePath` 下的 `realm-example.realm`，不是旧示例的 `default.realm`。

## ⚠️ 注意事项

1. **模型定义**：类名以下划线开头，并加上 `@RealmModel()`
2. **代码生成**：改完模型后运行 `dart run realm generate`，并提交生成文件
3. **主键**：每个普通对象使用 `@PrimaryKey()`，这里用 `ObjectId()`
4. **写入事务**：增删改都放在 `realm.write` 里
5. **同步**：20.0 起 SDK 不再包含 Atlas Device Sync

## 🔗 相关资源

- [realm 20.2.0](https://pub.dev/packages/realm)
- [Realm Flutter 快速开始](https://www.mongodb.com/docs/atlas/device-sdks/sdk/flutter/quick-start/)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 📄 许可证

本项目采用 MIT 许可证。

---

**返回 [项目总览](../README.md)**
