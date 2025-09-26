# !/bin/sh

# MCP settings
codex mcp add claude -- claude mcp
codex mcp add gemini-cli -- npx mcp-gemini-cli --allow-npx
codex mcp add fetch -- uvx mcp-server-fetch


# symbolic link
ln -sf ~/dotfiles/codex/AGENTS.md ~/.codex/
