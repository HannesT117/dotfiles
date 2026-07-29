# Code Comments

**Ask for approval before adding ANY code comment. Do not add comments unprompted.** This is the default — even
one line, even when it feels helpful. Write the code, then ask if a comment is wanted.

When a comment is approved:

- **Prefer high-level JSDoc** on functions over inline commentary.
- **Don't overexplain.** No comments that restate what the code already says, no section dividers
  (`// ---- Helpers ----`), no narrating obvious steps. A comment earns its place only by explaining *why*, or
  non-obvious info/usage the code can't convey.
- **Don't assume context from the caller side.** A function's comment describes the function on its own terms —
  don't reference how or where it happens to be called, or invariants the caller guarantees. The next caller breaks
  that assumption.
- Never assert behaviour the code doesn't control (e.g. an external split %, a Statsig rollout).
- Keep them short.

This applies to test files too: **no explanatory comments in tests** — names and bodies should be self-explanatory.
