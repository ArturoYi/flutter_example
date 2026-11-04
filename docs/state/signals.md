---
description: 我用 Signals 按读到的值刷新界面。
---

# Signals

我用 [signals](https://pub.dev/packages/signals) ^7.1.0，Flutter 组件来自 `package:signals/signals_flutter.dart`。代码在 `signals_example/`。Flutter 3.47 以上（Dart ^3.13.5）。

读到哪个 `.value`，就订阅哪个。`computed` 在依赖没变时不算。`effect` 可以返回清理函数，搜索防抖的 `Timer` 会在下一次输入时取消。`batch` 把几次写入合成一次通知。

目录用 `futureSignal`，时钟用 `streamSignal`。读失败开关时用 `untracked`，避免一切换就重新请求。登出时 `batch` 一起清会话和购物车。

页面自己的 signal 可以放在 `State` 里，跟路由一起释放。临时页是 `SignalStatefulWidget`，`SignalEffect` 在数到 5 时提示。

依赖是跑起来才知道的。读在 `if` 里面时，分支一变，订阅也变。应用状态放在全局的 `signals` 上，测试时我另外 `new LabSignals()`。

```bash
./scripts/demo.sh install signals_example
./scripts/demo.sh run signals_example
```

主要看 `lib/src/state.dart` 和 `lib/src/pages.dart`。
