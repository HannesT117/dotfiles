#!/usr/bin/env bash
# Stop-hook gate: asks for a code review once per session, when the working
# changes are substantial enough to be worth reviewing.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/session-gates.sh"
. "$(dirname "${BASH_SOURCE[0]}")/lib/usage.sh"

read_hook_input

[ "$HOOK_STOP_ACTIVE" = "true" ] && exit 0
[ "$(usage_state)" = "credits" ] && exit 0

sentinel=$(sentinel_path impl-review)
[ -f "$sentinel" ] && exit 0
[ "$(changed_lines)" -ge "$REVIEW_THRESHOLD" ] || exit 0

touch "$sentinel"

block_with "Before wrapping up, run the /code-review skill over the working changes (git diff against the merge-base with main), then address its findings. This fires once per session -- if you are still mid-implementation, note it and continue; it will not fire again."
