#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/linux/setup-gpg-for-git.sh [--name "Your Name"] [--email "you@example.com"] [--no-default-sign]

Options:
  --name             Git user.name and GPG UID name
  --email            Git user.email and GPG UID email
  --no-default-sign  Do not enable commit/tag signing by default
  -h, --help         Show this help

This script follows the GitHub Docs flow for Linux:
https://docs.github.com/ja/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
EOF
}

log() {
  printf '[gpg-setup] %s\n' "$*"
}

die() {
  printf '[gpg-setup] %s\n' "$*" >&2
  exit 1
}

prompt_if_empty() {
  local var_name=$1
  local prompt_text=$2
  local current_value=${!var_name:-}

  if [[ -n "$current_value" ]]; then
    return
  fi

  read -r -p "$prompt_text" current_value
  printf -v "$var_name" '%s' "$current_value"
}

install_gnupg_if_needed() {
  if command -v gpg >/dev/null 2>&1 || command -v gpg2 >/dev/null 2>&1; then
    return
  fi

  log "GnuPG が見つかりません。インストールを試みます。"

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y gnupg2 pinentry-curses
    return
  fi

  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y gnupg2 pinentry
    return
  fi

  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y gnupg2 pinentry
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm gnupg pinentry
    return
  fi

  if command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install gpg2 pinentry
    return
  fi

  die "GnuPG を自動インストールできませんでした。手動でインストールしてから再実行してください。"
}

version_ge() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

NAME=""
EMAIL=""
ENABLE_DEFAULT_SIGNING=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      NAME=${2:-}
      shift 2
      ;;
    --email)
      EMAIL=${2:-}
      shift 2
      ;;
    --no-default-sign)
      ENABLE_DEFAULT_SIGNING=0
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

install_gnupg_if_needed

if command -v gpg >/dev/null 2>&1; then
  GPG_BIN="gpg"
elif command -v gpg2 >/dev/null 2>&1; then
  GPG_BIN="gpg2"
else
  die "gpg コマンドが見つかりません。"
fi

if [[ "$GPG_BIN" == "gpg2" ]]; then
  git config --global gpg.program gpg2
fi

prompt_if_empty NAME "Git / GPG に設定する名前を入力してください: "
prompt_if_empty EMAIL "GitHub で確認済みのメールアドレスを入力してください: "

[[ -n "$NAME" ]] || die "名前が空です。"
[[ -n "$EMAIL" ]] || die "メールアドレスが空です。"

git config --global user.name "$NAME"
git config --global user.email "$EMAIL"

GPG_VERSION="$("$GPG_BIN" --version | awk 'NR==1 {print $3}')"

log "これから GPG キーを生成します。"
log "GitHub Docs に従い、メールアドレスには GitHub で確認済みのものを使ってください。"
log "名前: $NAME"
log "メール: $EMAIL"

if version_ge "$GPG_VERSION" "2.1.17"; then
  "$GPG_BIN" --full-generate-key
else
  "$GPG_BIN" --default-new-key-algo rsa4096 --gen-key
fi

log "生成後の秘密鍵一覧:"
"$GPG_BIN" --list-secret-keys --keyid-format=long "$EMAIL" || true

KEY_ID="$("$GPG_BIN" --list-secret-keys --with-colons --keyid-format=long "$EMAIL" | awk -F: '/^sec:/ {print $5; exit}')"

[[ -n "$KEY_ID" ]] || die "生成した GPG キー ID を取得できませんでした。"

git config --global user.signingkey "$KEY_ID"

if [[ "$ENABLE_DEFAULT_SIGNING" -eq 1 ]]; then
  git config --global commit.gpgsign true
  git config --global tag.gpgSign true
fi

mkdir -p "$HOME/.gnupg"
PUBLIC_KEY_FILE="$HOME/.gnupg/github-${KEY_ID}.asc"
"$GPG_BIN" --armor --export "$KEY_ID" > "$PUBLIC_KEY_FILE"

cat <<EOF

GPG キーの設定が完了しました。

Key ID:
  $KEY_ID

公開鍵ファイル:
  $PUBLIC_KEY_FILE

次の手順:
1. 以下のコマンドで公開鍵を確認します。
   cat "$PUBLIC_KEY_FILE"
2. 表示された -----BEGIN PGP PUBLIC KEY BLOCK----- から -----END PGP PUBLIC KEY BLOCK----- までをコピーします。
3. GitHub の GPG Key 設定画面を開いて貼り付けます。
   https://github.com/settings/keys
4. 署名確認:
   echo "test" | git hash-object --stdin
   git config --global --get user.signingkey

参考:
- GPG キー生成:
  https://docs.github.com/ja/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
- GitHub アカウントへの GPG キー追加:
  https://docs.github.com/ja/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account
- Git へ署名キーを伝える:
  https://docs.github.com/ja/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
EOF
