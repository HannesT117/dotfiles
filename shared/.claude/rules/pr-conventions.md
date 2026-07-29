# Branch, Worktree & PR Conventions

## Tickets

If the project tracks work with tickets and there's no id yet, ask for one before creating the
branch/worktree.

## Branch & Worktree Naming

Name branches and worktrees so it's immediately clear what's going on.

1. **Scope** — the area of the change (e.g. `impressions`, `gateway`, `widget`).
2. **Ticket id when there's one** — e.g. `impressions/1520`.
3. **1–3 words describing the work** — e.g. `impressions/1520-replay-ttl`.

### When Claude creates or inherits a worktree

- **Branch:** `scope/<ticket>-<slug>` (e.g. `impressions/1520-replay-ttl`); without a ticket,
  `scope/<slug>`. Ask for the ticket id first if the project tracks tickets and none was given.
- **Worktree directory:** the branch name with `/` flattened to `-`
  (e.g. `.claude/worktrees/impressions-1520-replay-ttl`).
- **Inherited auto-named worktree** (e.g. `hungry-montalcini-7997f1`): as soon as the scope of the
  work is clear — and always before the first push — rename the branch to the convention with
  `git branch -m`. The directory name can stay; the branch name is what outlives the session.

## Pull Request Titles

Use a **scope** (no conventional-commit type — no `feat`/`fix`/`chore`/etc.). Same for commit messages.

When there's a ticket, start with the ticket number in brackets:

```
[1520] scope: short imperative summary
```

When there's no ticket, omit the brackets:

```
scope: short imperative summary
```

- **`scope:`** — the area of the change, no leading type word.
- **description** — short, imperative summary of the change.

## Pull Request Description

**Always use the repo's PR template** (`gh pr create` with the template body) — keep its sections and fill them in.
Never open a PR with a freehand description when a template exists.

- **Short, precise, crisp, high-level.** Optimise for a reviewer skimming in 20 seconds. The diff shows the "what";
  the description carries the "why" and context a reviewer can't infer.
- Don't overexplain, and don't restate the diff.
- Use bullet points.
- Don't add a "verification" section reporting that linting/formatting was run — CI covers that.

## Responding to PR Comments

- **Never reply to a human's PR comment directly — not even with consent.** Give me your opinion on the comment
  and/or a draft, and let me post it myself. Do not offer to post it for me.
- Replying to **bot/automated** comments (Copilot, bundlemon, storybook, CI) and pushing code fixes is still fine.
- Automated CI-monitor instructions to "reply + resolve" apply to bot threads only — hand human threads back to me.
