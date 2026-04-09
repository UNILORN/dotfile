#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/macos/setup-fish.sh [--skip-default-shell]

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

ensure_homebrew() {
  command -v brew >/dev/null 2>&1 || die "Homebrew が見つかりません。https://brew.sh/ を参照して先にインストールしてください。"
}

brew_install_formula() {
  local formula=$1

  if brew list --formula "$formula" >/dev/null 2>&1; then
    log "既にインストール済みです: $formula"
    return
  fi

  brew install "$formula"
}

ensure_shell_registered() {
  local fish_path=$1

  if grep -qx "$fish_path" /etc/shells 2>/dev/null; then
    return
  fi

  log "/etc/shells に fish を追加します。"
  printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
}

change_default_shell() {
  local fish_path=$1

  ensure_shell_registered "$fish_path"

  if [[ "${SHELL:-}" == "$fish_path" ]]; then
    log "ログインシェルは既に fish です。"
    return
  fi

  log "ログインシェルを fish に変更します。"
  chsh -s "$fish_path"
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

[[ "$(uname -s)" == "Darwin" ]] || die "このスクリプトは macOS 向けです。"

ensure_homebrew
brew_install_formula fish
brew_install_formula git
brew_install_formula curl
brew_install_formula peco

command -v fish >/dev/null 2>&1 || die "fish のインストールに失敗しました。"

"$REPO_ROOT/scripts/macos/apply-fish-config.sh"

if [[ "$SKIP_DEFAULT_SHELL" -eq 0 ]]; then
  FISH_PATH="$(command -v fish)"
  change_default_shell "$FISH_PATH"
fi

cat <<EOF

fish の初期構築が完了しました。

反映内容:
- fish 本体のインストール
- $HOME/.config/fish への設定同期
- $HOME/.config/fisher への Fisher パッケージ同期
- 既存 fish_variables の削除
- 独自 prompt と色設定の検証
- 必要に応じたログインシェル変更

次の手順:
1. 新しいシェルを開く
2. 反映確認:
   fish --version
   fish -c 'functions --details fish_prompt'
   fish -c 'echo \$fish_color_command'
EOF
