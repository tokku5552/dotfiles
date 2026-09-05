# !/bin/sh

# MCP settings
# claude mcp add gemini-cli -s user -- npx mcp-gemini-cli --allow-npx
# claude mcp add fetch -s user -- uvx mcp-server-fetch
# claude mcp add codex -s user codex mcp

# symbolic link
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/

# Claude Code hooks

# Backup existing scripts directory if it's a real directory (not a symlink)
if [ -d ~/.claude/scripts ] && [ ! -L ~/.claude/scripts ]; then
  mv ~/.claude/scripts ~/.claude/scripts.bak
  echo "Backed up existing scripts directory to scripts.bak"
fi

ln -sfn ~/dotfiles/claude/scripts ~/.claude/scripts
chmod +x ~/dotfiles/claude/scripts/*.sh

# Claude Code settings
#
# ~/.claude/settings.json is generated, not symlinked: Claude Code writes to it
# itself, so sharing it directly would put every UI toggle into git. sync.sh
# merges the shared base with this machine's settings.local.json instead.
# Run with Claude Code closed; see README.md.

# Back up the live settings on the first run on this machine (no snapshot yet).
# Until the split, that file is the only copy of this machine's state. -L because
# it is still a symlink into this repo at that point.
if [ -e ~/.claude/settings.json ] && [ ! -e ~/.claude/.settings.snapshot.json ]; then
  cp -L ~/.claude/settings.json ~/.claude/settings.json.bak
  echo "Backed up existing settings.json to settings.json.bak"
fi

# Last command on purpose: its exit status becomes this script's, so a merge
# conflict (exit 3, nothing written) is not swallowed.
bash ~/dotfiles/claude/sync.sh --merge "$@"
