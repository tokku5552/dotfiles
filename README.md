# dotofiles

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
ln -s ./settings.json ~/Library/Application\ Support/Code/User/settings.json
```