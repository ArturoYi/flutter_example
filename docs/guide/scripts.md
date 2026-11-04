---
description: scripts/demo.sh 在仓库根目录统一处理依赖安装、代码生成、运行与清理。
---

# 脚本

`scripts/demo.sh` 在仓库根目录处理各个示例的依赖、代码生成、运行和清理。Flutter 与 Dart 按固定顺序查找：示例目录下的 `.fvm/flutter_sdk`、当前 `PATH`、`~/fvm/versions/stable`、`fvm` 命令。部分示例提交了 `.fvm`，指向本机的 stable；没有提交的示例落到后面几项。Drift、Realm、sqflite 属于后者。

```bash
./scripts/demo.sh install [目录]
./scripts/demo.sh generate [目录]
./scripts/demo.sh run <目录> [flutter run 的参数...]
./scripts/demo.sh clean [目录]
```

不写目录时，`install`、`generate`、`clean` 遍历根目录下所有带 `pubspec.yaml` 的示例。`run` 必须指定目录，其后参数原样传给 `flutter run`，例如 `-d macos`。不带参数执行脚本时，输出用法和当前示例列表。

`install` 在目标目录执行 `flutter pub get`。

`generate` 按目录名选择生成器，其余目录跳过：

| 目录 | 命令 |
| --- | --- |
| `objectbox_example`、`drift_example` | `dart run build_runner build --delete-conflicting-outputs` |
| `realm_example` | `dart run realm generate` |
| `flutter_rust_bridge_example` | `flutter_rust_bridge_codegen generate` |

`flutter_rust_bridge_codegen` 的版本与依赖中的 2.13.0 保持一致。脚本依次查找 `PATH` 和 `~/.cargo/bin`。尚未安装时执行：

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
```

新示例如果需要生成代码，在 `generate_demo` 中增加对应分支。

`clean` 先执行 `flutter clean`，再删除示例目录内的 `.dart_tool`、`build`、CocoaPods、Gradle 等本地产物。`flutter_rust_bridge_example` 还会删除 `rust/target`，以及 `rust_builder` 与 Cargokit 的构建缓存。全局 `~/.pub-cache`、`.fvm` 中的 Flutter SDK，以及已经提交的生成文件不在清理范围内。
