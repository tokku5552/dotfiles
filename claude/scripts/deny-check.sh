#!/bin/sh
# PreToolUse hook: deny dangerous Bash commands
# Exit 0 = allow, Exit 2 = block

set -eu

SETTINGS_FILE="$HOME/.claude/settings.json"

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Extract deny patterns from settings.json
DENY_PATTERNS=$(jq -r '.permissions.deny[]' "$SETTINGS_FILE" 2>/dev/null | while read -r pattern; do
  # Only process Bash(...) patterns
  case "$pattern" in
    Bash\(*)
      # Extract the glob inside Bash(...)
      echo "$pattern" | sed 's/^Bash(\(.*\))$/\1/'
      ;;
  esac
done)

if [ -z "$DENY_PATTERNS" ]; then
  exit 0
fi

# Split command by ;, &&, || and check each part
check_command() {
  local cmd="$1"
  # Trim leading/trailing whitespace
  cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [ -z "$cmd" ]; then
    return 0
  fi

  echo "$DENY_PATTERNS" | while read -r pattern; do
    if [ -z "$pattern" ]; then
      continue
    fi

    # Convert glob pattern to grep regex
    # Replace * with .* for matching
    regex=$(echo "$pattern" | sed 's/\./\\./g; s/\*/.*/g')

    if echo "$cmd" | grep -qE "^${regex}$"; then
      echo "BLOCKED: command '$cmd' matches deny pattern '$pattern'" >&2
      exit 2
    fi
  done
}

# Split by ;, &&, || and check each segment
echo "$COMMAND" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g' | while read -r segment; do
  check_command "$segment"
done

exit 0
