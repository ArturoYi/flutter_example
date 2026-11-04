---
description: 新增 package 时同时补上示例、生成规则、调试配置和文档。缺陷与文档错误通过 GitHub Issues 提交。
---

# 贡献与问题

## 贡献

一个 package 进入仓库时，示例、脚本、调试配置和文档一起提交。目录自带 `pubspec.yaml`，不引用其他示例。

示例目录写好后，页面上标明该 package 要求的 Flutter 与 Dart 下限。需要代码生成时，把命令加进 `scripts/demo.sh` 的 `generate_demo`。`.vscode/launch.json` 增加同名配置，`cwd` 指向新目录，`program` 为 `lib/main.dart`。`docs/` 下新增 Markdown，链接写入 `docs/.vitepress/config.ts` 的侧边栏，并归入存储、状态管理或其他。

文档页保留四项：版本、是否生成代码、示例调用过的 API、升级时需要核对的约束。改完后在仓库根目录执行 `npm run docs:build`，确认页面可以构建。本地预览执行 `npm run docs:dev`，地址为 `http://localhost:5173`，需要 Node.js 22 及以上。

代码从功能分支经 Pull Request 合并。属于示例提交内容的生成文件与手写源码一起提交。`.dart_tool`、`build`、CocoaPods 与 Gradle 缓存不进入版本库。

## 问题

缺陷、版本偏差和文档错误提交到 [GitHub Issues](https://github.com/ArturoYi/flutter_example/issues)。一条 Issue 对应一个 package 或一处文档错误，写明示例目录、运行平台、Flutter 版本与 package 版本，以及期望行为与实际行为。
