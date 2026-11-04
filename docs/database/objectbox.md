---
description: 我用 ObjectBox 把任务存在本地。
---

# ObjectBox

我用 [ObjectBox](https://objectbox.io/) ^5.3.2 做本地对象存储，代码在 `objectbox_example/`。还要 `objectbox_flutter_libs`，模型用 `objectbox_generator` 生成。

Flutter 3.29 以上（Dart ^3.7.0）。iOS 用 15，macOS 我按当前模板用 12。

任务写成带 `@Entity()` 的类。字段 UID 记在 `objectbox-model.json`。改名时我留着原来的 UID，不然它会当成删掉旧字段、再加一个新的。类型变了，旧数据不会自动转。

```dart
@Entity()
class Task {
  @Id()
  int id;

  @Property(uid: 1)
  String title;

  @Property(uid: 3)
  bool isCompleted;
}
```

列表用 `Query.watch` 跟着变。增删改用 `putAsync` 和 `removeAsync`。用之前先把库打开。

库在文档目录的 `obx-example`。沙盒 macOS 用 App Group `objectbox.example`。

```bash
./scripts/demo.sh install objectbox_example
./scripts/demo.sh generate objectbox_example
./scripts/demo.sh run objectbox_example
```

改了模型就重新生成，并留着 `objectbox.g.dart` 和 `objectbox-model.json`。

更多说明见 [ObjectBox 文档](https://docs.objectbox.io/)。
