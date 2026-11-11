---
name: improve-codebase-architecture
description: Find deepening opportunities - refactors that turn shallow modules into deep ones - informed by CONTEXT.md and ADRs; produces a visual report then a grilling loop. Use for architecture-wide or coupling-heavy work, or to make a codebase more testable/AI-navigable; PT - "melhora a arquitetura", "reduz acoplamento", "consolida esses modulos".
argument-hint: "[area, module or folder]"
---

# Improve Codebase Architecture

Scope: `$ARGUMENTS` (whole repo if empty).

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

## Glossary

Use these terms exactly in every suggestion. Consistent language is the point — don't drift into "component," "service," "API," or "boundary."

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place.
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

Key principles:

- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

This skill is _informed_ by the project's domain model. The domain language gives names to good seams; ADRs record decisions the skill should not re-litigate.

## Process

### 1. Explore

Choose scope before scanning. Honor the user's named module, subsystem or pain
point. Otherwise inspect a useful stretch of `git log --oneline` and prioritize
areas that repeatedly change; widen the search when there is no clear hotspot.
Deepening pays off where future changes are likely, not at every theoretical seam.

Read `GLOSSARY.md` / `GLOSSARY-MAP.md` and relevant ADRs first; use an existing
`CONTEXT.md` glossary when that is the project's convention.

Explore directly, or use a fresh read-only investigator when delegation is available and authorized. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as a visual report

Present a concise report with before/after diagrams when they clarify the
structure. Markdown and Mermaid are sufficient. If an interactive HTML report
would materially help, write a self-contained file to the OS temporary directory
and report its path. Do not require an Artifact tool or another skill. Open the
report only when the user requested that or the host permits it.

Each candidate gets a **before/after visualisation**. Be visual.

For each candidate:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side, illustrating the shallowness and the deepening
- **Recommendation strength** — one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the project glossary for domain vocabulary, and the glossary above for architecture.**

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly (e.g. a warning callout: _"contradicts ADR-0007 — but worth reopening because…"_).

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept missing from the project glossary?** Add the term to the existing glossary, or create `GLOSSARY.md` lazily.
- **Sharpening a fuzzy term during the conversation?** Update that glossary right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR only when the reason would prevent a future review from re-suggesting it; skip ephemeral reasons such as "not now" and self-evident ones. Frame it as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_

## When not to use

- Ordinary feature work or a localized refactor: the refactor package (`zoom-out` + `tdd`) covers it.
- The user wants code, not a structural review: skip.

## Handoffs

- Implementing a chosen candidate? Route via `coding-skill-router` (`architecture` package: `zoom-out` + this skill; `tdd` where behavior can be protected).
- `diagnose` hands off here when a bug's root cause is architectural — after the fix, not before.
