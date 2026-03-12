# !/bin/sh

npm install -g @anthropic-ai/claude-code

# MCP settings
claude mcp add gemini-cli -s user -- npx mcp-gemini-cli --allow-npx
claude mcp add fetch -s user -- uvx mcp-server-fetch
claude mcp add codex -s user codex mcp

# symbolic link
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/

# Claude Code settings and hooks
mkdir -p ~/.claude/scripts

# Backup existing settings.json if it's a real file (not a symlink)
if [ -f ~/.claude/settings.json ] && [ ! -L ~/.claude/settings.json ]; then
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
  echo "Backed up existing settings.json to settings.json.bak"
fi

ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/claude/scripts/deny-check.sh ~/.claude/scripts/deny-check.sh
chmod +x ~/dotfiles/claude/scripts/deny-check.sh
