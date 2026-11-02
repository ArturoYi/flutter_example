# Flutter 示例项目集合

这是一个 Flutter 示例项目集合，展示了不同技术方案在 Flutter 应用中的实现。

## 📋 项目总览

本项目包含以下示例：

| 示例项目 | 版本 | 描述 | 文档 |
|----------|------|------|------|
| [ObjectBox](./objectbox_example/README.md) | 5.3.2 | 高性能 NoSQL 对象数据库示例 | [查看详情](./objectbox_example/README.md) |
| [Realm](./realm_example/README.md) | 20.2.0 | 跨平台移动数据库引擎示例 | [查看详情](./realm_example/README.md) |
| [Drift](./drift_example/README.md) | 2.35.3 | 基于 SQLite 的类型安全关系库示例 | [查看详情](./drift_example/README.md) |
| [sqflite](./sqflite_example/README.md) | 2.4.5 | SQLite 插件的待办示例 | [查看详情](./sqflite_example/README.md) |

## 🚀 快速开始

### 环境要求
- **Flutter SDK**: Drift 和 sqflite 示例需要 3.47+。ObjectBox 需要 3.29+，Realm 需要 3.27+
- **Dart SDK**: Drift 和 sqflite 示例需要 3.13+。ObjectBox 需要 3.7+，Realm 需要 3.6+
- **开发工具**: Android Studio / VS Code
- **Git**

### 克隆项目
```bash
git clone <repository-url>
cd flutter_example
```

### 安装与清理依赖

在仓库根目录执行：

```bash
# 为所有 demo 安装依赖
./scripts/demo.sh install

# 清理所有 demo 的本地依赖产物和构建缓存
./scripts/demo.sh clean
```

只处理某一个示例时，在命令后加上目录名：

```bash
./scripts/demo.sh install objectbox_example
./scripts/demo.sh clean realm_example
./scripts/demo.sh install drift_example
./scripts/demo.sh install sqflite_example
```

`install` 会在每个示例里执行 `flutter pub get`。示例自带 `.fvm` 时使用该 Flutter SDK，否则使用当前环境中的 Flutter。

`clean` 会执行 `flutter clean`，并删除各示例目录内的 `.dart_tool`、`build`、CocoaPods、Gradle 等本地依赖和缓存。不会删除全局 `~/.pub-cache`，也不会改动 `.fvm` 里的 Flutter SDK。

## 🛠️ 运行示例

### 运行 ObjectBox 示例

ObjectBox 5.3.2 需要 Flutter 3.29+（Dart 3.7+）和 iOS 15。当前 Flutter 模板的 macOS 最低版本是 12。

```bash
cd objectbox_example
flutter pub get
dart run build_runner build
flutter run
```

### 运行 Realm 示例

Realm 20.2.0 需要 Flutter 3.27+（Dart 3.6+）。20.0 起已移除 Atlas Device Sync，本示例只使用本地数据库。

```bash
cd realm_example
flutter pub get
dart run realm generate
flutter run
```

### 运行 Drift 示例

Drift 2.35.3 在 SQLite 上生成类型安全的查询。改表之后需要重新生成代码。

```bash
cd drift_example
flutter pub get
dart run build_runner build
flutter run
```

### 运行 sqflite 示例

sqflite 2.4.5 直接执行 SQL。Android、iOS、macOS 使用插件；Linux 和 Windows 使用 `sqflite_common_ffi`。

```bash
cd sqflite_example
flutter pub get
flutter run
```

## 🤝 贡献指南

欢迎提交问题和贡献代码！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详情请见 [LICENSE](LICENSE) 文件。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 📧 邮箱：your-email@example.com
- 🐛 问题反馈：[GitHub Issues](https://github.com/username/flutter_example/issues)
- 💬 讨论：[GitHub Discussions](https://github.com/username/flutter_example/discussions)

---

**⭐ 如果这个项目对您有帮助，请给我们一个星标！**