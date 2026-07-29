---
name: retro
description: Run a short retro on the current session - what went well, where Claude struggled, what to change - and turn the outcome into rules or memory. Use when the user asks for a retro, runs /retro, or the retro Stop hook fires.
---

# Session Retro

A retro is only worth the interruption if you bring your own read of the session. Do not open
with "how did that go?".

## 1. Form your read first (no questions yet)

From the session in context, write down for yourself:

- **What worked** - a specific decision or step that paid off, not "we shipped it".
- **Where you struggled** - where you went in circles, guessed, needed correcting, re-read the same
  files, or reached for the wrong tool. Be concrete and name the turn.
- **What the user had to correct** - every time they redirected you is a signal. What did they have to
  say that a rule or memory could have said for them?
- **One candidate change** - the smallest change to rules, memory, or skills that would have avoided
  the biggest problem above.

If the session had no real friction, say so plainly. A retro that invents problems is noise.

## 2. Present it, then ask

Give your read in a handful of bullets - neutral register, no self-flagellation, no padding. Then ask
the user, in **at most two rounds**:

- Whether your read matches theirs, and what you missed. Use `AskUserQuestion` when you have concrete
  candidate answers to offer; plain text when it is genuinely open.
- For each thing worth changing: is this a **one-off** or a **recurring pattern**?

Stop asking once you have enough to act. Four questions total is the ceiling.

## 3. Classify before capturing

| Signal | Where it goes |
|---|---|
| Recurring pattern in how you should work, across projects | proposed edit to `~/.claude/rules/*.md` |
| Guidance specific to this project or this codebase | `feedback` memory in the project memory dir |
| Fact about the user, their role, or their preferences | `user` memory |
| One-off, or already covered by an existing rule | capture nothing - say so |

Check the existing rules and memories before writing. If a rule already covers it and you did not
follow it, the finding is "I did not apply an existing rule", and the fix may be making that rule
harder to miss rather than adding a new one.

## 4. Capture

**Rules edits require approval.** Show the exact diff you propose to `~/.claude/rules/<file>.md` and
wait. Keep additions short and in the register of the surrounding file - these files are read every
session, so every line added costs context forever. Prefer sharpening an existing line over appending
a new one.

**Memory** follows the standard format: one fact per file, `feedback`/`user`/`project`/`reference`
type, and for `feedback` a `**Why:**` and `**How to apply:**` line. Add the one-line pointer to
`MEMORY.md`. Link related memories with `[[name]]`.

## 5. Close

One short paragraph: what changed, what you deliberately did not capture, and anything still open. Do
not thank the user for the retro.
