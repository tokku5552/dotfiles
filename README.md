# dotofiles

## create symbolic link

```zsh
cd ~
ln -sf ~/dotfiles/.zshrc ~
```

## prezto

```zsh
cd ~
zsh
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
cd ~/dotfiles
make link
chsh -s /bin/zsh
```

ricty を Brewfile からインストールした後

```zsh
which ricty
cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
fc-cache -vf
```

## homebrew

- install & upgrade

```zsh
make brew
```

- .Brewfile の dump

```zsh
brew bundle dump --global
```

- brew にインストールされているアプリケーションの一覧出力

```zsh

# cask
brew list --cask -1
```

## VSCode Extension

<!-- TODO: .Brewfileに統合されているかもしれない -->

- Export

```zsh
code --list-extensions > extensions
```

- install extention

```shell:
cat ./VSCode/extensions | while read line
do
 code --install-extension $line
done
```

- install extention (insiders)

```bash:
code --list-extensions | xargs -n 1 code-insiders --install-extension
```

## Windows Install

```powershell:
New-Item -Type SymbolicLink -Value .\VSCode\settings.json -Path $env:APPDATA\Code\User -Name settings.json
```

## MacOS Install

```shell:
mv ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json.bk
ln -s ~/dotfiles/VSCode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# for mise (zsh activation is loaded by the linked .zshrc)
mise use -g node@lts
mise use -g python@3.12
mise use -g poetry@latest
mise use -g terraform@latest
```

## asdf からの移行

既存マシンで asdf を使っていた場合の手順:

```zsh
# 1. mise をインストール
make brew

# 2. zshrc 等を再リンク（新 .zshrc と ~/.config/mise/config.toml へのリンクが貼られる）
make link

# 3. asdf 本体を Homebrew から削除
#    (`brew cleanup` は古いバージョンの掃除だけなので uninstall は手動)
brew uninstall asdf

# 4. asdf 側のバージョンデータと残ったドットファイルを削除
rm -rf ~/.asdf
rm -f ~/.asdfrc

# 5. 新しいシェルを起動して mise を有効化
exec zsh
mise --version

# 6. 既存の .tool-versions は mise がそのまま解釈する
#    ただし未インストールのバージョンは事前に mise install すること
mise install
```

- java configure

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

## 環境変数の設定

GitHub で共有しない環境変数とエイリアスを設定する場合：

### ローカル設定ファイルの作成

```bash
# zshrc のローカル設定（エイリアス、関数、対話的設定）
cp zsh/.zshrc.local.example zsh/.zshrc.local

# zshenv のローカル設定（グローバル環境変数）
cp zsh/.zshenv.local.example zsh/.zshenv.local

# ローカル設定ファイルを編集
vim zsh/.zshrc.local
vim zsh/.zshenv.local
```

### 設定可能な内容

**`.zshrc.local`（対話的シェル用）:**

- エイリアス（Git、Docker、Kubernetes など）
- カスタム関数
- ローカル PATH 追加
- プロンプトカスタマイズ
- キーバインド設定
- 履歴設定
- プラグイン設定

**`.zshenv.local`（グローバル環境変数用）:**

- API キー（GitHub、OpenAI、AWS など）
- データベース認証情報
- アプリケーション固有の設定
- 外部サービストークン
- グローバル PATH 追加
- 言語・ロケール設定
- エディタ設定

**注意**: `.zshrc.local` と `.zshenv.local` ファイルは `.gitignore` に含まれているため、GitHub にコミットされません。

## Claude Code の設定（PC ごとの差分）

Claude Code は `~/.claude/settings.json` を**読むだけでなく自分で書き戻す**（`theme`、
`effortLevel`、`advisorModel`、`enabledPlugins`、`extraKnownMarketplaces` など）。
そのため、このファイルを直接 symlink で共有すると UI 操作のたびに追跡ファイルが書き換わり、
PC 間で PR が競合する。そこで 3 つのファイルに分けている。

| ファイル | 追跡 | 役割 |
| --- | --- | --- |
| `claude/settings.json` | される | 全 PC 共通のベース |
| `claude/settings.local.json` | **されない** | この PC 固有のオーバーレイ |
| `~/.claude/settings.json` | — | 上 2 つから**生成**され、Claude Code が読み書きする |

**移行・運用・トラブルシュートの具体的な手順は
[docs/claude-settings-runbook.md](docs/claude-settings-runbook.md) にある。**
既に symlink 方式で使っている PC を移行するときは、順序を間違えると設定を失うので
必ずそちらを読むこと。

### セットアップ

```bash
# この PC 固有の設定を持つ場合のみ（無くても動く）
cp claude/settings.local.json.example claude/settings.local.json

bash claude/install.sh
```

`install.sh` は `CLAUDE.md` と `scripts/` を `~/.claude/` へ symlink し、
`claude/sync.sh --merge` を呼んで `~/.claude/settings.json` を生成する。
**`~/.claude/settings.json` は生成物なので手で編集しない**（マージのたびに上書きされる）。
共通の設定を変えたいときは `claude/settings.json` を編集して `install.sh` を再実行する。

### オーバーレイの意味論

`claude/settings.local.json` はトップレベルのキー単位でベースに重なる。

- ここにあるキーはベースのキーを**丸ごと**置き換える（エントリ単位のマージではない）
- 値を `null` にするとそのキーを削除する
- ここに無いキーはベースの値がそのまま使われる

`permissions` と `hooks` はオーバーレイに入れないこと。全 PC 共通のガードレールであり、
`deny-check.sh` は deny リストが読めないとき**ブロック側に倒れる**（fail closed）。

> `claude/settings.local.json` は、リポジトリルートにある**追跡済みの**
> `.claude/settings.local.json`（Claude Code のプロジェクトスコープ設定）とは別物。

### PR を出す前

Claude Code が書き戻した差分（ドリフト）を、共通側とこの PC 側に振り分ける。

```bash
bash claude/sync.sh            # 差分を表示するだけ。差分があれば exit 3
bash claude/sync.sh --apply    # 共通は settings.json、PC 固有は settings.local.json へ
git diff claude/settings.json  # 共通側に入った内容を必ず確認する
```

振り分け先は `claude/sync.sh` の `LOCAL_KEYS` で決まる。想定外のキーが `base` に
向かっていたら、そのキーを `LOCAL_KEYS` に 1 行足す。

### 他の PC の変更を取り込む

```bash
git pull
bash claude/install.sh
```

自分の PC のドリフトと、他の PC が入れた変更の両方が保持される（前回生成した内容を
`~/.claude/.settings.snapshot.json` に記録しているため 3-way マージができる）。
同じキーを両方が別々に変えていた場合は競合として報告され、**何も書かずに中断する**。
手で直すか、この PC の値を採用してよければ `--prefer-local` を付ける。

**install / sync は Claude Code を閉じた状態で実行すること。** 起動中の Claude Code は
古い読み取り結果でファイル全体を上書きするため、マージ結果が巻き戻ることがある。

`git clean -xdf` は `claude/settings.local.json` を消す（復旧不能）。
`zsh/.zshrc.local` と同じ扱いなので、除外するか実行しないこと。

# AI Agent

## Documents

- gemini-cli
  - https://google-gemini.github.io/gemini-cli/
- Cursor
  - https://cursor.com/ja/docs
- Claude Code
  - https://docs.claude.com/ja/docs/claude-code/overview
- Codex CLI
  - https://github.com/openai/codex

## MCP info

- SuperClaude
  - context7
  - playwright
  - sequential-thinking
  - serena
  - morphllm-fast-apply
  - magic
- Official Ref
  - fetch
  - mcp-gemini-cli
  - codex


