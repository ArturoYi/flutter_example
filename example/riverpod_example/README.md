# Riverpod 状态管理示例

使用 [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) 3.4.3。六个页面和仓库里另外五个状态管理示例是同一组任务。

建议顺着这几个文件读：

1. `lib/main.dart`：`ProviderScope`
2. `lib/src/state.dart`：`Provider`、`NotifierProvider`、`AsyncNotifierProvider`、`StreamProvider`、`family`、`autoDispose`
3. `lib/src/pages.dart`：`ref.watch`、`ref.read`、`select`、`ref.listen`
4. `test/state_test.dart`：`ProviderContainer` 和 `overrideWithValue`

## 优势

- Provider 不依赖 `BuildContext`，组件、测试和其他 Provider 都能读
- `ref.watch` 自动建立依赖，`select` 只在选中的值变化时重建
- `AsyncValue` 自带 loading、error、data，可以用 `invalidate` 或重新赋值重试
- `autoDispose` 在没有监听者时释放，`family` 按参数分出不同的值
- 测试可以换掉 API，而不必启动整个 widget 树

## 劣势

- 概念比 Provider 多
- 手写 `NotifierProvider` 的类型参数比较长；改用 `@riverpod` 代码生成就要跑 `build_runner`。这个示例用手写 API，方便直接阅读
- 3.0 把 `StateProvider`、`StateNotifierProvider`、`ChangeNotifierProvider` 挪到了 `legacy.dart`，这里不使用它们
- 失败的 Provider 默认会退避重试。目录把 `retry` 设成返回 `null`，错误才会停在界面上
- 离线缓存和 Mutation 仍是实验 API，这个示例没有接

## 这个示例里的用法

- `Notifier`：计数、主题、待办、登录、购物车、失败开关
- `AsyncNotifier`：商品目录
- `StreamProvider`：顶栏时钟
- `Provider.family`：按 id 读“龙井”
- `ref.listen`：登出时清空购物车，临时页数到 5 时弹 SnackBar
- `NotifierProvider.autoDispose` 和 `ref.onDispose`
- 登录请求回来前用 `ref.mounted` 判断 Provider 是否还在

## 运行

```bash
cd example/riverpod_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。Riverpod 3.4 要求 Dart 3.12+。示例带了 `.fvm`，指向本机的 stable。
