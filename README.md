# Flutter 数据库插件示例项目

这个项目展示了在 Flutter 应用中使用不同数据库插件的实现方案。

## 目录
- [ObjectBox 示例](#objectbox-示例)
- [Realm 示例](#realm-示例)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [性能对比](#性能对比)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)
- [许可证](#许可证)

## ObjectBox 示例
[ObjectBox](https://objectbox.io/) 是一个高性能的 NoSQL 对象数据库，专为移动和物联网设备设计。

### 特点
- 速度快：比 SQLite 快 10 倍
- 内存占用小
- 纯 Dart 实现，无需本地桥接
- 强类型 API

### 示例内容
- 实体模型定义
- CRUD 操作实现
- 查询与索引优化
- 关系映射（一对多、多对多）
- 事务管理

## Realm 示例
[Realm](https://realm.io/) 是一个跨平台的移动数据库引擎，提供对象存储和同步功能。

### 特点
- 易于使用的对象 API
- 跨平台一致性
- 实时同步能力
- 支持加密

### 示例内容
- 数据模型定义
- 基础数据操作
- 复杂查询示例
- 数据监听与变更通知
- 迁移策略

## 环境要求
- Flutter SDK: ≥ 3.0.0
- Dart SDK: ≥ 2.17.0
- 开发工具: [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/)
- Git

## 快速开始
1. 克隆项目
```bash
git clone https://github.com/username/flutter_database_examples.git
cd flutter_database_examples
```

2. 进入对应示例目录
```bash
cd objectbox_example  # 或 realm_example
```

3. 安装依赖
```bash
flutter pub get
```

4. 运行项目
```bash
flutter run
```

## 项目结构

整个项目由两个主要示例组成：

### ObjectBox 示例结构
```
objectbox_example/
├── lib/
│   ├── main.dart                  # 主应用入口
│   ├── objectbox.g.dart           # ObjectBox 生成的代码
│   ├── objectbox-model.json       # ObjectBox 模型配置
│   ├── models/                    # 数据模型定义
│   │   └── task.dart              # Task 实体类定义
│   ├── objectbox/                 # ObjectBox 相关配置
│   │   └── database_manager.dart  # 数据库管理器
│   └── repositories/              # 仓库层，处理数据逻辑
│       └── task_repository.dart   # Task 仓库类
├── pubspec.yaml                   # 项目依赖配置
└── README.md                      # 项目说明文档
```

### Realm 示例结构
```
realm_example/
├── lib/
│   ├── main.dart                  # 主应用入口
│   ├── models/                    # 数据模型定义
│   │   ├── person.dart            # Person 实体类定义
│   │   └── person.realm.dart      # Realm 生成的代码
│   ├── database/                  # 数据库相关配置
│   │   └── database_manager.dart  # 数据库管理器
│   └── repositories/              # 仓库层，处理数据逻辑
│       └── person_repository.dart # Person 仓库类
├── pubspec.yaml                   # 项目依赖配置
└── README.md                      # 项目说明文档
```

## 主要功能实现

### ObjectBox 实现
ObjectBox 示例实现了一个简单的任务管理应用：
- **模型定义**：使用 `@Entity()`、`@Id()` 和 `@Property()` 注解定义实体
- **数据操作**：实现了任务的增删查改
- **版本管理**：通过 UID 管理字段变更，简化数据库版本迁移

### Realm 实现
Realm 示例实现了一个人员信息管理应用：
- **模型定义**：使用 `@RealmModel()` 和 `@PrimaryKey()` 注解定义实体
- **关系处理**：展示了一对一关系（Person 和 Address）
- **数据操作**：实现了人员信息的增删查改
- **版本迁移**：通过 `schemaVersion` 和 `migrationCallback` 处理数据库版本升级

## 性能对比

以下是两种数据库在不同场景下的性能对比：

| 操作 | ObjectBox | Realm | 说明 |
|------|-----------|-------|------|
| 插入 | 极快 | 快 | ObjectBox 在批量插入时表现更佳 |
| 查询 | 快 | 极快 | Realm 在复杂查询上更有优势 |
| 更新 | 极快 | 快 | ObjectBox 简单更新操作性能更好 |
| 删除 | 极快 | 快 | ObjectBox 在批量删除时表现更佳 |
| 内存占用 | 低 | 中 | ObjectBox 一般内存效率更高 |
| 启动时间 | 快 | 中 | ObjectBox 初始化速度略快 |

### 选择建议
- **ObjectBox**：适合本地数据存储，追求极致性能的应用
- **Realm**：适合需要数据同步功能，或有复杂查询需求的应用

## 常见问题

### ObjectBox
1. **版本管理**：
   - 通过给字段添加 `uid` 参数管理字段变更
   - 不需要手动管理版本，框架自动处理大部分情况
   - 字段类型改变的情况需要特别处理

2. **初始化问题**：
   - 确保在使用前完成初始化
   - 可以使用单例模式管理数据库实例

### Realm
1. **版本迁移**：
   - 在初始化时设置 `schemaVersion`
   - 通过 `migrationCallback` 处理架构变更
   - 需要手动编写迁移逻辑

2. **同步功能**：
   - 需要 Realm 云服务或自建服务器
   - 需要额外的身份验证和配置

## 贡献指南

欢迎提交问题和贡献代码！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 更多资源

- [ObjectBox 官方文档](https://docs.objectbox.io/)
- [ObjectBox Flutter 示例](https://github.com/objectbox/objectbox-dart/tree/main/objectbox_flutter_libs)
- [Realm 官方文档](https://docs.mongodb.com/realm/)
- [Realm Flutter SDK](https://github.com/realm/realm-dart)

## 许可证

本项目采用 MIT 许可证 - 详情请见 [LICENSE](LICENSE) 文件。