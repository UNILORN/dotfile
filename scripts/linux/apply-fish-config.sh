#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() {
  printf '[fish-config] %s\n' "$*"
}

die() {
  printf '[fish-config] %s\n' "$*" >&2
  exit 1
}

replace_path() {
  local src=$1
  local dest=$2

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

copy_tree_contents() {
  local src=$1
  local dest=$2

  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
}

verify_fish_config() {
  local prompt_path="$HOME/.config/fish/functions/fish_prompt.fish"

  fish -c "
    test (functions --details fish_prompt) = '$prompt_path'
    and test \"\$fish_color_command\" = '005fd7'
    and test -z \"\$fish_greeting\"
  " >/dev/null
}

command -v fish >/dev/null 2>&1 || die "fish が見つかりません。先に fish をインストールしてください。"

log "fish 設定を同期します。"

replace_path "$REPO_ROOT/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
replace_path "$REPO_ROOT/.config/fish/fishfile" "$HOME/.config/fish/fishfile"
copy_tree_contents "$REPO_ROOT/.config/fish/functions" "$HOME/.config/fish/functions"
copy_tree_contents "$REPO_ROOT/.config/fish/completions" "$HOME/.config/fish/completions"
copy_tree_contents "$REPO_ROOT/.config/fish/conf.d" "$HOME/.config/fish/conf.d"
copy_tree_contents "$REPO_ROOT/.config/fisher" "$HOME/.config/fisher"

rm -f "$HOME/.config/fish/fish_variables"

if verify_fish_config; then
  log "独自 prompt と色設定の反映を確認しました。"
else
  die "fish 設定の検証に失敗しました。新しい shell で 'fish -c \"functions --details fish_prompt\"' を確認してください。"
fi
