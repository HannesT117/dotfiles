#!/usr/bin/env bash
# PostToolUse(Bash) gate: when a Bash call actually opened a PR, require the
# adversarial critics and a code review over the PR diff before humans see it.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/session-gates.sh"

read_hook_input

cmd=$(hook_field '.tool_input.command // ""')

opens_pr=false
case "$cmd" in
  *"gh pr create"*) opens_pr=true ;;
esac
if [ "$opens_pr" = false ] &&
  printf '%s' "$cmd" | grep -Eq '/pulls' &&
  printf '%s' "$cmd" | grep -Eq '(-X|--request)[[:space:]]+POST|--method[[:space:]]+POST|--field|--input|(^|[[:space:]])-[fF]([[:space:]]|=)'; then
  opens_pr=true
fi
[ "$opens_pr" = true ] || exit 0

resp=$(hook_field '.tool_response | [.. | strings] | join("\n")')
printf '%s' "$resp" | grep -Eq 'github\.com/[^ ]+/pull/' || exit 0

# A reviewed PR settles this session's code-review obligation.
touch "$(sentinel_path impl-review)"

block_with "A PR was just opened. Spawn the logic-critic and architecture-critic agents IN PARALLEL (two Agent tool calls in one message) over the PR diff (git diff against the merge-base with main, or gh pr diff), including the original task/requirements verbatim in each agent's prompt. Also run the /code-review skill. Address their findings and push fixes before handing the PR to human reviewers."
