# !/bin/sh

claude mcp add -s user gemini-cli -- npx mcp-gemini-cli --allow-npx
claude mcp add fetch -s user -- uvx mcp-server-fetch
claude mcp add codex -s user codex mcp