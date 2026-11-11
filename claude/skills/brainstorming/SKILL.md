---
name: brainstorming
description: "Turn a rough idea into an approved design before coding: one question at a time, 2-3 approaches with a recommendation, design doc, approval gate. Use when the solution shape is open and there is no settled user-authored specification - even if the verb is directive ('implementa', 'cria'). PT: 'tenho uma ideia', 'pensa comigo', 'qual abordagem?'. Not for clear bug fixes or detailed user-authored specs."
---

# Brainstorming Ideas Into Designs

Turn an open idea into a design that captures what the user wants and why.
The `coding-skill-router` controls selection: settled user-authored specs, clear
bug fixes and mechanical edits do not need a new design conversation. A plan
drafted by the assistant does not count as a user-authored spec.

## Look before asking

Read the request, referenced materials, relevant implementation, project docs
and recent changes. Explain what exists today and what the change touches.
Never ask what the project already answers or reopen decisions the user settled.
If everything material is specified and there is one sensible implementation,
return to routing and execute within the existing authorization.

For an open idea, ask only questions whose answers change what gets built.
Start with the biggest unresolved goal or outcome, in the user's own vocabulary.
Use an open question when their intent is unclear; use concrete options with a
recommendation when a known trade-off needs a decision. Ask one at a time.
Explain what the answer changes. Do not ask the user to decide routine process
steps, document locations or facts you can inspect.

Distinguish the user's decisions from your proposed defaults. When the user
cares about outcomes and leaves implementation choices to you, follow existing
platforms and conventions, state significant choices and proceed with those.
Include goals, non-goals, anti-goals (what would make the result unacceptable),
constraints and success criteria when they matter to the design.

## Approaches and scope

Before writing the design, explain the viable approaches and their trade-offs.
Usually two or three suffice; do not manufacture alternatives when only one
fits. Recommend one with a reason. Let the user choose unresolved product
trade-offs; use your judgment for implementation choices they delegated.

If the request contains independent projects, agree an order and design the
first one rather than merging them into one oversized specification.
Keep improvements tied to the task; avoid unrelated refactors.

When seeing is clearer than reading, show a small text sketch. Offer the visual
companion only when a mockup, arrangement or side-by-side design will help the
user decide. After they accept, read [visual-companion.md](visual-companion.md)
before starting it. A UI topic does not make every question visual.

An explicitly requested or accepted spike may be built to answer a concrete
uncertainty. Label it throwaway, keep validation proportional, and report what
it taught you. A spike does not authorize retaining it as the finished product.

## Write the design

Scale the document to the work: a few clear paragraphs for a small design;
a fuller document for a project. Cover intent, constraints, approaches and their
trade-offs, the chosen behavior, important data flows/interfaces, error handling,
validation, and choices left to implementation. Do not add sections with no use.
Show sketches for visible behavior when they communicate better than prose.

Use `docs/specs/YYYY-MM-DD-<topic>-design.md` unless the user or repository specifies
another location. Do not commit it unless commits are authorized.

Review the written design for contradictions, missing requirements and guesses
that could materially change the implementation. For a substantial project,
use [spec-document-reviewer-prompt.md](spec-document-reviewer-prompt.md) as the
builder-readiness check; delegate only when available and authorized, otherwise
perform it yourself. Resolve questions already answered by the project, make
minor implementation calls explicitly, and bring only consequential unresolved
user decisions back in one concise message. Avoid repeated review loops over
wording or decisions a competent implementer can make.

## Approval and handoff

For a design conversation, obtain approval of the written design before product
implementation, scaffolding or dependency installation. Read-only exploration
and an authorized throwaway spike remain allowed. Approval of an idea does not
approve an unseen design. When the complete short design was already shown and
approved in conversation, record that approval without asking for it again.

If the user explicitly opts out of design discussion, end this workflow, state
material assumptions and return to normal execution. An imperative verb alone
is not an opt-out. Existing authorization still controls actual side effects.

After approval, return to `coding-skill-router` with the settled design. Select
execution skills and validation there; never route back into brainstorming for
the same settled design. The upstream `superpowers:writing-plans` dependency is
replaced by this environment's router and planning workflow.
