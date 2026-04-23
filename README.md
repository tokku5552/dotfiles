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


