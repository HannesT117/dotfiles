#!/usr/bin/env bash
# Shared gate primitives for the session hooks. Source this; do not execute it.
#
# Single source of truth for the two things the code-review, PR-review and retro
# gates all have to agree on: how per-session sentinel files are named, and how
# many changed lines count as "enough work to review". Changing either here
# changes it for every gate at once.

REVIEW_THRESHOLD=40
RETRO_MIN_ASSISTANT_TURNS=25

# Paths excluded from the changed-lines count: prose, lockfiles, snapshots.
DIFF_IGNORE_FILE_RE='[.](md|mdx|txt|lock|snap)$'
DIFF_IGNORE_PATH_RE='(^|/)(__snapshots__|docs)/'

hook_field() {
  printf '%s' "${HOOK_INPUT:-}" | jq -r "$1" 2>/dev/null
}

read_hook_input() {
  HOOK_INPUT=$(cat)
  HOOK_SESSION_ID=$(hook_field '.session_id // ""')
  HOOK_STOP_ACTIVE=$(hook_field '.stop_hook_active // false')
  HOOK_TRANSCRIPT=$(hook_field '.transcript_path // ""')
}

sentinel_path() {
  printf '%s/claude-%s-%s' "${TMPDIR:-/tmp}" "$1" "${HOOK_SESSION_ID:-nosession}"
}

changed_lines() {
  local base
  base=$(git merge-base HEAD main 2>/dev/null || echo HEAD)
  git diff --numstat "$base" 2>/dev/null |
    awk -v fre="$DIFF_IGNORE_FILE_RE" -v pre="$DIFF_IGNORE_PATH_RE" \
      '$3 !~ fre && $3 !~ pre { a+=$1; d+=$2 } END { print a+d+0 }'
}

assistant_turns() {
  local n
  if [ -z "${HOOK_TRANSCRIPT:-}" ] || [ ! -r "${HOOK_TRANSCRIPT:-}" ]; then
    printf '0'
    return
  fi
  n=$(grep -c '"type":"assistant"' "$HOOK_TRANSCRIPT" 2>/dev/null) || true
  printf '%s' "${n:-0}"
}

# True while the code-review gate still owes this session a review, so other
# gates can yield to it.
review_pending() {
  [ -f "$(sentinel_path impl-review)" ] && return 1
  [ "$(changed_lines)" -ge "$REVIEW_THRESHOLD" ]
}

block_with() {
  jq -nc --arg r "$1" '{decision:"block", reason:$r}'
}
