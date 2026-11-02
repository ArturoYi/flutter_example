# Bloc / Cubit 状态管理示例

使用 [bloc](https://pub.dev/packages/bloc) 9.2.1、[flutter_bloc](https://pub.dev/packages/flutter_bloc) 9.1.1 和 [bloc_concurrency](https://pub.dev/packages/bloc_concurrency) 0.3.0。六个页面和仓库里另外五个状态管理示例是同一组任务。

建议顺着这几个文件读：

1. `lib/main.dart`：`RepositoryProvider`、`MultiBlocProvider`、`Bloc.observer`
2. `lib/src/state.dart`：Cubit、带事件的 `TodoBloc`、`restartable`
3. `lib/src/pages.dart`：`BlocBuilder`、`BlocSelector`、`BlocListener`、`BlocConsumer`

## 优势

- Cubit 直接 `emit`，Bloc 先收事件再改状态，方向固定
- `BlocObserver` 能看到每一次变化
- `BlocBuilder` / `BlocSelector` 管重建，`BlocListener` 管 SnackBar、清购物车这类副作用
- `restartable` 会取消还没完成的搜索事件，只留下最后一次输入
- `RepositoryProvider` 注入 API，`BlocProvider` 创建并在离开子树时 `close`

## 劣势

- 事件类比直接改状态啰嗦
- 状态必须正确实现 `==`，否则该跳过的刷新不会跳过
- loading 和 error 要自己放进状态类
- 一个功能常常要拆成 event、state、bloc

## 这个示例里的用法

- Cubit：计数、主题、时钟、目录、登录、购物车、临时页
- Bloc：待办的添加、勾选、删除、筛选和搜索
- 搜索事件使用 `restartable`，内部先等 300ms
- 登出只改会话，`BlocListener` 再清空购物车
- 临时页用 `BlocConsumer`，`listenWhen` 只在进入 5 时弹 SnackBar
- `LabBlocObserver` 把除时钟以外的变化打到调试控制台

## 运行

```bash
cd bloc_example
flutter pub get
flutter run
```

Flutter 3.47+（Dart 3.13+）。示例带了 `.fvm`，指向本机的 stable。
