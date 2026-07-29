# Architectural Preferences

Keep these in mind in **every** coding session — writing, refactoring, and reviewing — not only when running an
adversarial architecture agent. The architecture agent applies this same list.

## General design (from Ousterhout, *A Philosophy of Software Design*, + DDD)

- **Composition & pluggability over configuration.** Prefer composing small pieces to threading ever more flags/props.
- **Children-over-props** for React composition — pass `children`/slots rather than proliferating boolean props.
- **Deep modules, information hiding.** A module should hide complexity behind a simple interface; avoid shallow
  wrappers that add surface without hiding anything.
- **Cohesion & reusability.** Group what changes together; extract genuinely reusable pieces (see the monorepo's
  "extract into a package vs keep in a service" rule when it applies).
- **Domain-Driven Design** — model the domain, keep boundaries meaningful.
- **Single source of truth for shared constants and predicates.** When two call sites must agree on a
  value or a condition, define it once and have both read it — never copy the value and rely on
  keeping them in sync. Holds for config, scripts and hooks, not just application code.

## In-session teaching (systems design / DDD)

Working code is usually a **counterexample**, not a map of good boundaries. Never baptise a
package, worker, or folder as a bounded context. Vocabulary (aggregate, consistency boundary,
information hiding, anti-corruption layer) names the **desired** cut — the bullets above — not the
tree.

Trigger: a **concrete design claim** you can pin to the files in play (missing/wrong cut, leaked
invariant, shallow module, coupling this change would add). Not a dedicated lesson, not “we entered
a module.” Skip format, typos, and tests-going-green with no domain shape.

- **Full beat** when a design decision is on the table (new service, trade-off, “how should we…”):
  desired cut, the invariant it would protect, the rejected alternative. One beat per reply.
- **Aside** on small tickets that still have a claim: 2–4 sentences, contrastive, tied to the files,
  one transferable claim — plus whether this change deepens the leak or starts to hide it. Once per
  distinct claim, max 2–3 per session. Same claim already asided → skip unless a new fork (then
  upgrade to a full beat). Do not mint a context map to justify extra asides. No pattern catalog; no
  CAP/event-sourcing lecture unless the diff forces it.
- If any beat or aside fired: close the session with one transferable sentence about the better cut,
  not a description of the status quo. This is not `/retro` (retro is agent friction → rules).

## Functions & purity

- **Prefer side-effect-free (pure) functions.** Push side effects to the edges; keep the core computational.

## React

- **Use modern React tools/APIs** (current hooks, `use`, actions, Suspense, etc.) — don't reach for dated patterns.
- **Don't reach for `useEffect`/`useMemo`/`useCallback` by default.** Before adding one, confirm it's actually
  necessary — derive during render where possible, and remember most effects are avoidable.

## Reuse

- **Prefer built-in functionality over custom implementations** — language/stdlib/framework/library built-ins before
  hand-rolling. Custom only when a built-in genuinely doesn't fit.
