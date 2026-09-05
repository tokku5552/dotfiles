#!/bin/sh
# Stop hook: give the session a title that reflects its first turn.
#
# At the end of a turn, if the session has not been renamed yet, nudge Claude
# once -- exit 2 keeps the turn going and shows stderr to Claude -- and never
# nudge the same session again. So a session is renamed at the point where it
# is clear what it is about, and costs one short extra turn to do it.
#
# Exit 0 = let the session stop. Exit 2 = continue the turn.
# Every unexpected condition exits 0: a session title is not worth breaking a
# turn over.

set -eu

# mcp__ccd_session_mgmt__* only exists in the Claude desktop app.
if [ "${CLAUDE_CODE_ENTRYPOINT:-}" != "claude-desktop" ]; then
  exit 0
fi

INPUT=$(cat)

# printf, not echo: /bin/sh's echo expands backslash escapes and corrupts JSON.
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Already inside a hook-driven continuation; do not stack another one.
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

MARKER_DIR="${TMPDIR:-/tmp}/claude-session-title"
MARKER="$MARKER_DIR/$SESSION_ID"

# Handled (or already nudged) for this session.
if [ -e "$MARKER" ]; then
  exit 0
fi

# Agent-driven sessions (origin "peer"/"coordinator") are not the user's own
# conversations; leave their titles alone.
if ! grep -qF '"origin":{"kind":"human"}' "$TRANSCRIPT"; then
  exit 0
fi

# Scheduled runs are tagged human too, so check the shape of the first prompt:
# the launcher wraps it in <scheduled-task name="..." file="...">. Their titles
# carry the task name and are worth keeping. Read only the first user line --
# a conversation *about* scheduled tasks quotes that tag further down.
FIRST_PROMPT=$(grep -m1 -F '"type":"user"' -- "$TRANSCRIPT" \
  | jq -r 'if (.message.content | type) == "string" then .message.content else "" end' \
  2>/dev/null || true)
case "$FIRST_PROMPT" in
  '<scheduled-task '*) exit 0 ;;
esac

# Claim the nudge before spending it, so a session is nudged at most once even
# if Claude ignores the message below.
mkdir -p "$MARKER_DIR"
: > "$MARKER"

# Match the tool_use block, not prose that merely names the tool: the nudge
# below and any tool-schema listing also land in the transcript. Only a real
# call is followed by its "input" object.
if grep -qF '"name":"mcp__ccd_session_mgmt__set_session_title","input":' "$TRANSCRIPT"; then
  exit 0
fi

cat >&2 <<'MSG'
This session still carries its auto-generated title. Call
mcp__ccd_session_mgmt__set_session_title (load it with ToolSearch first if it is
not already in your tool list) with session_id "self" and a concise
Japanese title (noun phrase, roughly 20-30 characters, no trailing punctuation)
describing what this session is about, then reply with one short line and
nothing else.
MSG
exit 2
