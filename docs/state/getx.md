---
description: 我用 GetX 管理状态和路由。
---

# GetX

我用 [get](https://pub.dev/packages/get) ^4.7.3，代码在 `example/getx_example/`。5.0 还是预发布，我用稳定版。Flutter 3.47 以上（Dart ^3.13.5）。

拿控制器、开页面、弹提示都可以不传 `BuildContext`。`.obs` 配合 `Obx`，读到哪个变量就刷新哪一块。`GetBuilder` 还可以按 id 刷新。

待办控制器用 `lazyPut`，时钟是 `permanent` 的 `GetxService`。搜索用 `debounce`，登出用 `ever` 清购物车，第一次加购用 `once` 提示。临时页的控制器在路由关掉时 `onClose`。

依赖在全局定位器里，不写在 widget 树上。漏读 `.obs` 不会有编译错误，界面只是不刷新。底部导航用 `IndexedStack` 一次建好页面，所以 `lazyPut` 的待办控制器启动后就会被创建。

```bash
./scripts/demo.sh install getx_example
./scripts/demo.sh run getx_example
```

主要看 `lib/main.dart`、`lib/src/state.dart`、`lib/src/pages.dart`。
