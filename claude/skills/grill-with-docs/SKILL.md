---
name: grill-with-docs
description: Stress-test a plan against the domain model (GLOSSARY.md or existing CONTEXT.md, ADRs) with questions ordered by decision dependencies, sharpen terminology and update docs inline as decisions crystallise. Use for domain/business decisions the code cannot answer and when writing glossaries/ADRs; PT - "decisao de dominio", "atualiza a documentacao", "valida contra os ADRs". Not for implementation with settled requirements.
---

# Grill With Docs

<what-to-do>

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Map the decisions and their prerequisites. Ask the highest-impact unresolved
question first, with a recommended answer. Independent decisions whose prerequisites
are already settled may be grouped in a short numbered round; dependent questions
wait for the earlier answer. Default to one question at a time when the topic is
complex. Recompute what is still open after each answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

</what-to-do>

<supporting-info>

## Domain awareness

Use `GLOSSARY.md` and `GLOSSARY-MAP.md` in projects that have adopted them. If the
project already keeps its glossary in `CONTEXT.md` / `CONTEXT-MAP.md`, follow that
convention instead. Do not rename or migrate existing context files automatically.
For a new domain glossary, use `GLOSSARY.md`; general agent/project instructions
remain in the project's existing context files.

During codebase exploration, also look for existing documentation:

### File structure

Most repos have a single context:

```
/
├── GLOSSARY.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `GLOSSARY-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── GLOSSARY-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── GLOSSARY.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── GLOSSARY.md
│       └── docs/adr/
```

Create files lazily — only when you have something to write. If no `GLOSSARY.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `GLOSSARY.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update GLOSSARY.md inline

When a term is resolved, update `GLOSSARY.md` right there. Don't batch these up — capture them as they happen.

`GLOSSARY.md` should be totally devoid of implementation details. Do not treat `GLOSSARY.md` as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR.

</supporting-info>

## Handoffs

- No docs exist? Still use this skill — create `GLOSSARY.md`/ADRs lazily only when a decision is worth recording; otherwise just interview.
- Once decisions are resolved and docs updated, return to `coding-skill-router` for execution skills.

## Requirements before questions

For a supplied specification, read the relevant description, acceptance criteria,
comments, attachments and linked documents available through authorized access.
Separate settled requirements from ambiguities and contradictions; cite their
sources. Ask only about decisions the available evidence cannot resolve, with a
recommended answer and its consequence. Settled requirements need no interview
or repeated approval: report the documentation check and continue execution.

Keep an existing document's purpose and structure. The glossary-only convention
above applies to a new `GLOSSARY.md`; it does not authorize replacing an existing
project context or moving its implementation guidance. Record only decisions
within the requested documentation scope. Define project-specific domain terms,
not general programming concepts. Use a short definition of what the concept is;
list rejected synonyms when they would otherwise cause confusion.
