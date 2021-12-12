# dotofiles

## VSCode Extension
- Export
```
code --list-extensions > extensions
```

## Windows Install
```powershell:
New-Item -Type SymbolicLink -Value .\VSCode\settings.json -Path $env:APPDATA\Code\User -Name settings.json
```