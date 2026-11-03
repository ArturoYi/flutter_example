# Flutter + Rust 示例

用 [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) 2.13.0 把 Rust 函数接到 Flutter。界面上有六节，每一节对应一种会反复用到的写法。

建议顺着这几个文件读：

1. `lib/main.dart`：`RustLib.init()`
2. `rust/src/api/simple.rs`：同步函数，以及丢到工作线程的函数
3. `rust/src/api/notes.rs`：结构体、枚举，把一整份数据交过去
4. `rust/src/api/amount.rs`：`Result` 在 Dart 里变成返回值或异常
5. `rust/src/api/total.rs`：状态留在 Rust 里的对象
6. `rust/src/api/progress.rs`：`Stream`
7. `lib/src/lesson_page.dart`：上面这些函数在界面里怎么调用

`lib/src/rust/` 和 `rust/src/frb_generated.rs` 是生成的胶水，不要手改。

## 这层桥在做什么

你在 `rust/src/api` 里写普通的 `pub fn`、结构体和方法。`flutter_rust_bridge_codegen generate` 读这些签名，生成 Dart 函数和 Rust 侧的编解码。Cargokit 在 `flutter run` 时编译 Rust，并把动态库打进应用。

`flutter_rust_bridge.yaml` 指定了入口：`crate::api` 下面的模块都会被扫描。新增一个 Rust 文件时，要在 `rust/src/api/mod.rs` 里 `pub mod` 它，否则生成器看不到。

## 这个示例里的用法

- `#[frb(sync)]`：`greet`、`count_primes_blocking`、`Ledger` 的方法。Dart 侧没有 `await`
- 普通 `pub fn`：`count_primes`、`report`、`parse_cents`。Dart 侧是 `Future`，Rust 跑在工作线程
- `#[frb(init)]`：`init_app`，随 `RustLib.init()` 执行
- `#[frb(opaque)]`：`Ledger`。Dart 拿到句柄，用完调用 `dispose()`
- `Result<T, E>`：`parse_cents` 失败时 Dart 抛出 `AmountError`
- `StreamSink<T>`：`count_down` 在 Dart 里是 `Stream<int>`
- `type_64bit_int: true`：示例里的 `i64` 生成 Dart `int`。默认配置在 Web 上会是 `BigInt`

带字段的 Rust 枚举默认会生成 freezed 类。金额错误这里做成了结构体加一个简单枚举，生成的 Dart 可以直接读。

## 运行

需要 Flutter 3.47+（Dart 3.13+）和 [rustup](https://rustup.rs) 的 stable。示例带了 `.fvm`，指向本机的 stable。Android 还需要 NDK。

```bash
cd flutter_rust_bridge_example
flutter pub get
flutter run
```

改了 `rust/src/api` 之后重新生成胶水。生成器版本要和 `Cargo.toml`、`pubspec.yaml` 里的 `2.13.0` 一致：

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
flutter_rust_bridge_codegen generate
```

`integration_test/simple_test.dart` 会真正加载 Rust 库，需要在设备或桌面目标上跑，例如：

```bash
flutter test integration_test/simple_test.dart -d macos
```

Rust 自己的单测不经过 Flutter：

```bash
cd rust
cargo test
```

## 接着可以看的能力

这个示例没有展开这些部分，文档在 <https://cjycode.com/flutter_rust_bridge/>：

- Rust 调用 Dart 回调
- trait 和带生命周期的类型
- 把已有的 Rust crate 扫进来
- Web 需要 `flutter_rust_bridge_codegen build-web`，并给 `flutter run` 加上跨域隔离头
