---
description: 仓库根目录的 .vscode/launch.json 为每个示例指定工作目录与入口文件。
---

# launch.json

仓库由多个独立的 Flutter 工程组成。把根目录当作唯一工作区时，调试器找不到对应示例的 `pubspec.yaml`。根目录的 `.vscode/launch.json` 为每个示例写一条配置：`cwd` 指向该目录，`program` 固定为 `lib/main.dart`。

在 Cursor 或 VS Code 中打开本仓库后，从运行面板选择与目录同名的配置即可启动。需要代码生成的示例，先按 [脚本](/guide/scripts) 执行 `generate`，再启动调试。

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "objectbox_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/objectbox_example",
      "program": "lib/main.dart"
    },
    {
      "name": "realm_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/realm_example",
      "program": "lib/main.dart"
    },
    {
      "name": "drift_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/drift_example",
      "program": "lib/main.dart"
    },
    {
      "name": "sqflite_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/sqflite_example",
      "program": "lib/main.dart"
    },
    {
      "name": "provider_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/provider_example",
      "program": "lib/main.dart"
    },
    {
      "name": "getx_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/getx_example",
      "program": "lib/main.dart"
    },
    {
      "name": "bloc_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/bloc_example",
      "program": "lib/main.dart"
    },
    {
      "name": "riverpod_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/riverpod_example",
      "program": "lib/main.dart"
    },
    {
      "name": "redux_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/redux_example",
      "program": "lib/main.dart"
    },
    {
      "name": "signals_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/signals_example",
      "program": "lib/main.dart"
    },
    {
      "name": "flutter_rust_bridge_example",
      "type": "dart",
      "request": "launch",
      "cwd": "${workspaceFolder}/flutter_rust_bridge_example",
      "program": "lib/main.dart"
    }
  ]
}
```

新增示例时，在 `configurations` 中按同样的字段追加一项。`name` 与目录名保持一致，`type` 为 `dart`，`request` 为 `launch`。
