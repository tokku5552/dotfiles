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

- .Brewfileのdump

```zsh
brew bundle dump --global
```

- brewにインストールされているアプリケーションの一覧出力

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

# for asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc
asdf plugin-add nodejs
asdf install nodejs 18.16.1
asdf global nodejs 18.16.1

# python and poetry
asdf plugin-add python
asdf install python 3.8.13
asdf global python 3.8.13

asdf plugin-add poetry
asdf install poetry latest
asdf global poetry latest

# terraform
asdf plugin add terraform
asdf list all terraform 
asdf install terraform 1.4.6
asdf global terraform 1.4.6
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


## MCP info
- claude
  - context7
  - playwright
  - sequential-thinking
  - serena