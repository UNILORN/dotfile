#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/linux/setup-fish.sh [--skip-default-shell]

Options:
  --skip-default-shell  Do not change the user's login shell to fish
  -h, --help            Show this help
EOF
}

log() {
  printf '[fish-setup] %s\n' "$*"
}

die() {
  printf '[fish-setup] %s\n' "$*" >&2
  exit 1
}

is_wsl() {
  grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y fish git curl peco
    return
  fi

  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y fish git curl peco
    return
  fi

  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y fish git curl peco
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm fish git curl peco
    return
  fi

  if command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install fish git curl peco
    return
  fi

  die "対応しているパッケージマネージャーが見つかりません。fish を手動でインストールしてください。"
}

SKIP_DEFAULT_SHELL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-default-shell)
      SKIP_DEFAULT_SHELL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ "$(uname -s)" == "Linux" ]] || die "このスクリプトは Linux / WSL 向けです。"

install_packages

command -v fish >/dev/null 2>&1 || die "fish のインストールに失敗しました。"

"$REPO_ROOT/scripts/linux/apply-fish-config.sh"

if [[ "$SKIP_DEFAULT_SHELL" -eq 0 ]]; then
  if is_wsl; then
    log "WSL を検出したため、ログインシェルの変更はスキップします。必要なら手動で fish を起動してください。"
  else
    FISH_PATH="$(command -v fish)"
    if ! grep -qx "$FISH_PATH" /etc/shells 2>/dev/null; then
      log "/etc/shells に fish を追加します。"
      printf '%s\n' "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    if [[ "${SHELL:-}" != "$FISH_PATH" ]]; then
      log "ログインシェルを fish に変更します。"
      chsh -s "$FISH_PATH"
    fi
  fi
fi

cat <<EOF

fish の初期構築が完了しました。

反映内容:
- fish 本体のインストール
- $HOME/.config/fish への設定同期
- $HOME/.config/fisher への Fisher パッケージ同期
- 既存 fish_variables の削除
- 独自 prompt と色設定の検証

次の手順:
1. 新しいシェルを開く
2. 反映確認:
   fish --version
   fish -c 'functions --details fish_prompt'
   fish -c 'echo $fish_color_command'
3. WSL の場合:
   fish
EOF
