---
description: 我用 flutter_rust_bridge 在 Flutter 里调用 Rust。
---

# flutter_rust_bridge

我用 [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) 2.13.0 在 Flutter 里调用 Rust，代码在 `example/flutter_rust_bridge_example/`。

Flutter 3.47 以上（Dart ^3.13.5），还要 Rust stable。Android 还要 NDK。

我在 `rust/src/api` 里写普通函数。生成器读签名，生成两边的胶水。新文件要在 `rust/src/api/mod.rs` 里 `pub mod`，不然扫不到。`lib/src/rust/` 和 `frb_generated.rs` 不要手改。

| 我这样写 | Dart 里是 |
| --- | --- |
| `#[frb(sync)]` | 直接调用，不用 `await` |
| 普通 `pub fn` | `Future`，Rust 在工作线程 |
| `#[frb(init)]` | 跟着 `RustLib.init()` 跑 |
| `#[frb(opaque)]` | 拿到句柄，用完 `dispose()` |
| `Result` | 失败时抛异常 |
| `StreamSink` | `Stream` |

`i64` 我配了 `type_64bit_int: true`，生成 Dart 的 `int`。带字段的枚举默认会变成 freezed，金额错误我改成了结构体加简单枚举，Dart 这边好读一些。

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
./scripts/demo.sh install flutter_rust_bridge_example
./scripts/demo.sh generate flutter_rust_bridge_example
./scripts/demo.sh run flutter_rust_bridge_example
```

生成器版本要和依赖里的 2.13.0 一样。改了 `rust/src/api` 就重新生成。

集成测试会真的加载 Rust 库，要指定设备，例如 `flutter test integration_test/simple_test.dart -d macos`。Rust 自己的测试在 `rust/` 里 `cargo test`。

回调、trait、Web 这些我还没写，官方说明在 <https://cjycode.com/flutter_rust_bridge/>。
