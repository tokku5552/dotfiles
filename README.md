# dotofiles

## create symbolic link

```
cd ~
ln -sf ~/dotfiles/.zshrc ~
```

## prezto

```
cd ~
zsh
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
cd ~/dotfiles
make link
chsh -s /bin/zsh
```

ricty を Brewfile からインストールした後

```
which ricty
cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
fc-cache -vf
```

## homebrew

```
make brew
```

## VSCode Extension

- Export

```
code --list-extensions > extensions
```

- install extention

```shell:
cat ./VSCode/extensions | while read line
do
 code --install-extension $line
done
```

## Windows Install

```powershell:
New-Item -Type SymbolicLink -Value .\VSCode\settings.json -Path $env:APPDATA\Code\User -Name settings.json
```

## MacOS Install

```shell:
mv ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json.bk
ln -s ~/dotfiles/VSCode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```
