# GetX 状态管理示例

使用 [get](https://pub.dev/packages/get) 4.7.3。5.0 仍是预发布版本，这里用当前稳定版。六个页面和仓库里另外五个状态管理示例是同一组任务。

建议顺着这几个文件读：

1. `lib/main.dart`：`GetMaterialApp`
2. `lib/src/state.dart`：`Get.put`、`Get.lazyPut`、`GetxService`、Worker
3. `lib/src/pages.dart`：`Obx`、`GetBuilder`、`GetView`、路由 `Bindings`

## 优势

- 拿控制器、开页面、弹 SnackBar 都可以不传 `BuildContext`
- `.obs` + `Obx` 按读到的响应式变量刷新；`GetBuilder.update` 可以按 id 手动刷新
- `Get.put`、`Get.lazyPut`、`permanent` 和路由 Bindings 覆盖不同生命周期
- `ever`、`once`、`debounce` 用来监听、只跑一次和防抖
- 路由 binding 注册的控制器在页面弹出时 `onClose`

## 劣势

- 服务定位器是全局的，依赖不写在类型和 widget 树上
- 漏读 `.obs` 时不会有编译错误，只会不刷新，或者 Obx 在运行时抛错
- 路由和弹窗跟 Flutter 官方 Navigator 的习惯不同
- 业务容易堆进一个很大的 `GetxController`
- 静态分析能提供的帮助比 Riverpod、Bloc 少

## 这个示例里的用法

- 响应式计数，以及 `GetBuilder` 只刷新 id 为 `count` 的那一块
- 待办控制器 `lazyPut`，时钟是 `permanent` 的 `GetxService`
- `debounce` 做搜索，`ever` 在登出时清购物车，`once` 在第一次加购时提示
- `Get.snackbar` 和 `Get.to`
- 临时页控制器在路由弹出后 `onClose`

底部导航用 `IndexedStack` 一次建好所有页面，所以 `lazyPut` 的待办控制器会在启动后马上被创建。

## 运行

```bash
cd example/getx_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。示例带了 `.fvm`，指向本机的 stable。
