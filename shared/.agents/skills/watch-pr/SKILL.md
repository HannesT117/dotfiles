---
name: watch-pr
description: >-
  Use when the user asks to watch a PR for review comments, runs /watch-pr,
  wants hybrid local CI+comment watching (gh run watch + comment heartbeat),
  or asks to auto-handle bot vs human review feedback without cloud webhooks.
---

# Watch PR (hybrid local)

Watch the current branch's open PR **without cloud webhooks**.

- **CI:** event-ish — after a push (or when runs are already in progress), block on
  `gh run watch` and wake when that run finishes. Do **not** poll CI on a timer.
- **Comments / conflicts:** long heartbeat only (default **15m**).

Fix feedback immediately, but **only auto-land bot comments**. Human comments get
a proposed fix + draft reply — never committed or posted.

This is not Claude Desktop auto-fix (no GitHub → session webhooks). Closest
local approximation: watch active runs + heartbeat for new threads.

## Parse invocation

Accept `/watch-pr [interval]` and natural variants (`watch this PR every 10m`).
The interval is the **comment heartbeat**, not a CI poll.

| Input | Comment heartbeat |
| --- | --- |
| (none) | **15m** (default) |
| `10min`, `10m`, `10 minutes` | 10 minutes |
| `30s`, `1h`, `2h` | as given |

Convert unit words to short units. If no open PR for the current branch, stop
and tell the user.

## Hard rules (never violate)

Classify each unresolved review **thread** by the **top-level comment author**
(not reply authors).

### Bot thread

Author is a bot when any of:

- GraphQL `author.__typename == "Bot"` (or REST `user.type == "Bot"`)
- login ends with `[bot]`
- known bots: `cursor`, `copilot-pull-request-reviewer`, `copilot`, `coderabbitai`,
  `github-actions`, `dependabot`, `renovate`, `bugbot`, `sonarcloud`, `claude`

For each bot finding:

1. **Validate first** (especially Bugbot). Only change code when the finding is
   correct and in scope. If you disagree or are unsure: reply explaining why,
   do not "fix" speculative issues, resolve only when the thread is clearly
   addressed or invalid.
2. Fix the code when valid.
3. **Commit** with a scoped message referencing the thread.
4. **Push** to the PR branch.
5. **Reply** on the thread (brief) and **resolve** it via `gh api` / GraphQL.
6. After any push that triggers CI → **arm CI watchers** (see below).

### Human thread

1. You **may** apply the fix in the working tree.
2. **Draft** a proposed GitHub reply for the user (show it in chat; do not post).
3. **MUST NOT** commit.
4. **MUST NOT** push.
5. **MUST NOT** post the reply or resolve the thread.

If unsure whether an author is a bot, treat as **human**.

### Mixed ticks

Process **bots first** (fix → commit → push → reply/resolve), then humans
(local fix + draft reply only). Never include human-driven edits in a bot /
conflict / CI commit: finish and push auto-landed work before touching human
fixes, or keep human fixes unstaged while committing auto-land files only.

## Wake model (dynamic loop)

Follow the **loop** skill **Dynamic Schedule** (not a fixed CI poll).

Primary wakes:

1. **CI watcher** — `gh run watch <run_id>` (or watch latest run for the branch)
   finishes → emit `AGENT_LOOP_WAKE_watch_pr` with `{"reason":"ci",...}`.
2. **Comment heartbeat** — one-shot sleep for the parsed interval → emit
   `AGENT_LOOP_WAKE_watch_pr` with `{"reason":"comments",...}`. Lean on this only
   for new review threads / conflicts; do not use it to busy-poll CI.

On every wake: run a tick scoped by `reason`, then re-arm (CI watchers if runs
are in progress or you just pushed; always re-arm the comment heartbeat unless
stopped).

Do not run a fixed `while true; sleep` CI poll.

## Each tick

1. Resolve PR: `gh pr view --json number,url,headRefName` (current branch).
2. **Comments** (always on `comments` wakes; also after CI if cheap): Fetch
   unresolved review threads only (`isResolved: false`). Read only each comment
   body + author + minimum path/line/URL — not full JSON / resolved threads.
