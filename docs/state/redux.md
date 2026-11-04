---
description: 我用 Async Redux 把状态放在一棵树上。
---

# Async Redux

我用 [async_redux](https://pub.dev/packages/async_redux) ^29.2.3，代码在 `example/redux_example/`。Flutter 3.47 以上（Dart ^3.13.5）。

原版 `redux` 和 `flutter_redux` 还停在 Dart 2，当前 Flutter 装不上，所以我用 Async Redux。状态是一棵不可变的树。改状态看动作的 `reduce`，异步也可以直接返回 `Future`。

同步动作用来改计数、主题、待办和购物车。`LoadCatalog`、`Login` 是异步的，并混入 `NonReentrant`。`Logout` 在同一次 `reduce` 里清掉会话和购物车。API 从 `environment` 拿。

`context.select` 会比较选中的值，内容没变就不重建。错误用 `UserException` 弹窗。`Evt` 读过一次就没了，提示不会在下次构建再出现。

临时页关掉后草稿还在，再进去要自己派发 `ResetDraft`。搜索防抖不能写进 reducer，`Timer` 留在页面里。

```bash
./scripts/demo.sh install redux_example
./scripts/demo.sh run redux_example
```

主要看 `lib/main.dart`、`lib/src/state.dart`、`lib/src/pages.dart`。
