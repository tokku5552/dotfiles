# !/bin/sh

npm install -g @anthropic-ai/claude-code

# MCP settings
claude mcp add gemini-cli -s user -- npx mcp-gemini-cli --allow-npx
claude mcp add fetch -s user -- uvx mcp-server-fetch
claude mcp add codex -s user codex mcp

# symbolic link
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/
