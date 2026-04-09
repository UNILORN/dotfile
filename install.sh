#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [fish] [options]
  ./install.sh tools

Commands:
  fish   fish の初期構築を実行します。省略時のデフォルトです。
  tools  ツールインストーラを起動します。
EOF
}

os_name="$(uname -s)"
command_name="${1:-fish}"

if [[ "$command_name" != "fish" && "$command_name" != "tools" && "$command_name" != "-h" && "$command_name" != "--help" ]]; then
  if [[ "$command_name" == -* ]]; then
    command_name="fish"
  else
    usage >&2
    exit 1
  fi
fi

case "$command_name" in
  -h|--help)
    usage
    exit 0
    ;;
  fish)
    if [[ "${1:-}" == "fish" ]]; then
      shift
    fi

    case "$os_name" in
      Linux)
        exec "$REPO_ROOT/scripts/linux/setup-fish.sh" "$@"
        ;;
      Darwin)
        exec "$REPO_ROOT/scripts/macos/setup-fish.sh" "$@"
        ;;
      *)
        echo "未対応の OS です: $os_name" >&2
        exit 1
        ;;
    esac
    ;;
  tools)
    shift

    case "$os_name" in
      Linux)
        exec "$REPO_ROOT/scripts/linux/install-tools.sh" "$@"
        ;;
      Darwin)
        exec "$REPO_ROOT/scripts/macos/install-tools.sh" "$@"
        ;;
      *)
        echo "未対応の OS です: $os_name" >&2
        exit 1
        ;;
    esac
    ;;
esac
