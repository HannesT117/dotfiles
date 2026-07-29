# Fixing Bugs & Writing Their Tests

Diagnosis is usually the easy part. Most of the value (and most of my past misses) is in **how the
diagnosis becomes a fix and a test**. Apply these whenever fixing a bug, not just incidents.

## Match the fix to the kind of bug

- **Localized bug** (one wrong branch, off-by-one, bad mapping) → a surgical, minimal fix is correct.
- **Drift / duplication bug** — the root cause is "X and Y disagreed" (two code paths that must stay in
  sync diverged) → do **not** just re-align the one condition that diverged today. Make X and Y share a
  **single source of truth** so no condition can drift again. The next field will drift tomorrow.
- The signal is in the root cause itself: "A and B counted/handled it differently" almost always means
  "give A and B one shared definition," not "make A match B this once." Investing in structure here is
  right even though it's more code — don't let a "keep it minimal" instinct under-fix a structural bug.
- **Never ship a safety claim you haven't checked.** If a fix rests on "this is idempotent", "a retry is
  safe", or "nothing else writes here", enumerate every write and caller in scope and verify each one —
  then put the evidence in the PR, not as a confident comment in the code. An unverified justification in
  a JSDoc is worse than none: reviewers trust it instead of re-deriving it.

## Reconcile *all* conditions, not just the one in the stack trace

When two code paths must agree, **enumerate every condition on both sides and diff them all**. The
condition named in the error/stack trace is often not the only one that has diverged — fixing just that
one can leave a second latent divergence that still bites. List both predicates side by side and check
parity for each clause.

## Test the contract the bug crosses — both sides real

- A bug in the *relationship* between two functions needs a test that exercises **both functions for
  real**, asserting the invariant across the input space — not a unit test on each side in isolation.
- A green unit test on one side proves nothing about the contract. Beware false confidence: "my tests
  pass" is not "I'm done" when the bug lives between components.
- **Name the invariant explicitly** ("a bundle the pre-filter keeps must always be adoptable without
  throwing"). Once named, the fix and the test both fall out of it, and the next person inherits the spec.
- A good regression test fails on the incomplete fix and passes on the complete one — verify red→green.

## For incidents, reconstruct the trigger, not just the mechanism

Explain *why it fired when it did*: what deployed, what data/config shifted, what margin shrank. The
mechanism ("these two disagreed") plus the trigger ("a deploy made them disagree, and an overnight
squeeze tipped it past the threshold") validates the diagnosis and surfaces adjacent risk a
mechanism-only explanation hides.
