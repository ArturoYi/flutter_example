# ObjectBox Flutter 示例项目

这是一个演示如何在Flutter项目中使用ObjectBox数据库的示例项目。ObjectBox是一个高性能的NoSQL数据库，专为移动和物联网应用设计。

## 项目特点

- 高性能：ObjectBox提供极快的读写速度
- 易用性：简单直观的API设计
- 类型安全：完全支持Dart类型系统
- 跨平台：支持Android、iOS、macOS、Linux和Windows

## 环境要求

- Flutter SDK 3.0.0 或更高版本
- Dart SDK 2.17.0 或更高版本
- Android Studio / VS Code
- Android SDK（适用于Android开发）
- Xcode（适用于iOS/macOS开发）

## 快速开始

1. 克隆项目：
```bash
git clone [项目地址]
cd objectbox_example
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
@Entity()
class Task {
  @Id()
  int id = 0;
  
  String title;
  String? description;
  bool isCompleted;
  
  Task({required this.title, this.description, this.isCompleted = false});
}
```

### 2. 数据操作

```dart
// 插入数据
final task = Task(title: '完成作业');
final id = objectBox.taskBox.put(task);

// 查询数据
final tasks = objectBox.taskBox.getAll();

// 更新数据
task.isCompleted = true;
objectBox.taskBox.put(task);

// 删除数据
objectBox.taskBox.remove(task.id);
```

## 进阶功能

- 关系查询
- 异步操作
- 数据监听
- 事务处理
- 数据迁移

## 常见问题

1. **Q: 如何处理数据库版本更新？**
   A: ObjectBox会自动处理简单的模式更改。对于复杂的更改，需要手动迁移数据。

2. **Q: 是否支持加密？**
   A: 是的，ObjectBox支持数据库加密，需要在初始化时配置。

3. **Q: 如何优化查询性能？**
   A: 使用索引、限制查询结果数量、避免不必要的关系查询等。

## 贡献

欢迎提交问题和改进建议！

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件
