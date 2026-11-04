# Async Redux 状态管理示例

[redux](https://pub.dev/packages/redux) 5.0.0、[flutter_redux](https://pub.dev/packages/flutter_redux) 0.10.0 和 [redux_thunk](https://pub.dev/packages/redux_thunk) 0.4.0 把 SDK 限制在 `>=2.12.0 <3.0.0`。Dart 3 的解析器会直接拒绝它们，所以这个示例不能用那一组包。

这里用仍在维护的 [async_redux](https://pub.dev/packages/async_redux) 29.2.3。它保留了单一不可变状态树、动作和 reducer，并让 `reduce` 可以直接返回 `Future`。六个页面和仓库里另外五个状态管理示例是同一组任务。

建议顺着这几个文件读：

1. `lib/main.dart`：`Store`、`StoreProvider`、`UserExceptionDialog`、每秒派发的 `TickClock`
2. `lib/src/state.dart`：`AppState`、动作、`ActionObserver`
3. `lib/src/pages.dart`：`context.select`、`isWaiting`、`Evt`

## 优势

- 状态怎么变，只看动作和 `reduce`
- 异步动作不必再接 thunk 中间件
- `context.select` 会深度比较选中的值。待办列表每次都会新建一个 `List`，内容没变就不会重建
- `UserException` 配合 `UserExceptionDialog` 弹出错误
- `Evt` 被读一次后就消费掉，SnackBar 不会在下次构建时再出现
- `ActionObserver` 可以记日志，而不必把日志塞进状态

## 劣势

- 原版 `redux` / `flutter_redux` 没有可用的 Dart 3 发布版
- 状态默认全局。离开临时页不会销毁草稿，再次进入时要自己派发 `ResetDraft`
- `AppState.copyWith` 会随着字段变长
- `isWaiting` 订阅的是整个 store。时钟每秒变化时，调用了它的那一块也会重建
- 搜索防抖是副作用，不能写进 reducer。这个示例把 `Timer` 留在待办页里

## 这个示例里的用法

- 同步动作改计数、主题、待办、购物车和草稿
- `LoadCatalog`、`Login` 是异步动作，并混入 `NonReentrant`
- `environment` 注入 `CatalogApi` 和 `AuthApi`
- `Logout` 在同一次 `reduce` 里清空会话和购物车
- 概览页用 `ActionObserver` 显示最近的动作，并跳过 `TickClock`

## 运行

```bash
cd example/redux_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。示例带了 `.fvm`，指向本机的 stable。
