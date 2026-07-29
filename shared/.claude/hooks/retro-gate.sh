#!/usr/bin/env bash
# Stop-hook gate: asks for a session retro once per session, and only for
# sessions substantial enough to have something worth discussing.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/session-gates.sh"
. "$(dirname "${BASH_SOURCE[0]}")/lib/usage.sh"

read_hook_input

[ "$HOOK_STOP_ACTIVE" = "true" ] && exit 0
[ "$(usage_state)" = "credits" ] && exit 0
[ -n "$HOOK_SESSION_ID" ] || exit 0

sentinel=$(sentinel_path retro)
[ -f "$sentinel" ] && exit 0
[ "$(assistant_turns)" -ge "$RETRO_MIN_ASSISTANT_TURNS" ] || exit 0

review_pending && exit 0

touch "$sentinel"

block_with "Before wrapping up, run the retro skill (~/.claude/skills/retro/SKILL.md) with the user: a short retro on this session covering what went well, where you struggled, and what to change. Form your own read of the session first, then ask. Follow the skill's capture rules for anything worth keeping. This fires once per session -- if the user is still mid-task, say so in one line and continue; it will not fire again."
