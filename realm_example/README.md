# Realm 数据库示例

这是一个使用 [Realm](https://realm.io/) 数据库的 Flutter 示例项目，展示了如何在 Flutter 应用中实现跨平台的本地数据存储和同步功能。

## 📋 项目简介

Realm 是一个跨平台的移动数据库引擎，提供对象存储和实时同步功能，具有以下特点：

- 🌐 **跨平台一致性**：支持 Android、iOS、Flutter 等多个平台
- 🔄 **实时同步**：支持云端数据同步
- 🛡️ **数据加密**：内置加密功能保护敏感数据
- 🎯 **对象 API**：直观的对象导向数据访问
- ⚡ **高性能**：优化的查询引擎和内存管理

## 🚀 功能特性

本示例实现了以下功能：

- ✅ **人员管理**：创建、读取、更新、删除人员信息
- ✅ **地址关联**：一对一关系映射（Person 和 Address）
- ✅ **数据持久化**：数据自动保存到本地数据库
- ✅ **版本迁移**：数据库架构版本管理
- ✅ **响应式 UI**：数据变更自动更新界面

## 📱 应用截图

应用提供了一个人员信息管理界面：
- 人员列表显示（姓名、年龄、邮箱、地址信息）
- 编辑人员信息功能
- 删除人员功能
- 添加新人员（自动关联地址信息）

## 🛠️ 技术栈

- **Flutter**: 3.3.4+
- **Realm**: 20.0.1
- **Dart**: 3.3.4+

## 📦 安装与运行

### 环境要求
- Flutter SDK ≥ 3.3.4
- Dart SDK ≥ 3.3.4
- Android Studio / VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd realm_example
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行项目**
```bash
flutter run
```

## 📁 项目结构

```
realm_example/
├── lib/
│   ├── main.dart                  # 主应用入口
│   ├── models/
│   │   ├── person.dart            # Person 实体类定义
│   │   └── person.realm.dart      # Realm 生成的代码
│   ├── database/
│   │   └── database_manager.dart  # 数据库管理器
│   └── repositories/
│       └── person_repository.dart # Person 仓库类
├── pubspec.yaml                   # 项目依赖配置
└── README.md                      # 项目说明文档
```

## 🔧 核心组件

### 1. 数据模型

#### Person 模型
```dart
@RealmModel()
class _Person {
  @PrimaryKey()
  late String id;
  
  late String name;
  late int age;
  String? email;
  
  late _Address? addresses;
}
```

#### Address 模型
```dart
@RealmModel()
class _Address {
  @PrimaryKey()
  late String id;
  
  late String street;
  late String city;
  late String country;
  String? postalCode;
}
```

### 2. 数据库管理器

负责 Realm 数据库的初始化、配置和版本管理。

### 3. 仓库层

封装数据访问逻辑，提供 CRUD 操作接口。

## 💡 关键特性说明

### 关系映射
- **一对一关系**：Person 和 Address 之间的一对一关联
- **可选关系**：Address 字段为可选，支持空值

### 版本管理
- 通过 `schemaVersion` 管理数据库版本
- 使用 `migrationCallback` 处理架构变更
- 支持数据迁移和字段变更

### 数据同步
- 支持 Realm 云服务同步
- 需要额外的身份验证和配置
- 本示例专注于本地数据存储

## 🔍 使用示例

### 创建人员
```dart
final person = _personRepository.createPerson(
  '张三', 
  25, 
  email: 'zhangsan@example.com'
);
```

### 添加地址信息
```dart
_personRepository.addAddress(
  person,
  '某某路某某号',
  '上海',
  '中国',
  postalCode: '200000',
);
```

### 查询所有人员
```dart
List<Person> persons = _personRepository.getAllPersons();
```

### 更新人员信息
```dart
_personRepository.updatePerson(
  person,
  name: '${person.name}(更新)',
  age: person.age + 1,
);
```

### 删除人员
```dart
_personRepository.deletePerson(person);
```

## 🔄 数据库版本迁移

### 版本配置
```dart
final config = Configuration.local(
  [Person.schema, Address.schema],
  schemaVersion: 1,
  migrationCallback: (migration, oldSchemaVersion) {
    // 处理版本迁移逻辑
  },
);
```

### 迁移策略
- 增加 `schemaVersion` 触发迁移
- 在 `migrationCallback` 中处理字段变更
- 支持字段重命名、类型转换等操作

## ⚠️ 注意事项

1. **模型定义**：使用 `@RealmModel()` 注解定义模型
2. **主键设置**：每个模型都需要 `@PrimaryKey()` 字段
3. **关系管理**：注意关系的可选性和约束
4. **版本迁移**：架构变更时需要手动处理迁移逻辑
5. **同步功能**：需要额外的 Realm 云服务配置

## 🔗 相关资源

- [Realm 官方文档](https://docs.mongodb.com/realm/)
- [Realm Flutter SDK](https://github.com/realm/realm-dart)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 📄 许可证

本项目采用 MIT 许可证。

---

**返回 [项目总览](../README.md)**
