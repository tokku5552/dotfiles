
foreach ($item in Get-Content extensions) {
    code --install-extension $item
}