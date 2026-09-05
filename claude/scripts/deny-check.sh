#!/bin/sh
# PreToolUse hook: deny dangerous Bash commands
# Exit 0 = allow, Exit 2 = block

set -eu

SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Fail closed. An unreadable or malformed settings file must not silently
# disable the deny list: Claude Code drops every setting from a malformed file,
# so "no patterns found" would otherwise turn this guardrail off with no signal.
# Only a deny array that is explicitly present is allowed to yield no patterns.
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

# Deny array present but carrying no Bash(...) rules: nothing to enforce here.
if [ -z "$DENY_PATTERNS" ]; then
  exit 0
fi

# Check a single command against all deny patterns
check_command() {
  _cmd=$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [ -z "$_cmd" ]; then
    return 0
  fi

  echo "$DENY_PATTERNS" | while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue

    # Convert glob pattern to regex: escape dots, replace * with .*
    regex=$(echo "$pattern" | sed 's/\./\\./g; s/\*/.*/g')

    if echo "$_cmd" | grep -qE "^${regex}$"; then
      echo "BLOCKED: command '$_cmd' matches deny pattern '$pattern'" >&2
      exit 2
    fi
  done
}

# Split by ;, &&, || and check each segment
echo "$COMMAND" | tr ';' '\n' | sed 's/&&/\n/g; s/||/\n/g' | while IFS= read -r segment; do
  check_command "$segment"
done

exit 0
