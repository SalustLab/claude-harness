---
name: zoom-out
description: Map modules, callers, data flow and conventions before editing unfamiliar or multi-layer code, using the project's domain vocabulary. Use before multi-layer changes, migrations, cross-layer features or refactors; runs inside plan mode as the exploration phase. PT - "implementa", "refatora", "nao conheco essa parte". Not for localized changes in code you already know.
---

# Zoom Out

I don't know this area of code well. Go up a layer of abstraction. Give me a map of all the relevant modules and callers, using the project's domain glossary vocabulary.

Cover, at minimum:

- the modules involved and what each one owns
- who calls what (entry points → services → persistence/UI)
- the data flow for the behavior being changed
- existing conventions and patterns in the area (naming, validation, error handling)
- docs that apply: `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md`, ADRs, README, `AGENTS.md`

Keep the map at the level needed for the task — a paragraph for a narrow change, a structured map for a cross-layer change.

## Handoffs

- After mapping, return to `coding-skill-router` output: the map is the evidence line for this skill.
- In plan mode: the map becomes the plan file's Context section and is this skill's evidence — "the plan is already drafted" is never a reason to skip; the map precedes the draft.
- Feeds `tdd` (where the test seams are), `brainstorming` (what exists before designing), and `improve-codebase-architecture` (where the shallow modules are).

## Execution context for cross-repository work

For multi-layer changes, migrations or changes spanning repositories, extend the map only with
facts relevant to execution: each repository's responsibility and local path,
current/base branch, target test environment, data stores, dependencies, and
applicable requirements, comments, attachments and mockups. Cite the source of
important facts; distinguish confirmed facts from assumptions and missing access.
Reference credential locations without copying secret values.

When branch or environment selection matters, inspect publishing configuration
and relevant successful releases rather than inferring the deployment flow from
branch names. Mapping does not authorize switching branches, deploying or writing
to databases. Preserve local changes and apply the project's actual safety rules.
