#!/usr/bin/env bash

set -euo pipefail

CLAUDE_CODE_NPM_PACKAGE="${CLAUDE_CODE_NPM_PACKAGE:-@anthropic-ai/claude-code}"
CODEX_CLI_NPM_PACKAGE="${CODEX_CLI_NPM_PACKAGE:-@openai/codex}"
GEMINI_CLI_NPM_PACKAGE="${GEMINI_CLI_NPM_PACKAGE:-@google/gemini-cli}"
GENERATIVE_COMMIT_MESSAGE_REPO_URL="${GENERATIVE_COMMIT_MESSAGE_REPO_URL:-https://github.com/UNILORN/generative-commit-message-for-ai-tool.git}"
GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR="${GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR:-$HOME/.local/share/unilorn/generative-commit-message-for-ai-tool}"
GENERATIVE_COMMIT_MESSAGE_BIN_NAME="${GENERATIVE_COMMIT_MESSAGE_BIN_NAME:-generative-commit-message-for-ai-tool}"
GENERATIVE_COMMIT_MESSAGE_ALIAS_NAME="${GENERATIVE_COMMIT_MESSAGE_ALIAS_NAME:-gcm}"

TOOL_IDS=(
  docker
  github_cli
  golang
  nodejs
  pnpm
  n
  ai_clis
  generative_commit_message
)

declare -A TOOL_LABELS=(
  [docker]="docker command"
  [github_cli]="github cli"
  [golang]="golang"
  [nodejs]="nodejs + npm"
  [pnpm]="pnpm"
  [n]="n"
  [ai_clis]="claude code / codex cli / gemini cli"
  [generative_commit_message]="generative-commit-message-for-ai-tool"
)

declare -A TOOL_DESCRIPTIONS=(
  [docker]="Homebrew Cask で Docker Desktop をインストールします。"
  [github_cli]="Homebrew で GitHub CLI (gh) をインストールします。"
  [golang]="Homebrew で Go toolchain をインストールします。"
  [nodejs]="Homebrew で Node.js と npm をインストールします。"
  [pnpm]="npm 経由で pnpm をグローバルインストールします。"
  [n]="npm 経由で n をグローバルインストールします。"
  [ai_clis]="npm 経由で Claude Code / Codex CLI / Gemini CLI をインストールします。"
  [generative_commit_message]="GitHub リポジトリを配置し、既知の形式ならローカルインストールします。"
)

declare -A TOOL_SELECTED
for tool_id in "${TOOL_IDS[@]}"; do
  TOOL_SELECTED["$tool_id"]=0
done

log() {
  printf '[tool-install] %s\n' "$*"
}

die() {
  printf '[tool-install] %s\n' "$*" >&2
  exit 1
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  die "Homebrew が見つかりません。https://brew.sh/ を参照して先にインストールしてください。"
}

render_menu() {
  clear
  cat <<EOF
macOS Tool Installer

数字を入力すると選択を切り替えます。
複数指定は空白区切りで入力してください。

  a すべて選択
  n すべて解除
  i インストール開始
  q 終了
EOF

  echo

  local index=1
  local tool_id
  local mark
  for tool_id in "${TOOL_IDS[@]}"; do
    if [[ "${TOOL_SELECTED[$tool_id]}" -eq 1 ]]; then
      mark="x"
    else
      mark=" "
    fi

    printf ' [%s] %d. %s\n' "$mark" "$index" "${TOOL_LABELS[$tool_id]}"
    printf '     %s\n' "${TOOL_DESCRIPTIONS[$tool_id]}"
    index=$((index + 1))
  done
}

toggle_selection() {
  local input=$1

  if [[ ! "$input" =~ ^[0-9]+$ ]]; then
    log "不正な入力をスキップします: $input"
    return
  fi

  if (( input < 1 || input > ${#TOOL_IDS[@]} )); then
    log "範囲外の番号です: $input"
    return
  fi

  local tool_id="${TOOL_IDS[$((input - 1))]}"
  if [[ "${TOOL_SELECTED[$tool_id]}" -eq 1 ]]; then
    TOOL_SELECTED["$tool_id"]=0
  else
    TOOL_SELECTED["$tool_id"]=1
  fi
}

select_all() {
  local tool_id
  for tool_id in "${TOOL_IDS[@]}"; do
    TOOL_SELECTED["$tool_id"]=1
  done
}

select_none() {
  local tool_id
  for tool_id in "${TOOL_IDS[@]}"; do
    TOOL_SELECTED["$tool_id"]=0
  done
}

interactive_select() {
  local answer
  local token

  while true; do
    render_menu
    read -r -p '選択: ' answer

    case "$answer" in
      a|A)
        select_all
        ;;
      n|N)
        select_none
        ;;
      i|I)
        return
        ;;
      q|Q)
        log "インストールを中止しました。"
        exit 0
        ;;
      *)
        for token in $answer; do
          toggle_selection "$token"
        done
        ;;
    esac
  done
}

