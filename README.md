# flutter-cookbook

我用这个仓库记下用过的 Flutter package。版本、生成步骤和调用方式写在文档站：[flutter-cookbook](https://arturoyi.github.io/flutter_example/)。

本地预览文档，在仓库根目录执行：

```bash
npm install
npm run docs:dev
```

浏览器打开 `http://localhost:5173`。需要 Node.js 22+。跑 Flutter 不需要 Node.js，见下面的快速开始。

推送到 `main` 后，GitHub Actions 会把文档发布到上面的地址。仓库需要在 Settings → Pages → Build and deployment 里把 Source 设为 GitHub Actions。内页地址带 `.html`，例如 [ObjectBox](https://arturoyi.github.io/flutter_example/database/objectbox.html)。

## 📋 项目总览

本项目包含以下示例：

| 示例项目 | 版本 | 描述 | 文档 |
|----------|------|------|------|
| [ObjectBox](./example/objectbox_example/README.md) | 5.3.2 | 高性能 NoSQL 对象数据库示例 | [文档](https://arturoyi.github.io/flutter_example/database/objectbox.html) |
| [Realm](./example/realm_example/README.md) | 20.2.0 | 跨平台移动数据库引擎示例 | [文档](https://arturoyi.github.io/flutter_example/database/realm.html) |
| [Drift](./example/drift_example/README.md) | 2.35.3 | 基于 SQLite 的类型安全关系库示例 | [文档](https://arturoyi.github.io/flutter_example/database/drift.html) |
| [sqflite](./example/sqflite_example/README.md) | 2.4.5 | SQLite 插件的待办示例 | [文档](https://arturoyi.github.io/flutter_example/database/sqflite.html) |
| [Provider](./example/provider_example/README.md) | 6.1.5+1 | InheritedWidget 风格的状态管理 | [文档](https://arturoyi.github.io/flutter_example/state/provider.html) |
| [GetX](./example/getx_example/README.md) | 4.7.3 | 响应式状态、依赖注入和路由 | [文档](https://arturoyi.github.io/flutter_example/state/getx.html) |
| [Bloc / Cubit](./example/bloc_example/README.md) | bloc 9.2.1 | 事件、Cubit 和可追踪的状态变化 | [文档](https://arturoyi.github.io/flutter_example/state/bloc.html) |
| [Riverpod](./example/riverpod_example/README.md) | 3.4.3 | 不依赖 BuildContext 的 Provider | [文档](https://arturoyi.github.io/flutter_example/state/riverpod.html) |
| [Async Redux](./example/redux_example/README.md) | 29.2.3 | 单一状态树。原版 redux 包无法在 Dart 3 上解析 | [文档](https://arturoyi.github.io/flutter_example/state/redux.html) |
| [Signals](./example/signals_example/README.md) | 7.1.0 | signal、computed 和 effect | [文档](https://arturoyi.github.io/flutter_example/state/signals.html) |
| [flutter_rust_bridge](./example/flutter_rust_bridge_example/README.md) | 2.13.0 | 在 Flutter 里调用 Rust | [文档](https://arturoyi.github.io/flutter_example/rust/) |

## 🚀 快速开始

### 环境要求
- **Flutter SDK**: 状态管理、Drift、sqflite 和 flutter_rust_bridge 示例需要 3.47+。ObjectBox 需要 3.29+，Realm 需要 3.27+
- **Dart SDK**: 状态管理、Drift、sqflite 和 flutter_rust_bridge 示例需要 3.13+。ObjectBox 需要 3.7+，Realm 需要 3.6+
- **开发工具**: Android Studio / VS Code
- **Git**
- **Rust**: 仅 `flutter_rust_bridge_example` 需要，通过 [rustup](https://rustup.rs) 安装 stable

### 克隆项目
```bash
git clone <repository-url>
cd flutter_example
```

### 安装、生成、运行与清理

在仓库根目录执行。示例都在 `example/` 下。不带示例名时，`install`、`generate`、`clean` 会处理全部示例；`./scripts/demo.sh` 会列出当前示例目录。脚本参数仍是目录名，例如 `objectbox_example`。

```bash
# 为所有 demo 安装依赖
./scripts/demo.sh install

# 为需要代码生成的 demo 重新生成代码
./scripts/demo.sh generate

# 清理所有 demo 的本地依赖产物和构建缓存
./scripts/demo.sh clean
```

只处理某一个示例时，在命令后加上目录名。`run` 必须指定示例，后面的参数会传给 `flutter run`：

```bash
./scripts/demo.sh install objectbox_example
./scripts/demo.sh generate drift_example
./scripts/demo.sh generate realm_example
./scripts/demo.sh generate flutter_rust_bridge_example
./scripts/demo.sh run provider_example -d macos
./scripts/demo.sh clean sqflite_example
```

`install` 会在每个示例里执行 `flutter pub get`。

`generate` 按示例选择生成命令：

| 示例 | 命令 |
|------|------|
| `objectbox_example`、`drift_example` | `dart run build_runner build --delete-conflicting-outputs` |
| `realm_example` | `dart run realm generate` |
| `flutter_rust_bridge_example` | `flutter_rust_bridge_codegen generate` |
| 其余示例 | 跳过 |

`flutter_rust_bridge` 的生成器要和依赖里的 2.13.0 一致。脚本会使用 PATH 或 `~/.cargo/bin` 里的 `flutter_rust_bridge_codegen`；还没有时先执行：

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
```

`run` 使用和 `install` 相同的 Flutter。Flutter 的查找顺序是：示例自带的 `.fvm/flutter_sdk`、当前 PATH、`~/fvm/versions/stable`、`fvm flutter`。`drift_example`、`realm_example`、`sqflite_example` 没有提交 `.fvm`，会落到后面几项。

`clean` 会执行 `flutter clean`，并删除各示例目录内的 `.dart_tool`、`build`、CocoaPods、Gradle 等本地依赖和缓存。`flutter_rust_bridge_example` 还会删除 `rust/target`，以及 `rust_builder` 和 Cargokit 的本地构建缓存。不会删除全局 `~/.pub-cache`，也不会改动 `.fvm` 里的 Flutter SDK。

## 🛠️ 运行示例

### 运行 ObjectBox 示例

ObjectBox 5.3.2 需要 Flutter 3.29+（Dart 3.7+）和 iOS 15。当前 Flutter 模板的 macOS 最低版本是 12。

```bash
./scripts/demo.sh install objectbox_example
./scripts/demo.sh generate objectbox_example
./scripts/demo.sh run objectbox_example
```

### 运行 Realm 示例

Realm 20.2.0 需要 Flutter 3.27+（Dart 3.6+）。20.0 起已移除 Atlas Device Sync，本示例只使用本地数据库。

```bash
./scripts/demo.sh install realm_example
./scripts/demo.sh generate realm_example
./scripts/demo.sh run realm_example
```

### 运行 Drift 示例

Drift 2.35.3 在 SQLite 上生成类型安全的查询。改表之后需要重新生成代码。

```bash
./scripts/demo.sh install drift_example
./scripts/demo.sh generate drift_example
./scripts/demo.sh run drift_example
```

### 运行 sqflite 示例

sqflite 2.4.5 直接执行 SQL。Android、iOS、macOS 使用插件；Linux 和 Windows 使用 `sqflite_common_ffi`。

```bash
./scripts/demo.sh install sqflite_example
./scripts/demo.sh run sqflite_example
```

### 运行状态管理示例

六个示例做同一组事情：局部刷新、待办和派生状态、异步加载、登录与购物车、页面级作用域。每个示例的概览页和 README 写了该方案的优势、劣势，以及这里用到的 API。

| 目录 | 库 |
|------|----|
| `provider_example` | provider 6.1.5+1 |
| `getx_example` | get 4.7.3（稳定版，不含 5.0 预发布） |
| `bloc_example` | bloc 9.2.1、flutter_bloc 9.1.1 |
| `riverpod_example` | flutter_riverpod 3.4.3 |
| `redux_example` | async_redux 29.2.3 |
| `signals_example` | signals 7.1.0 |

`redux` 5.0.0 和 `flutter_redux` 0.10.0 的 SDK 约束仍是 Dart 2，当前 Flutter 不能依赖它们，所以 Redux 示例用 Async Redux。

```bash
./scripts/demo.sh install provider_example
./scripts/demo.sh run provider_example
```

把目录换成 `getx_example`、`bloc_example`、`riverpod_example`、`redux_example` 或 `signals_example` 即可。这些示例不需要代码生成，需要 Flutter 3.47+（Dart 3.13+）。

### 运行 Flutter + Rust 示例

[flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) 2.13.0 生成 Dart 和 Rust 之间的胶水。界面按同步调用、工作线程、结构体、错误、Rust 对象和 `Stream` 分成六节。

需要 Rust stable。Android 构建还需要 NDK。改 `rust/src/api` 之后，用上面的 `generate` 重新生成胶水。生成器安装和更多说明写在示例 README 里。

```bash
./scripts/demo.sh install flutter_rust_bridge_example
./scripts/demo.sh run flutter_rust_bridge_example
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