# UNILORN dotfile

mac と Linux / WSL の初期構築に使うリポジトリです。

現状は fish shell 周りの設定と、Linux 向けのツールインストーラを用意しています。

## Scope

- `fish` のインストールと初期設定
- fish 用の設定ファイル、functions、completions、Fisher 管理ファイルの配置
- ツール群の対話式インストール
- Git のコミット署名用 GPG キー生成と Git 設定

## Directory Layout

```text
.
|-- .config/
|   |-- fish/
|   `-- fisher/
|-- install.sh
`-- scripts/
    `-- linux/
        |-- README.md
        |-- install-tools.sh
        |-- setup-fish.md
        |-- setup-fish.sh
        `-- setup-gpg-for-git.sh
    `-- macos/
        `-- install-tools.sh
```

## Quick Start

```sh
git clone https://github.com/UNILORN/dotfile
cd dotfile
./install.sh
```

`install.sh` はエントリーポイントで、`fish` と `tools` のサブコマンドを切り替えます。

ツールインストーラは次で起動します。

```sh
./install.sh tools
```

## Linux / WSL

### fish の初期構築

```sh
./scripts/linux/setup-fish.sh
```

このスクリプトで以下を実行します。

- `fish`, `git`, `curl`, `peco` のインストール
- `~/.config/fish` への設定同期
- `~/.config/fisher` への Fisher 管理ファイル同期
- 既存 `fish_variables` の削除
- 独自 prompt と色設定の検証
- Linux では `chsh` によるデフォルトシェル変更
- WSL ではログインシェル変更をスキップ

必要に応じて、デフォルトシェル変更を避けたい場合は次を使います。

```sh
./scripts/linux/setup-fish.sh --skip-default-shell
```

詳細は `./scripts/linux/setup-fish.md` を参照してください。

設定だけを再同期したい場合は次を実行します。

```sh
./scripts/linux/apply-fish-config.sh
```

### Git GPG セットアップ

```sh
./scripts/linux/setup-gpg-for-git.sh --name "Your Name" --email "you@example.com"
```

このスクリプトで以下を実行します。

- `gpg` / `gpg2` の確認と不足時インストール
- GitHub Docs ベースの対話式 GPG キー生成
- `git config --global user.name`
- `git config --global user.email`
- `git config --global user.signingkey`
- `git config --global commit.gpgsign true`
- `git config --global tag.gpgSign true`
- GitHub に登録するための公開鍵ファイル出力

GitHub への公開鍵追加は Web UI で行います。詳細は `./scripts/linux/README.md` を参照してください。

### ツールインストール

```sh
./install.sh tools
```

Linux では番号トグル式の対話メニューを開き、以下をまとめてインストールできます。

- `docker` command
- `golang`
- `nodejs` / `npm`
- `pnpm`
- `n`
- `claude code`, `codex cli`, `gemini cli`
- `generative-commit-message-for-ai-tool` (`gcm` にリネーム)

AI CLI の npm パッケージ名や GitHub リポジトリ URL はスクリプト内の環境変数で上書きできます。

## Notes

- `.config/fish/fish_variables` は配布しません。ユーザー環境依存のため、各環境で fish が生成する前提です。
- 共通の色設定と `fish_greeting` は `.config/fish/conf.d/colors.fish` で管理します。
- `config.fish` は Linux / macOS 両方で壊れにくいように調整していますが、エイリアスや functions は個人用途前提のものを含みます。
- macOS 向けツールインストーラは現時点では骨組みのみです。
