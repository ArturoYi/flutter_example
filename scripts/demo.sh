#!/usr/bin/env bash
# 安装或清理本仓库里各个 Flutter demo 的依赖与本地缓存。
#
# 用法:
#   ./scripts/demo.sh install [demo]
#   ./scripts/demo.sh clean [demo]
#
# 不传 demo 时处理仓库根目录下所有包含 pubspec.yaml 的示例。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
用法:
  ./scripts/demo.sh install [demo]   安装 demo 依赖 (flutter pub get)
  ./scripts/demo.sh clean [demo]     清理 demo 的本地依赖产物和构建缓存

示例:
  ./scripts/demo.sh install
  ./scripts/demo.sh install objectbox_example
  ./scripts/demo.sh install drift_example
  ./scripts/demo.sh clean
  ./scripts/demo.sh clean realm_example
  ./scripts/demo.sh clean sqflite_example
EOF
}

discover_demos() {
  local dir
  for dir in "$ROOT"/*/; do
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

  local name="$1"
  if [[ -f "$ROOT/$name/pubspec.yaml" ]]; then
    printf '%s\n' "$ROOT/$name"
  elif [[ -f "$name/pubspec.yaml" ]]; then
    (cd "$name" && pwd)
  else
    echo "找不到 demo: $name" >&2
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

install_demo() {
  local demo="$1"
  echo "==> 安装依赖: $(basename "$demo")"
  run_flutter "$demo" pub get
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
