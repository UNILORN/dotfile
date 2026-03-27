## Linux / WSL: Git GPG Setup

```sh
chmod +x ./scripts/linux/setup-gpg-for-git.sh
./scripts/linux/setup-gpg-for-git.sh --name "Your Name" --email "you@example.com"
```

このスクリプトは以下を行います。

- `gpg` / `gpg2` の確認と不足時インストール
- GitHub Docs ベースの対話式 GPG キー生成
- `git config --global user.name`
- `git config --global user.email`
- `git config --global user.signingkey`
- `git config --global commit.gpgsign true`
- `git config --global tag.gpgSign true`
- GitHub へ登録するための公開鍵ファイル出力

GitHub への公開鍵追加は Web UI で行います。

## Linux: Tool Installer

```sh
./install.sh tools
```

対話メニューで選択できるもの:

- docker command
- golang
- nodejs / npm
- pnpm
- n
- claude code / codex cli / gemini cli
- generative-commit-message-for-ai-tool (`gcm` にリネーム)
