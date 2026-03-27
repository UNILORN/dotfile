## Linux / WSL: Fish Setup

```sh
chmod +x ./scripts/linux/setup-fish.sh
./scripts/linux/setup-fish.sh
```

このスクリプトは以下を行います。

- fish のインストール
- `git`, `curl`, `peco` のインストール
- `.config/fish` の同期
- `.config/fisher` の同期
- `fish_variables` を配布対象から除外
- 独自 prompt と色設定の検証
- Linux では必要に応じて `chsh` によるデフォルトシェル変更
- WSL ではデフォルトシェル変更をスキップ

設定だけを再同期したいときは次を実行します。

```sh
./scripts/linux/apply-fish-config.sh
```
