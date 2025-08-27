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

```zsh
make brew
```

## VSCode Extension

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

GitHub で共有しない環境変数を設定する場合：

```bash
# テンプレートファイルをコピー
cp zsh/.zshrc.local.example zsh/.zshrc.local

# ローカル設定ファイルを編集
vim zsh/.zshrc.local
```

設定可能な環境変数の例：
- API キー（GitHub、OpenAI、AWS など）
- データベース認証情報
- アプリケーション固有の設定
- 外部サービストークン

**注意**: `.zshrc.local` ファイルは `.gitignore` に含まれているため、GitHub にコミットされません。