3. Skip threads already handled this session (track by thread id).
4. Apply Hard rules above.
5. **Merge conflicts:** If the branch conflicts with the base, resolve
   intelligently preserving intent on both sides. If intents conflict, abort and
   ask — do not guess. May commit + push (isolation rule applies).
6. **CI** (on `ci` wakes, or when status is already failed on a comments wake):
   Fix failures caused by changes in this PR's scope. Never edit CI
   checks/workflows just to pass, and never make unrelated code changes — report
   instead. If a merge-blocking failure looks unrelated, check whether the branch
   is behind base and merge latest. In-scope CI fixes may commit + push
   (isolation rule). After push → arm CI watchers again.
7. Short summary: what woke you; bots landed; humans pending + draft replies;
   CI/conflict actions; watchers re-armed.

## Arm / re-arm

1. Check terminals for an existing `watch-pr` CI watcher or comment heartbeat;
   do not duplicate.
2. Run **one tick immediately** (`reason: "start"`).
3. **CI watchers** — if the PR has in-progress runs (or you just pushed):

```bash
# Prefer a concrete run id when known
gh run watch <run_id> --exit-status
echo 'AGENT_LOOP_WAKE_watch_pr {"reason":"ci","prompt":"CI run finished. Run one watch-pr tick (reason=ci). Follow the watch-pr skill."}'
```

   Or watch the latest run for the PR head branch:

```bash
gh run watch --exit-status
echo 'AGENT_LOOP_WAKE_watch_pr {"reason":"ci","prompt":"CI run finished. Run one watch-pr tick (reason=ci). Follow the watch-pr skill."}'
```

   `notify_on_output` on `^AGENT_LOOP_WAKE_watch_pr`. Title the shell
   `Loop CI watch: watch-pr`. If multiple workflows are running, watch each run
   id once (or watch the primary failing/required one first). Skip arming when
   nothing is queued/in progress.

4. **Comment heartbeat** (always, unless stopped):

```bash
sleep <heartbeat_seconds>
echo 'AGENT_LOOP_WAKE_watch_pr {"reason":"comments","prompt":"Comment heartbeat. Run one watch-pr tick (reason=comments). Follow the watch-pr skill."}'
```

   One-shot only; re-arm after each comments wake. Title
   `Loop comment heartbeat: watch-pr`.

5. Smoke-check watchers once; track PIDs (CI + heartbeat) for stop.
6. Confirm: hybrid mode (CI via `gh run watch`, comments via heartbeat),
   heartbeat interval, that the first tick ran, which watchers are armed, and
   that only bot comments (plus conflicts/CI) auto-commit/push/resolve.

On later wakes: short delta. If both a CI wake and a heartbeat fire, handle CI
first, then comments in the same turn if needed; still only one heartbeat re-arm.

## gh helpers

```bash
# PR for current branch
gh pr view --json number,url,headRefName,reviewDecision,mergeable,statusCheckRollup

# In-progress / recent runs for this branch
gh run list --branch "$(git branch --show-current)" --limit 10

# Block until a run completes (CI wake)
gh run watch <run_id> --exit-status

# Unresolved review threads — filter resolved client-side; read minimally
gh api graphql -f query='
query($owner:String!,$repo:String!,$number:Int!) {
  repository(owner:$owner,name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id isResolved isOutdated
          comments(first:20) {
            nodes {
              databaseId
              author { __typename login }
              body path url createdAt
            }
          }
        }
      }
    }
  }
}' -f owner=OWNER -f repo=REPO -F number=N
```

Resolve a thread (bot only):

```bash
gh api graphql -f query='mutation($id:ID!) {
  resolveReviewThread(input:{threadId:$id}) { thread { id isResolved } }
}' -f id=THREAD_NODE_ID
```

Reply on a thread (bot only) with `gh api` on the pull comment replies endpoint;
prefer in-thread reply over top-level `gh pr comment`.

## Stop

User says stop / cancel watch / end loop → kill tracked CI watcher + heartbeat
PIDs, do not re-arm, confirm.
