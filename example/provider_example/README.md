# Provider 状态管理示例

使用 [provider](https://pub.dev/packages/provider) 6.1.5+1。六个页面和仓库里另外五个状态管理示例是同一组任务，方便对照。

建议顺着这几个文件读：

1. `lib/main.dart`：`MultiProvider`、`FutureProvider`、`StreamProvider`、`ChangeNotifierProxyProvider`
2. `lib/src/state.dart`：`ChangeNotifier` 和页面级 `DraftCounter`
3. `lib/src/pages.dart`：`context.read`、`context.watch`、`context.select`、`Selector`、`Consumer`

## 优势

- API 薄，状态跟 widget 子树走，离开子树就 `dispose`
- `context.select` 和 `Selector` 可以只订阅一个字段
- `Provider` 放 API，`ChangeNotifierProvider` 放可变状态，`FutureProvider` / `StreamProvider` 放异步值
- `ChangeNotifierProxyProvider` 能让购物车跟着登录状态更新
- 路由里新建的 Provider 会随页面弹出释放

## 劣势

- 没有统一的事件和异步状态机，loading / error / 重试要自己写
- 没有专门的副作用组件，SnackBar 要自己 `addListener`
- `context.watch` 写在太大的 `build` 上，会把整页绑在一起重建
- 依赖按类型查找，同一子树里两个相同类型会读到更近的那个
- 项目变大后，约束比 Bloc 和 Riverpod 弱

## 这个示例里的用法

- 注入 `CatalogApi`、`AuthApi`
- 计数、主题、待办、目录、登录、购物车
- 搜索在 `TodoController` 里防抖 300ms
- 顶栏时钟是 `StreamProvider`，概览里的一句话是 `FutureProvider`
- 临时页的 `DraftCounter` 由路由上的 Provider 创建，弹出后 `dispose`

## 运行

```bash
cd example/provider_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。示例带了 `.fvm`，指向本机的 stable。
