#!/bin/sh
# PreToolUse hook: deny dangerous Bash commands
# Exit 0 = allow, Exit 2 = block

set -eu

# Overridable so the fail-closed behaviour can be exercised against a scratch
# file instead of the live settings.
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command
# NOTE: use printf, not echo -- /bin/sh's echo expands backslash escapes and
# corrupts the JSON payload before jq sees it (exit 5, "Invalid escape").
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Fail closed. An unreadable or malformed settings file must not silently
# disable the deny list: jq's parse error used to go to /dev/null, leaving zero
# patterns and an exit 0 that allowed everything. Claude Code also drops every
# setting from a malformed file, so the deny list and this hook would vanish
# together, with no signal. Require the deny array to actually be readable.
if ! jq -e '(.permissions.deny | type) == "array"' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "BLOCKED: cannot read permissions.deny from $SETTINGS_FILE (failing closed)" >&2
  exit 2
fi

# Extract deny patterns from settings.json, filtering Bash(...) entries
# and extracting the inner glob pattern
DENY_PATTERNS=$(jq -r '.permissions.deny[]' "$SETTINGS_FILE" \
  | grep '^Bash(' \
  | sed 's/^Bash(//; s/)$//' \
  || true)

# A deny array that is present but carries no Bash(...) rules is a legitimate
# configuration: there is nothing for this hook to enforce, so allow.
if [ -z "$DENY_PATTERNS" ]; then
  exit 0
fi

# Check a single command against all deny patterns.
# Returns 0 to allow, 2 to block.
check_command() {
  _cmd=$(printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [ -z "$_cmd" ]; then
    return 0
  fi

  # NOTE: fed by redirect, not by a pipe. A `while` on the right-hand side of a
  # pipe runs in a subshell, so a `return`/`exit` there never reaches the caller.
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue

    # Convert glob pattern to regex: escape dots, replace * with .*
    regex=$(printf '%s' "$pattern" | sed 's/\./\\./g; s/\*/.*/g')

    if printf '%s' "$_cmd" | grep -qE "^${regex}$"; then
      echo "BLOCKED: command '$_cmd' matches deny pattern '$pattern'" >&2
      return 2
    fi
  done <<EOF
$DENY_PATTERNS
EOF

  return 0
}

# Split by ;, && and || and check each segment.
# NOTE: the replacement is a literal backslash-newline -- BSD sed does not read
# "\n" in a replacement as a newline, so the escapes must be spelled out.
SEGMENTS=$(printf '%s' "$COMMAND" | tr ';' '\n' | sed 's/&&/\
/g; s/||/\
/g')

while IFS= read -r segment; do
  check_command "$segment" || exit 2
done <<EOF
$SEGMENTS
EOF

exit 0
