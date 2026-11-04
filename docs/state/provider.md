---
description: 我用 provider 把状态放在 widget 树上。
---

# Provider

我用 [provider](https://pub.dev/packages/provider) ^6.1.5+1，代码在 `provider_example/`。Flutter 3.47 以上（Dart ^3.13.5）。

状态跟着 widget 子树走，离开就 `dispose`。`context.select` 可以只听一个字段。API 放 `Provider`，可变状态放 `ChangeNotifierProvider`，异步值放 `FutureProvider` 或 `StreamProvider`。

购物车用 `ChangeNotifierProxyProvider` 跟着登录变。搜索在 `TodoController` 里防抖 300 毫秒。顶栏时钟是 `StreamProvider`。临时页的计数放在路由上的 Provider 里，页面关掉就释放。

loading 和错误要自己写。`context.watch` 放在太大的 `build` 里，整页会一起重建。同一个类型会读到更近的那个。

```bash
./scripts/demo.sh install provider_example
./scripts/demo.sh run provider_example
```

主要看 `lib/main.dart`、`lib/src/state.dart`、`lib/src/pages.dart`。
