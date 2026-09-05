#!/usr/bin/env bash
#
# Link Claude Code's config into ~/.claude and generate its settings.
#
# ~/.claude/settings.json is NOT a symlink into this repo: Claude Code writes
# that file itself, so sharing it directly across machines puts every UI toggle
# into version control. claude/sync.sh generates it from the shared base plus
# this machine's overlay instead. See claude/sync.sh for the full model.
#
# Run with Claude Code closed: it rewrites the whole settings file from an
# earlier read, and would undo what sync.sh just merged.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# MCP settings
# claude mcp add gemini-cli -s user -- npx mcp-gemini-cli --allow-npx
# claude mcp add fetch -s user -- uvx mcp-server-fetch
# claude mcp add codex -s user codex mcp

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
backed_up=0

# Created lazily so an idempotent re-run does not leave an empty directory
# behind (link.sh creates its backup dir unconditionally and does).
backup() {
  local target="$1"
  [ -e "$target" ] || return 0
  mkdir -p "$BACKUP_DIR"
  # -L so a symlinked target is backed up by content, not as a dangling link.
  cp -RL "$target" "$BACKUP_DIR/$(basename "$target")"
  backed_up=1
  echo "Backed up: $target -> $BACKUP_DIR/$(basename "$target")"
}

mkdir -p "$CLAUDE_DIR"

ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Back up a real scripts directory (a symlink is already ours).
if [ -d "$CLAUDE_DIR/scripts" ] && [ ! -L "$CLAUDE_DIR/scripts" ]; then
  backup "$CLAUDE_DIR/scripts"
  rm -rf "$CLAUDE_DIR/scripts"
fi
ln -sfn "$DOTFILES_DIR/claude/scripts" "$CLAUDE_DIR/scripts"
chmod +x "$DOTFILES_DIR"/claude/scripts/*.sh

# Back up the live settings only on the first run on this machine, i.e. while
# there is no snapshot. That is the migration case, where the live file is the
# only copy of this machine's state. Afterwards a re-run is safe without one:
# sync.sh carries unpersisted drift forward and refuses to write on conflict.
if [ ! -e "$CLAUDE_DIR/.settings.snapshot.json" ]; then
  backup "$CLAUDE_DIR/settings.json"
fi

# Generate ~/.claude/settings.json from base + overlay. Exits non-zero (and
# writes nothing) on a merge conflict, leaving the current settings in place.
bash "$DOTFILES_DIR/claude/sync.sh" --merge "$@"

if [ "$backed_up" -eq 1 ]; then
  echo ""
  echo "Backup location: $BACKUP_DIR"
fi
