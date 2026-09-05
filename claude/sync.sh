#!/usr/bin/env bash
#
# Reconcile Claude Code's user settings across machines.
#
# Claude Code reads AND WRITES ~/.claude/settings.json (theme, effortLevel,
# advisorModel, enabledPlugins, extraKnownMarketplaces, ...). Sharing that file
# directly across machines therefore means every UI toggle lands in the tracked
# dotfiles file and PRs conflict. Instead:
#
#   claude/settings.json         shared base, tracked
#   claude/settings.local.json   this machine's overlay, gitignored, optional
#   ~/.claude/settings.json      generated: base + overlay. Claude Code owns it.
#   ~/.claude/.settings.snapshot.json
#                                what we generated last time -- the common
#                                ancestor that makes a 3-way merge possible
#
# The snapshot is what lets us tell "this machine drifted" apart from "another
# machine changed the base". Without it, pulling a base change on machine B and
# then persisting would silently revert machine A's work.
#
# Granularity is TOP-LEVEL KEYS throughout: composition, comparison and routing
# all treat a top-level key as one unit, and the overlay owns a key outright
# when it mentions it. A base key the overlay is silent about still propagates
# normally. Composing recursively instead would break the invariant below --
# an overlay that drops one entry from enabledPlugins could not suppress the
# base's copy, so base+overlay would no longer reproduce the merge result.
#
# Exit codes:
#   0  success; --report found nothing to do
#   1  usage error or missing prerequisite
#   2  an input file is not a JSON object
#   3  --report found drift; --merge/--apply hit a conflict and wrote nothing
#   4  a safety postcondition failed

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

BASE="$DOTFILES_DIR/claude/settings.json"
OVERLAY="$DOTFILES_DIR/claude/settings.local.json"
LIVE="$CLAUDE_DIR/settings.json"
SNAPSHOT="$CLAUDE_DIR/.settings.snapshot.json"

# Top-level keys that belong to this machine rather than to every machine.
# Rule of thumb: if Claude Code writes the key back on its own, it belongs here,
# otherwise every write-back is routed into the tracked base and causes the very
# conflicts this script exists to prevent. Add a line when --report shows an
# unexpected key heading for "base".
LOCAL_KEYS=(
  theme
  agentPushNotifEnabled
  enabledPlugins
  extraKnownMarketplaces
)

MODE="report"
PREFER="none"
DRY_RUN=0

die() { printf '%s\n' "$2" >&2; exit "$1"; }

usage() {
  cat <<'EOF'
Usage: sync.sh [MODE] [OPTIONS]

Modes (mutually exclusive; default --report):
  --report          Report drift and upstream changes. Writes nothing.
  --merge           3-way merge -> ~/.claude/settings.json + snapshot.
  --apply           Persist this machine's drift into the base/overlay
                    according to the key list, then merge.

Options:
  --prefer-local    Resolve conflicts in favour of this machine instead of
                    refusing. Conflict-resolved keys are never persisted.
  -n, --dry-run     Print what would be written, write nothing.
  -h, --help        This text.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --report) MODE="report" ;;
    --merge)  MODE="merge" ;;
    --apply)  MODE="apply" ;;
    --prefer-local) PREFER="local" ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die 1 "unknown argument: $1" ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || die 1 "jq is required (brew install jq)"
[ -f "$BASE" ] || die 1 "shared base not found: $BASE"

# A settings file that is valid JSON but not an object (e.g. "[]") would reach
# the merge operator and abort with jq's own exit 5 instead of our documented 2.
# `jq -e .` is not enough: it exits 0 for an array.
read_object() {
  local path="$1" default="$2"
  if [ -e "$path" ]; then
    jq -e 'type == "object"' "$path" >/dev/null 2>&1 \
      || die 2 "not a JSON object: $path"
    cat "$path"
  else
    printf '%s' "$default"
  fi
}