has_selection() {
  local tool_id
  for tool_id in "${TOOL_IDS[@]}"; do
    if [[ "${TOOL_SELECTED[$tool_id]}" -eq 1 ]]; then
      return 0
    fi
  done

  return 1
}

brew_install_formula() {
  local formula=$1

  if brew list --formula "$formula" >/dev/null 2>&1; then
    log "既にインストール済みです: $formula"
    return
  fi

  brew install "$formula"
}

brew_install_cask() {
  local cask=$1

  if brew list --cask "$cask" >/dev/null 2>&1; then
    log "既にインストール済みです: $cask"
    return
  fi

  brew install --cask "$cask"
}

ensure_docker() {
  brew_install_cask docker
}

ensure_github_cli() {
  brew_install_formula gh
}

ensure_golang() {
  brew_install_formula go
}

ensure_nodejs() {
  brew_install_formula node
}

ensure_npm_global() {
  local package_name=$1
  npm install -g "$package_name"
}

install_ai_clis() {
  ensure_nodejs
  ensure_npm_global "$CLAUDE_CODE_NPM_PACKAGE"
  ensure_npm_global "$CODEX_CLI_NPM_PACKAGE"
  ensure_npm_global "$GEMINI_CLI_NPM_PACKAGE"
}

install_generative_commit_message_tool() {
  ensure_nodejs

  if ! command -v git >/dev/null 2>&1; then
    if command -v xcode-select >/dev/null 2>&1; then
      die "git が見つかりません。Command Line Tools を導入してください: xcode-select --install"
    fi

    die "git が見つかりません。"
  fi

  mkdir -p "$(dirname "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR")"

  if [[ -d "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR/.git" ]]; then
    log "generative-commit-message-for-ai-tool を更新します。"
    git -C "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR" pull --ff-only
  else
    log "generative-commit-message-for-ai-tool を clone します。"
    git clone "$GENERATIVE_COMMIT_MESSAGE_REPO_URL" "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR"
  fi

  if [[ -f "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR/package.json" ]]; then
    log "package.json を検出したため npm でグローバルインストールします。"
    npm install -g "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR"
    return
  fi

  if [[ -f "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR/go.mod" ]]; then
    ensure_golang
    log "go.mod を検出したため go install を実行します。"
    (cd "$GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR" && go install ./...)
    rename_generative_commit_message_binary
    return
  fi

  log "既知のインストール形式を検出できなかったため、リポジトリ配置のみ完了しました: $GENERATIVE_COMMIT_MESSAGE_INSTALL_DIR"
}

rename_generative_commit_message_binary() {
  local gopath
  local source_bin
  local target_bin

  gopath="$(go env GOPATH)"
  source_bin="$gopath/bin/$GENERATIVE_COMMIT_MESSAGE_BIN_NAME"
  target_bin="$gopath/bin/$GENERATIVE_COMMIT_MESSAGE_ALIAS_NAME"

  if [[ ! -x "$source_bin" ]]; then
    die "go install 後のバイナリが見つかりません: $source_bin"
  fi

  mv -f "$source_bin" "$target_bin"
  log "バイナリを $GENERATIVE_COMMIT_MESSAGE_ALIAS_NAME にリネームしました: $target_bin"
}

run_install() {
  ensure_homebrew

  if [[ "${TOOL_SELECTED[docker]}" -eq 1 ]]; then
    ensure_docker
  fi

  if [[ "${TOOL_SELECTED[github_cli]}" -eq 1 ]]; then
    ensure_github_cli
  fi

  if [[ "${TOOL_SELECTED[golang]}" -eq 1 ]]; then
    ensure_golang
  fi

  if [[ "${TOOL_SELECTED[nodejs]}" -eq 1 ]]; then
    ensure_nodejs
  fi

  if [[ "${TOOL_SELECTED[pnpm]}" -eq 1 ]]; then
    ensure_nodejs
    ensure_npm_global pnpm
  fi

  if [[ "${TOOL_SELECTED[n]}" -eq 1 ]]; then
    ensure_nodejs
    ensure_npm_global n
  fi

  if [[ "${TOOL_SELECTED[ai_clis]}" -eq 1 ]]; then
    install_ai_clis
  fi

  if [[ "${TOOL_SELECTED[generative_commit_message]}" -eq 1 ]]; then
    install_generative_commit_message_tool
  fi
}

[[ "$(uname -s)" == "Darwin" ]] || die "このスクリプトは macOS 向けです。"

interactive_select

if ! has_selection; then
  die "インストール対象が選択されていません。"
fi

run_install

cat <<EOF

ツールインストールが完了しました。

確認候補:
- docker --version
- gh --version
- go version
- node --version
- npm --version
- pnpm --version
- n --version
- claude --version
- codex --version
- gemini --version
- gcm --help

補足:
- Docker Desktop は初回起動と権限付与が必要です。
- Homebrew 未導入の場合は https://brew.sh/ を参照して先にセットアップしてください。
EOF
