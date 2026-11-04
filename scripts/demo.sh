#!/usr/bin/env bash
# 安装、生成或清理本仓库里各个 Flutter demo 的依赖与本地缓存。
#
# 用法:
#   ./scripts/demo.sh install [demo]
#   ./scripts/demo.sh generate [demo]
#   ./scripts/demo.sh run <demo> [flutter run 的参数...]
#   ./scripts/demo.sh clean [demo]
#
# 不传 demo 时，install、generate、clean 处理 example/ 下所有包含 pubspec.yaml 的示例。
# run 必须指定一个示例。示例名是目录名，例如 objectbox_example。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLES="$ROOT/example"

usage() {
  cat <<'EOF'
用法:
  ./scripts/demo.sh install [demo]     安装依赖 (flutter pub get)
  ./scripts/demo.sh generate [demo]    生成代码；没有生成步骤的示例会跳过
  ./scripts/demo.sh run <demo> [参数]  用该示例对应的 Flutter 执行 flutter run
  ./scripts/demo.sh clean [demo]       清理本地依赖产物和构建缓存

不传 demo 时，install、generate、clean 处理全部示例。run 必须指定一个示例，
后面的参数会原样传给 flutter run，例如 -d macos。

示例:
  ./scripts/demo.sh install
  ./scripts/demo.sh generate objectbox_example
  ./scripts/demo.sh generate flutter_rust_bridge_example
  ./scripts/demo.sh run signals_example -d macos
  ./scripts/demo.sh clean flutter_rust_bridge_example

Flutter 查找顺序: 示例的 .fvm/flutter_sdk、PATH、~/fvm/versions/stable、fvm。
EOF
  echo
  echo "当前示例:"
  local demo
  while IFS= read -r demo; do
    [[ -z "$demo" ]] && continue
    printf '  %s\n' "$(basename "$demo")"
  done < <(discover_demos)
}

