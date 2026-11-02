# Signals 状态管理示例

使用 [signals](https://pub.dev/packages/signals) 7.1.0。Flutter 组件来自 `package:signals/signals_flutter.dart`。六个页面和仓库里另外五个状态管理示例是同一组任务。

建议顺着这几个文件读：

1. `lib/src/state.dart`：`signal`、`computed`、`effect`、`futureSignal`、`streamSignal`、`batch`
2. `lib/src/pages.dart`：`SignalBuilder`、`SignalEffect`、`SignalStatefulWidget`
3. `lib/main.dart`：只有主题那一层包了 `SignalBuilder`

## 优势

- 读到哪个 `.value`，就订阅哪个。没读到的变化不会重建这块界面
- `computed` 懒计算，依赖没变就不重算
- `effect` 可以返回清理函数。搜索防抖的 `Timer` 会在下一次输入时取消
- `batch` 把多次写入合成一次通知
- `futureSignal` / `streamSignal` 把异步收成 `AsyncState`
- 页面自己的 signal 可以放在 `State` 里，跟路由一起 `dispose`

## 劣势

- 依赖在运行时追踪。读在 `if` 里面时，分支一变，订阅也会变
- 库不提供依赖注入。应用状态放在全局 `signals` 上，测试要另外 `new LabSignals()`
- `effect` 里同步修改自己正在读的 signal，可能形成循环
- 全局 signal 多了以后，和 GetX 的全局控制器一样，要自己约定归属
- 大型团队的配套规范和工具比 Bloc、Riverpod 少

## 这个示例里的用法

- 刷新页对比 `peek`、只读 `count`、同时读 `count` 和 `taps`
- “分两次加”会通知两次，“batch 一起加”只通知一次
- 待办的 `remaining` 不读筛选，切换筛选时那一块不重建
- `effect` 把输入延迟 300ms 写到 `query`
- `futureSignal` 加载目录；`untracked` 读取失败开关，避免一切换就重新请求
- `streamSignal` 做顶栏时钟
- 登出时 `batch` 同时清会话和购物车
- 临时页是 `SignalStatefulWidget`，`SignalEffect` 在数到 5 时弹 SnackBar

## 运行

```bash
cd signals_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。示例带了 `.fvm`，指向本机的 stable。
