# !/bin/sh

# MCP settings
# claude mcp add gemini-cli -s user -- npx mcp-gemini-cli --allow-npx
# claude mcp add fetch -s user -- uvx mcp-server-fetch
# claude mcp add codex -s user codex mcp

# symbolic link
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/

# Claude Code settings and hooks

# Backup existing settings.json if it's a real file (not a symlink)
if [ -f ~/.claude/settings.json ] && [ ! -L ~/.claude/settings.json ]; then
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
  echo "Backed up existing settings.json to settings.json.bak"
fi

ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json

# Backup existing scripts directory if it's a real directory (not a symlink)
if [ -d ~/.claude/scripts ] && [ ! -L ~/.claude/scripts ]; then
  mv ~/.claude/scripts ~/.claude/scripts.bak
  echo "Backed up existing scripts directory to scripts.bak"
fi

ln -sfn ~/dotfiles/claude/scripts ~/.claude/scripts
chmod +x ~/dotfiles/claude/scripts/*.sh
