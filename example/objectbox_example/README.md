# ObjectBox 数据库示例

这是一个使用 [ObjectBox](https://objectbox.io/) 数据库的 Flutter 示例项目，展示了如何在 Flutter 应用中实现高性能的本地数据存储。

## 📋 项目简介

ObjectBox 是一个专为移动和物联网设备设计的高性能 NoSQL 对象数据库，具有以下特点：

- ⚡ **极速性能**：比 SQLite 快 10 倍
- 💾 **内存占用小**：高效的内存管理
- 🎯 **纯 Dart 实现**：无需本地桥接，开发体验更佳
- 🔒 **强类型 API**：编译时类型安全
- 🔄 **自动版本管理**：简化数据库迁移

## 🚀 功能特性

本示例实现了以下功能：

- ✅ **任务管理**：创建、读取、更新、删除任务
- ✅ **状态切换**：任务完成状态的实时切换
- ✅ **数据持久化**：数据自动保存到本地数据库
- ✅ **版本管理**：通过 UID 管理字段变更
- ✅ **响应式 UI**：`Query.watch` 在数据变更后自动更新界面
- ✅ **异步写入**：添加、更新、删除使用 `putAsync` / `removeAsync`

## 📱 应用截图

应用提供了一个简洁的任务管理界面：
- 任务列表显示（ID、标题、完成状态）
- 删除任务功能
- 切换任务完成状态
- 添加新任务

## 🛠️ 技术栈

- **Flutter**: 3.29+
- **ObjectBox**: 5.3.2
- **Dart**: 3.7+

## 📦 安装与运行

### 环境要求
- Flutter SDK ≥ 3.29（Dart SDK ≥ 3.7）
- iOS 15 / macOS 12（ObjectBox 本身要求 macOS 11，当前 Flutter 模板要求 12）
- Android Studio / VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd example/objectbox_example
```

2. **安装依赖**
```bash
flutter pub get
```

3. **生成 ObjectBox 代码**
```bash
dart run build_runner build
```

4. **运行项目**
```bash
flutter run
```

## 📁 项目结构

```
objectbox_example/
├── lib/
│   ├── main.dart                  # 主应用入口
│   ├── objectbox.g.dart           # ObjectBox 生成的代码
│   ├── objectbox-model.json       # ObjectBox 模型配置
│   ├── models/
│   │   └── task.dart              # Task 实体类定义
│   ├── objectbox/
│   │   └── database_manager.dart  # 数据库管理器
│   └── repositories/
│       └── task_repository.dart   # Task 仓库类
├── pubspec.yaml                   # 项目依赖配置
└── README.md                      # 项目说明文档
```

## 🔧 核心组件

### 1. 数据模型 (Task)

```dart
@Entity()
class Task {
  @Id()
  int id;

  @Property(uid: 1)
  String title;
  
  @Property(uid: 2)
  String? description;
  
  @Property(uid: 3)
  bool isCompleted;
  
  @Property(type: PropertyType.date, uid: 4)
  DateTime createdAt;
}
```

### 2. 数据库管理器

负责 ObjectBox 数据库的初始化和配置。

### 3. 仓库层

封装数据访问逻辑，提供 CRUD 操作接口。

## 💡 关键特性说明

### 版本管理
ObjectBox 把字段的稳定 UID 记在 `objectbox-model.json` 里：
- 新增或删除字段后，重新运行 `dart run build_runner build`，生成器会更新模型
- 重命名字段时保留原来的 UID（可在 `@Property(uid: ...)` 上显式写出），否则会被当成删除旧字段并新增字段
- 字段类型变化不会自动转换已有数据，需要自行迁移

### 性能优化
- 使用 `@Id()` 注解定义主键
- 通过 `@Property()` 注解配置字段属性
- 支持日期类型和可选字段

## 🔍 使用示例

### 添加任务
```dart
await taskRepository.addTask(
  Task(title: "新任务标题")
);
```

### 查询所有任务
```dart
List<Task> tasks = taskRepository.getAllTasks();
```

### 监听任务列表
```dart
Stream<List<Task>> tasks = taskRepository.watchAllTasks();
```

### 更新任务
```dart
task.isCompleted = true;
await taskRepository.updateTask(task);
```

### 删除任务
```dart
await taskRepository.deleteTask(taskId);
```

## ⚠️ 注意事项

1. **代码生成**：修改模型后需要重新运行 `build_runner`
2. **版本管理**：字段类型改变时需要特别处理
3. **初始化**：确保在使用前完成数据库初始化
4. **UID 管理**：每个字段的 UID 必须唯一，重命名时不要更换已有 UID
5. **平台**：iOS 最低 15，macOS 最低 12。沙盒 macOS 使用 App Group `objectbox.example`
6. **数据库目录**：Store 位于文档目录下的 `obx-example`。这和 4.1.0 直接写在文档目录根下的数据不是同一个库

## 🔗 相关资源

- [ObjectBox 官方文档](https://docs.objectbox.io/)
- [ObjectBox Flutter 示例](https://github.com/objectbox/objectbox-dart/tree/v5.3.2/objectbox/example/flutter/objectbox_demo)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 📄 许可证

本项目采用 MIT 许可证。

---

**返回 [项目总览](../README.md)**
