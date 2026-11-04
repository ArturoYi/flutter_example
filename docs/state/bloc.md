---
description: 我用 Cubit 和 Bloc 改状态。
---

# Bloc / Cubit

我用 [flutter_bloc](https://pub.dev/packages/flutter_bloc) ^9.1.1 和 [bloc_concurrency](https://pub.dev/packages/bloc_concurrency) ^0.3.0，代码在 `bloc_example/`。Flutter 3.47 以上（Dart ^3.13.5）。

简单状态用 Cubit，直接 `emit`。待办用 Bloc：先收事件，再改状态。重建看 `BlocBuilder` 和 `BlocSelector`，弹提示、清购物车放在 `BlocListener`。

搜索事件用 `restartable`，里面先等 300 毫秒，没完成的那次会被取消。登出只改会话，监听器再清购物车。临时页用 `BlocConsumer`，数到 5 才提示。`LabBlocObserver` 把变化打到控制台，时钟除外。

状态要正确实现 `==`，不然该跳过的刷新跳不过。loading 和错误放进状态类里。

```bash
./scripts/demo.sh install bloc_example
./scripts/demo.sh run bloc_example
```

主要看 `lib/main.dart`、`lib/src/state.dart`、`lib/src/pages.dart`。