# Write via a temp file in the destination directory so readers -- Claude Code
# itself, and deny-check.sh mid-hook -- never observe a truncated file. A
# truncated settings file disables every setting silently, deny list included.
atomic_write() {
  local dest="$1" tmp
  tmp="$(mktemp "${dest}.XXXXXX")"
  cat >"$tmp"
  if ! jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    die 2 "refusing to write a non-object to $dest"
  fi
  mv -f "$tmp" "$dest"
}

if [ "$(git -C "$DOTFILES_DIR" rev-parse --git-dir 2>/dev/null)" \
   != "$(git -C "$DOTFILES_DIR" rev-parse --git-common-dir 2>/dev/null)" ]; then
  printf 'warning: running from a git worktree (%s).\n' "$DOTFILES_DIR" >&2
  printf '         its base will be installed as your live settings.\n' >&2
fi

BASE_JSON="$(read_object "$BASE" '{}')"
OVERLAY_JSON="$(read_object "$OVERLAY" '{}')"
LIVE_JSON="$(read_object "$LIVE" '{}')"
SNAPSHOT_JSON="$(read_object "$SNAPSHOT" '{}')"
LOCAL_KEYS_JSON="$(printf '%s\n' "${LOCAL_KEYS[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')"

# ---------------------------------------------------------------------------
# Classify. Top-level keys, wrapped as {v: ...} / null so that "absent" is
# distinguishable from a null value.
#
#   l == u  -> both sides agree (including both absent)      take live
#   l == a  -> only upstream moved                           take upstream
#   u == a  -> only this machine moved                       take live
#   else    -> both moved differently                        CONFLICT
#
# Deletions need no special case; they fall out of the table.
# ---------------------------------------------------------------------------
CLASSIFY='
def at($o; $k): if ($o | has($k)) then {v: $o[$k]} else null end;
def kind($from; $to): if $from == null then "+" elif $to == null then "-" else "~" end;

(($base + $overlay) | with_entries(select(.value != null))) as $up
| ([($anc | keys), ($live | keys), ($up | keys)] | add | unique) as $keys
| reduce $keys[] as $k (
    {merged: {}, conflicts: [], local: [], upstream: []};
    at($anc; $k) as $a | at($live; $k) as $l | at($up; $k) as $u
    | if $l == $u then
        (if $l then .merged[$k] = $l.v else . end)
      elif $l == $a then
        (if $u then .merged[$k] = $u.v else . end)
        | .upstream += [{key: $k, kind: kind($a; $u), from: $a.v, to: $u.v}]
      elif $u == $a then
        (if $l then .merged[$k] = $l.v else . end)
        | .local += [{key: $k, kind: kind($a; $l), from: $a.v, to: $l.v}]
      elif $prefer == "local" then
        (if $l then .merged[$k] = $l.v else . end)
        | .local += [{key: $k, kind: kind($a; $l), from: $a.v, to: $l.v, resolved: true}]
      else
        .conflicts += [{key: $k, ancestor: $a.v, local: $l.v, upstream: $u.v}]
      end
  )
| .composed = $up
'

RESULT="$(jq -n \
  --argjson anc "$SNAPSHOT_JSON" \
  --argjson live "$LIVE_JSON" \
  --argjson base "$BASE_JSON" \
  --argjson overlay "$OVERLAY_JSON" \
  --arg prefer "$PREFER" \
  "$CLASSIFY")"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
RENDER='
def short: tojson | if length > 30 then .[0:27] + "..." else . end;
def target($k):
                  # LOCAL_KEYS wins outright. Deciding by "where the key lives today" first
                  # sent every listed key that the base already carries straight back to the
                  # base -- which is exactly the second machine migrating.
                  if ($k | IN($lk[])) then "overlay"
                  elif ($overlay | has($k)) then "overlay"
                  else "base" end;
def rows($list; $withTarget):
  if ($list | length) == 0 then "  (none)"
  else ($list | map(
    "  \(.kind)  \(.key)"
    + (if .from == null then "" else "  \(.from | short) ->" end)
    + (if $withTarget then "  [\(target(.key))]" else "" end)
    + (if .to == null then "  (removed)" else "  \(.to | short)" end)
    + (if .resolved then "  (conflict resolved --prefer-local; not persisted)" else "" end)
  ) | join("\n")) end;

"LOCAL DRIFT   live vs snapshot                    \(.local | length) key(s)",
rows(.local; true),
"",
"UPSTREAM      base+overlay vs snapshot            \(.upstream | length) key(s)",
rows(.upstream; false),
"",
"CONFLICTS                                         \(.conflicts | length) key(s)",
(if (.conflicts | length) == 0 then "  (none)"
 else (.conflicts | map(
   "  !  \(.key)\n       ancestor  \(.ancestor | short)\n       local     \(.local | short)\n       upstream  \(.upstream | short)"
 ) | join("\n")) end)
'

jq -r \
  --argjson base "$BASE_JSON" \
  --argjson overlay "$OVERLAY_JSON" \
  --argjson lk "$LOCAL_KEYS_JSON" \
  "$RENDER" <<<"$RESULT"
echo

N_CONFLICT="$(jq '.conflicts | length' <<<"$RESULT")"
N_LOCAL="$(jq '.local | length' <<<"$RESULT")"
N_UPSTREAM="$(jq '.upstream | length' <<<"$RESULT")"

if [ "$MODE" = "report" ]; then
  if [ "$N_LOCAL" -eq 0 ] && [ "$N_UPSTREAM" -eq 0 ] && [ "$N_CONFLICT" -eq 0 ]; then
    echo "in sync."
    exit 0
  fi
  echo "run 'claude/sync.sh --apply' to persist local drift into base/overlay,"
  echo "or 'claude/sync.sh --merge' to take upstream and leave drift unpersisted."
  exit 3
fi

if [ "$N_CONFLICT" -gt 0 ]; then
  echo "refusing to write. resolve by hand in claude/settings.json or" >&2
  echo "claude/settings.local.json, or re-run with --prefer-local." >&2
  exit 3
fi

# ---------------------------------------------------------------------------
# Route (--apply). Only keys where "this machine alone moved" are persisted:
# routing a key that upstream also changed is exactly the lost update the
# snapshot exists to prevent. Conflict resolutions are reported, never written.
# Destination is decided by where the key already lives, falling back to the
# key list -- otherwise deleting a key that only the overlay carries would be a
# no-op on the base and the same drift would be reported forever.
# ---------------------------------------------------------------------------
ROUTE='
def target($k):
                  # LOCAL_KEYS wins outright. Deciding by "where the key lives today" first
                  # sent every listed key that the base already carries straight back to the
                  # base -- which is exactly the second machine migrating.
                  if ($k | IN($lk[])) then "overlay"
                  elif ($overlay | has($k)) then "overlay"
                  else "base" end;
reduce ($drift[] | select(.resolved | not)) as $d
  ({base: $base, overlay: $overlay, routes: []};
    $d.key as $k | target($k) as $t
    | if $d.kind == "-" then
        (if $t == "overlay" then .overlay[$k] = null
         else .base |= del(.[$k]) | .overlay |= del(.[$k]) end)
      else
        (if $t == "overlay" then .overlay[$k] = $d.to else .base[$k] = $d.to end)
      end
    | .routes += [{key: $k, kind: $d.kind, target: $t}])
'

NEW_BASE="$BASE_JSON"
NEW_OVERLAY="$OVERLAY_JSON"

if [ "$MODE" = "apply" ] && [ "$N_LOCAL" -gt 0 ]; then
  ROUTED="$(jq -n \
    --argjson base "$BASE_JSON" \
    --argjson overlay "$OVERLAY_JSON" \
    --argjson lk "$LOCAL_KEYS_JSON" \
    --argjson drift "$(jq '.local' <<<"$RESULT")" \
    "$ROUTE")"
  NEW_BASE="$(jq '.base' <<<"$ROUTED")"
  NEW_OVERLAY="$(jq '.overlay' <<<"$ROUTED")"

  echo "routing:"
  jq -r '.routes[] | "  \(.kind)  \(.key) -> \(.target)"' <<<"$ROUTED"
  echo
fi

MERGED="$(jq '.merged' <<<"$RESULT")"

# Invariant, --apply only: once drift has been routed, re-composing the two
# files must reproduce the merge result. If it does not, routing dropped or
# misplaced something and we must not install the outcome.
#
# Only --apply persists drift, so only --apply can satisfy this. Under --merge
# the drift is deliberately left unpersisted, and keys whose conflict was
# resolved by --prefer-local are deliberately never written, so both are
# excluded rather than checked.
if [ "$MODE" = "apply" ]; then
  RESOLVED_KEYS="$(jq '[.local[] | select(.resolved) | .key]' <<<"$RESULT")"
  if ! jq -e -n \
    --argjson base "$NEW_BASE" --argjson overlay "$NEW_OVERLAY" \
    --argjson merged "$MERGED" --argjson skip "$RESOLVED_KEYS" \
    'def drop: with_entries(select(.key | IN($skip[]) | not));
     ((($base + $overlay) | with_entries(select(.value != null))) | drop) == ($merged | drop)' \
    >/dev/null; then
    die 4 "internal error: base+overlay does not reproduce the merge result; nothing written"
  fi
fi

# The deny list and the hook that enforces it are the whole guardrail. Installing
# a settings file without them fails open, so refuse instead.
jq -e '(.permissions.deny | type) == "array" and (.permissions.deny | length) > 0' \
  <<<"$MERGED" >/dev/null || die 4 "merged settings have an empty permissions.deny; nothing written"
jq -e '[.hooks.PreToolUse[]?.hooks[]?.command // empty] | any(test("deny-check\\.sh"))' \
  <<<"$MERGED" >/dev/null || die 4 "merged settings do not run deny-check.sh; nothing written"

write_overlay=0
if [ "$MODE" = "apply" ]; then
  if [ -e "$OVERLAY" ] || ! jq -e 'length == 0' <<<"$NEW_OVERLAY" >/dev/null; then
    write_overlay=1
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry run: would write"
  echo "  $LIVE"
  echo "  $SNAPSHOT"
  if [ "$MODE" = "apply" ]; then
    echo "  $BASE"
    if [ "$write_overlay" -eq 1 ]; then echo "  $OVERLAY"; fi
  fi
  exit 0
fi

if [ "$MODE" = "apply" ]; then
  jq . <<<"$NEW_BASE" | atomic_write "$BASE"
  if [ "$write_overlay" -eq 1 ]; then
    jq . <<<"$NEW_OVERLAY" | atomic_write "$OVERLAY"
  fi
fi

# The snapshot records the UPSTREAM side we just reconciled against -- the
# composed base+overlay -- not the merge result.
#
# Writing the merge result here loses drift. The merge result carries drift that
# is not in the base or overlay yet; as an ancestor that drift then reads as
# "upstream deleted it" on the next run (l == a, u absent), so the next --merge
# silently reverts it. That is what happens whenever --merge runs twice before
# --apply, e.g. install.sh followed by sync.sh --apply.
#
# With the composed value as the ancestor, unpersisted drift stays visible as a
# local change (u == a) until --apply writes it into the base or the overlay.
if [ "$MODE" = "apply" ]; then
  SNAPSHOT_OUT="$(jq -n --argjson base "$NEW_BASE" --argjson overlay "$NEW_OVERLAY" \
    '($base + $overlay) | with_entries(select(.value != null))')"
else
  SNAPSHOT_OUT="$(jq '.composed' <<<"$RESULT")"
fi

mkdir -p "$CLAUDE_DIR"
# The live path may still be the old symlink into the tracked base. Remove it
# first: writing through it would edit the tracked file directly.
if [ -L "$LIVE" ]; then rm -f "$LIVE"; fi
jq -S . <<<"$MERGED" | atomic_write "$LIVE"
jq -S . <<<"$SNAPSHOT_OUT" | atomic_write "$SNAPSHOT"

echo "wrote $LIVE"
echo "wrote $SNAPSHOT"
if [ "$MODE" = "apply" ]; then
  echo "wrote $BASE"
  if [ "$write_overlay" -eq 1 ]; then echo "wrote $OVERLAY"; fi
fi
exit 0
