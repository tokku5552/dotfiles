#!/bin/sh

set -euo pipefail

# バックアップディレクトリを作成
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# バックアップしたファイルのリスト
BACKUP_FILES=""

# バックアップ関数
backup_if_exists() {
    local target_file="$1"
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        local backup_file="$BACKUP_DIR/$(basename "$target_file")"
        cp -r "$target_file" "$backup_file"
        BACKUP_FILES="$BACKUP_FILES$target_file\n"
        echo "Backed up: $target_file -> $backup_file"
    fi
}

echo "Creating symbolic links..."

# create symbolic link
backup_if_exists "$HOME/.zshrc"
ln -sf ~/dotfiles/zsh/.zshrc ~

backup_if_exists "$HOME/.zlogin"
ln -sf ~/dotfiles/zsh/.zlogin ~

backup_if_exists "$HOME/.zlogout"
ln -sf ~/dotfiles/zsh/.zlogout ~

backup_if_exists "$HOME/.zpreztorc"
ln -sf ~/dotfiles/zsh/.zpreztorc ~

backup_if_exists "$HOME/.zprofile"
ln -sf ~/dotfiles/zsh/.zprofile ~

backup_if_exists "$HOME/.zshenv"
ln -sf ~/dotfiles/zsh/.zshenv ~

backup_if_exists "$HOME/.asdfrc"
ln -sf ~/dotfiles/asdf/.asdfrc ~

echo ""
echo "Symbolic links created successfully!"
echo ""

# バックアップしたファイルを列挙
if [ -n "$BACKUP_FILES" ]; then
    echo "Backed up files:"
    echo "$BACKUP_FILES" | grep -v "^$"
    echo ""
    echo "Backup location: $BACKUP_DIR"
else
    echo "No existing files were backed up."
fi