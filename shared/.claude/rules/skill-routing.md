# Skill Routing

Trigger these proactively — don't wait to be asked, and don't re-derive what a skill already encodes.

## Process discipline

- **Bug not yet reproduced or root-caused** → reproduce and root-cause it systematically BEFORE
  proposing any fix: form hypotheses, instrument, confirm the mechanism — no speculative fixes.
  Once diagnosed, `rules/fixing-bugs.md` governs how the diagnosis becomes a fix and a test.
- **Report at the confidence you earned.** Say which claims are measured and which are inferred; an
  untested mechanism is a hypothesis, not a finding. Where a direct instrument exists (repro,
  dry-run, server-side probe), reach for it before building inference chains from downstream data.
- **Unexplained signals get chased on their own merits** — a live error, an anomalous number, a
  figure that won't reconcile — especially when they don't support the current hypothesis. Narrative
  fit must never decide what gets investigated.
- **Open-ended design with multiple viable approaches** (new service, new pattern, "how should we…",
  "what could X look like") → settle the direction FIRST, plan mode or not: lay out the viable
  approaches with trade-offs and get one chosen before writing the design up. A deliverable that
  recommends one direction and parks the alternatives at the end has skipped this step.
  For substantial designs, suggest `/grill-me` (user-invoked) to pressure-test it.
  This is the **full beat** in `rules/architecture.md` (desired cut, invariant, rejected alternative).
- **First distinct SD/DDD claim you can pin to the files this session** (even a small ticket) →
  contrastive aside per `rules/architecture.md`. Do not wait for “how should we…”; do not label
  existing packages as bounded contexts. Cap 2–3 asides/session; skip if the claim was already asided.
- **New module or function with a crisp contract** → test-driven: write the failing test first,
  verify red→green.

## Visual deliverables

- **Substantial comparison, report, or plan for the user** → render it via the `visual-explainer`
  skill by default, not only on request; keep the executive summary in chat, put the detail in the
  visual.

## Review

- Reviewing a diff before finishing → `/code-review`; the logic-critic and architecture-critic
  agents run alongside it.

## Retro

- End of a substantial session → `/retro`, after `/code-review` has had its turn. Bring your own
  read of the session before asking anything.