discover_demos() {
  local dir
  for dir in "$EXAMPLES"/*/; do
    if [[ -f "${dir}pubspec.yaml" ]]; then
      printf '%s\n' "${dir%/}"
    fi
  done
}

resolve_targets() {
  if [[ $# -eq 0 ]]; then
    discover_demos
    return
  fi

  local name="${1%/}"
  name="${name#example/}"
  if [[ -f "$EXAMPLES/$name/pubspec.yaml" ]]; then
    printf '%s\n' "$EXAMPLES/$name"
  elif [[ -f "$name/pubspec.yaml" ]]; then
    (cd "$name" && pwd)
  else
    echo "找不到 demo: $1" >&2
    exit 1
  fi
}

run_flutter() {
  local demo="$1"
  shift

  if [[ -x "$demo/.fvm/flutter_sdk/bin/flutter" ]]; then
    (cd "$demo" && "$demo/.fvm/flutter_sdk/bin/flutter" "$@")
  elif command -v flutter >/dev/null 2>&1; then
    (cd "$demo" && flutter "$@")
  elif [[ -x "${HOME}/fvm/versions/stable/bin/flutter" ]]; then
    (cd "$demo" && "${HOME}/fvm/versions/stable/bin/flutter" "$@")
  elif command -v fvm >/dev/null 2>&1; then
    (cd "$demo" && fvm flutter "$@")
  else
    echo "未找到 Flutter。请把 flutter 加入 PATH，或用 fvm 安装 stable。" >&2
    return 1
  fi
}

run_dart() {
  local demo="$1"
  shift

  if [[ -x "$demo/.fvm/flutter_sdk/bin/dart" ]]; then
    (cd "$demo" && "$demo/.fvm/flutter_sdk/bin/dart" "$@")
  elif command -v dart >/dev/null 2>&1; then
    (cd "$demo" && dart "$@")
  elif [[ -x "${HOME}/fvm/versions/stable/bin/dart" ]]; then
    (cd "$demo" && "${HOME}/fvm/versions/stable/bin/dart" "$@")
  elif command -v fvm >/dev/null 2>&1; then
    (cd "$demo" && fvm dart "$@")
  else
    echo "未找到 Dart。请把 dart 加入 PATH，或用 fvm 安装 stable。" >&2
    return 1
  fi
}

install_demo() {
  local demo="$1"
  echo "==> 安装依赖: $(basename "$demo")"
  run_flutter "$demo" pub get
}

generate_demo() {
  local demo="$1"
  local name codegen
  name="$(basename "$demo")"

  case "$name" in
    objectbox_example|drift_example)
      echo "==> 生成代码: $name"
      run_dart "$demo" run build_runner build --delete-conflicting-outputs
      ;;
    realm_example)
      echo "==> 生成代码: $name"
      run_dart "$demo" run realm generate
      ;;
    flutter_rust_bridge_example)
      echo "==> 生成代码: $name"
      if command -v flutter_rust_bridge_codegen >/dev/null 2>&1; then
        codegen="$(command -v flutter_rust_bridge_codegen)"
      elif [[ -x "${HOME}/.cargo/bin/flutter_rust_bridge_codegen" ]]; then
        codegen="${HOME}/.cargo/bin/flutter_rust_bridge_codegen"
      else
        echo "未找到 flutter_rust_bridge_codegen。请安装与示例一致的 2.13.0:" >&2
        echo "  cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked" >&2
        return 1
      fi
      (cd "$demo" && "$codegen" generate)
      ;;
    *)
      echo "==> 无需生成代码: $name"
      ;;
  esac
}

# 只删除示例目录里的依赖产物和构建缓存。
# 不碰 .fvm 指向的 Flutter SDK，也不清理全局 ~/.pub-cache。
clean_demo() {
  local demo="$1"
  local rel
  local paths=(
    .dart_tool
    .packages
    .flutter-plugins
    .flutter-plugins-dependencies
    .pub
    .pub-cache
    build
    .gradle
    android/.gradle
    ios/Pods
    ios/.symlinks
    ios/Flutter/ephemeral
    ios/Flutter/Flutter.framework
    ios/Flutter/App.framework
    ios/Flutter/Flutter.podspec
    ios/Flutter/Generated.xcconfig
    ios/Flutter/.last_build_id
    macos/Pods
    macos/.symlinks
    macos/Flutter/ephemeral
    linux/flutter/ephemeral
    windows/flutter/ephemeral
    rust/target
    rust_builder/.dart_tool
    rust_builder/.flutter-plugins
    rust_builder/.flutter-plugins-dependencies
    rust_builder/.packages
    rust_builder/build
    rust_builder/cargokit/build_tool/.dart_tool
    rust_builder/cargokit/build_tool/.packages
  )

  echo "==> 清理依赖与缓存: $(basename "$demo")"
  if ! run_flutter "$demo" clean; then
    echo "警告: flutter clean 未完成，继续删除本地缓存。" >&2
  fi

  for rel in "${paths[@]}"; do
    rm -rf "${demo}/${rel}"
  done
}

run_for_targets() {
  local action="$1"
  shift
  local output demo

  if ! output="$(resolve_targets "$@")"; then
    exit 1
  fi
  if [[ -z "$output" ]]; then
    echo "没有找到带 pubspec.yaml 的 demo。" >&2
    exit 1
  fi

  while IFS= read -r demo; do
    [[ -z "$demo" ]] && continue
    "$action" "$demo"
  done <<< "$output"
}

main() {
  local cmd="${1:-}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "$cmd" in
    install|get)
      if [[ $# -gt 1 ]]; then
        usage >&2
        exit 1
      fi
      run_for_targets install_demo "$@"
      ;;
    generate|codegen)
      if [[ $# -gt 1 ]]; then
        usage >&2
        exit 1
      fi
      run_for_targets generate_demo "$@"
      ;;
    run)
      if [[ $# -lt 1 ]]; then
        echo "run 需要指定一个 demo。" >&2
        usage >&2
        exit 1
      fi
      local target demo
      target="$1"
      shift
      if ! demo="$(resolve_targets "$target")"; then
        exit 1
      fi
      echo "==> 运行: $(basename "$demo")"
      run_flutter "$demo" run "$@"
      ;;
    clean)
      if [[ $# -gt 1 ]]; then
        usage >&2
        exit 1
      fi
      run_for_targets clean_demo "$@"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "未知命令: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
