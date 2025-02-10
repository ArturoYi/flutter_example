# Realm Flutter 示例项目

这是一个演示如何在Flutter项目中使用Realm数据库的示例项目。Realm是一个现代化的移动数据库，提供了简单、快速且功能强大的数据存储解决方案。

## 项目特点

- 实时同步：支持实时数据同步和离线存储
- 跨平台：完整支持iOS、Android和其他主流平台
- 响应式：内置数据变化通知机制
- 简单易用：直观的API设计，无需编写复杂SQL

## 环境要求

- Flutter SDK 3.0.0 或更高版本
- Dart SDK 2.17.0 或更高版本
- Android Studio / VS Code
- Android SDK（用于Android开发）
- Xcode 13.0或更高版本（用于iOS/macOS开发）

## 快速开始

1. 克隆项目：
```bash
git clone [项目地址]
cd realm_example
```

2. 安装依赖：
```bash
flutter pub get
```

3. 运行项目：
```bash
flutter run
```

## 基本用法

### 1. 定义数据模型

在`lib/models`目录下定义你的数据模型类，例如：

```dart
class Task extends RealmObject {
  @PrimaryKey()
  late ObjectId id;
  
  late String title;
  String? description;
  late bool isCompleted;
}
```

### 2. 数据操作

```dart
// 初始化Realm
final config = Configuration.local([Task.schema]);
final realm = Realm(config);

// 插入数据
realm.write(() {
  realm.add(Task()
    ..title = '完成作业'
    ..isCompleted = false);
});

// 查询数据
final tasks = realm.all<Task>();

// 更新数据
realm.write(() {
  task.isCompleted = true;
});

// 删除数据
realm.write(() {
  realm.delete(task);
});
```

## 进阶功能

- 实时数据同步
- 数据加密
- 复杂查询和排序
- 数据迁移
- 数据订阅

## 常见问题

1. **Q: 如何实现数据同步？**
   A: 需要配置MongoDB Realm后端服务，并在应用中设置同步配置。

2. **Q: 数据库文件存储在哪里？**
   A: 在应用的文档目录下，可以通过Configuration配置自定义路径。

3. **Q: 如何处理并发访问？**
   A: Realm自动处理并发访问，使用write事务确保数据一致性。

## 贡献

欢迎提交问题和改进建议！

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件
