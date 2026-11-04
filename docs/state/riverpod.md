---
description: 我用 Riverpod 在 widget 树外读状态。
---

# Riverpod

我用 [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) ^3.4.3，代码在 `riverpod_example/`。Flutter 3.47 以上（Dart ^3.13.5）。我手写 Provider，没有用代码生成。

入口包一层 `ProviderScope`。计数、主题、待办、登录用 `Notifier`。商品目录用 `AsyncNotifier`，自带 loading 和 error。时钟是 `StreamProvider`。按 id 取值用 `family`。没有人听的时候，`autoDispose` 会释放。

`ref.watch` 建立依赖，`select` 只在选中的值变化时重建。登出清购物车、数到 5 弹提示，我放在 `ref.listen`。异步回来前用 `ref.mounted` 看 Provider 还在不在。

失败默认会重试。目录把 `retry` 设成返回 `null`，错误才会停在界面上。`StateProvider` 这些旧 API 我不用。

```bash
./scripts/demo.sh install riverpod_example
./scripts/demo.sh run riverpod_example
```

测试用 `ProviderContainer` 换掉 API，不用把整棵 widget 树拉起来。主要看 `lib/src/state.dart` 和 `lib/src/pages.dart`。
