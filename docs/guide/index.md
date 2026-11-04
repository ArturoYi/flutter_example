---
description: flutter-cookbook 以独立示例记录 Flutter package 的版本、生成步骤与调用方式，分为存储、状态管理与其他。
---

# 项目介绍

flutter-cookbook 收录已经接入过的 Flutter package。每个 package 单独占一个目录，目录之间不共享业务代码，因此一种方案的依赖和生成步骤不会混进另一种方案。文档页与目录一一对应，写明当前版本、是否需要代码生成、示例里调用过的 API，以及升级时需要核对的约束。接入时对照示例；依赖升级时，从同一页判断迁移落在哪些 API 上。

文档站由 VitePress 构建，源文件位于 `docs/`。预览文档需要 Node.js 22 及以上。运行示例只依赖该目录声明的 Flutter 与 Dart，不依赖 Node.js。

```bash
git clone https://github.com/ArturoYi/flutter_example.git
cd flutter_example
```

调试入口见 [launch.json](/guide/launch)。依赖安装、代码生成、运行与清理见 [脚本](/guide/scripts)。

## 存储

这一组处理本地持久化。ObjectBox 与 Realm 以对象模型写入，Drift 在 SQLite 上生成类型安全查询，sqflite 直接执行 SQL。ObjectBox 要求 Flutter 3.29+（Dart 3.7+），Realm 要求 Flutter 3.27+（Dart 3.6+），Drift 与 sqflite 要求 Flutter 3.47+（Dart 3.13+）。

| Package | 版本 | 目录 |
| --- | --- | --- |
| [ObjectBox](/database/objectbox) | 5.3.2 | `objectbox_example` |
| [Realm](/database/realm) | 20.2.0 | `realm_example` |
| [Drift](/database/drift) | 2.35.3 | `drift_example` |
| [sqflite](/database/sqflite) | 2.4.5 | `sqflite_example` |

## 状态管理

这一组用同一套界面比较六种写法：局部刷新、待办与派生状态、异步加载、登录与购物车、页面级作用域。示例要求 Flutter 3.47+（Dart 3.13+），不生成代码。

| Package | 版本 | 目录 |
| --- | --- | --- |
| [Provider](/state/provider) | 6.1.5+1 | `provider_example` |
| [GetX](/state/getx) | 4.7.3 | `getx_example` |
| [Bloc / Cubit](/state/bloc) | bloc 9.2.1 | `bloc_example` |
| [Riverpod](/state/riverpod) | 3.4.3 | `riverpod_example` |
| [Async Redux](/state/redux) | 29.2.3 | `redux_example` |
| [Signals](/state/signals) | 7.1.0 | `signals_example` |

GetX 固定在稳定版 `get` 4.7.3，不使用 5.0 预发布。`redux` 与 `flutter_redux` 的 SDK 约束仍停留在 Dart 2，当前 Flutter 无法解析，因此 Redux 示例采用 Async Redux。Bloc 示例直接依赖 `flutter_bloc` 9.1.1，传递依赖为 `bloc` 9.2.1。

## 其他

[flutter_rust_bridge](/rust/) 2.13.0 生成 Dart 与 Rust 之间的绑定。示例按同步调用、工作线程、结构体、错误、Rust 对象和 `Stream` 分节。Flutter 要求 3.47+（Dart 3.13+），另外需要 Rust stable；Android 构建需要 NDK。
