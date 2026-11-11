---
name: agent-doctor
description: Audit the current repository for agent-readiness - doc gaps, context routing, onboarding quality for AI agents - with concrete recommendations. Use when asked to audit agent docs or improve how agents navigate the repo; PT - "audita o repo para agentes", "lacunas de docs", "prepara o repo para IA". Never for runtime bugs or code fixes.
---

# Agent Doctor

Audit the current repository for agent-readiness and recommend concrete improvements.

## Workflow

1. Inspect the repo shape.
   - Find root agent docs: `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules`.
   - Find context docs: `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md`, `CONTEXT-MAP.md`, nested glossaries/context docs and `AGENTS.md`.
   - Find agent support docs: `docs/agents/**`, `docs/adr/**`, architecture docs, onboarding docs.
   - Determine whether the repo has one global domain context or multiple contexts, such as a monorepo with separate frontend/backend, app/package, or bounded-domain areas.
   - Find setup paths: bootstrap scripts, package scripts, setup docs, devcontainer files.
   - Find issue tracker hints: Linear, GitHub Issues, Jira, ClickUp, labels, PR conventions.

2. Read relevant docs.
   - Start with the root agent doc.
   - If `CONTEXT-MAP.md` exists, read it before individual context files.
   - Read only context files relevant to the repo structure or requested area.
   - Prefer nearby docs over broad repository-wide reading.

3. Diagnose gaps.
   - Separate missing information from unclear or duplicated information.
   - Treat stale or conflicting instructions as higher risk than missing optional docs.
   - Check whether agents can quickly answer: "Which domain context and ADRs should I read before editing this area?"

4. Recommend changes.
   Group findings by impact:
   - `High`: an agent is likely to make wrong code changes without this.
   - `Medium`: an agent will waste time or need repeated user guidance.
   - `Low`: cleanup, consistency, or maintainability.
   - When domain routing is missing or unclear, recommend a `domain.md`-style document, preferably at `docs/agents/domain.md` unless the repo already has an equivalent location.
   - The domain doc should tell agents whether to use one global `CONTEXT.md` or multiple local context files, where those files live, and which `docs/adr/**` records are relevant to each domain.

5. Offer implementation.
   - Do not edit files unless the user asks.
   - If asked to implement, keep changes small and repo-specific.
   - Prefer improving existing docs over adding new files.
   - Add new files only when they create a clearer routing structure.

## Output Format

Return:

1. Current state
2. Gaps by priority
3. Recommended file changes
4. Domain context routing recommendation
5. Suggested setup or bootstrap changes
6. Open questions, only where repo conventions are ambiguous

Keep recommendations specific to the repository. Avoid generic agent advice.

## Handoffs

- Implementing the recommended docs? Route via `coding-skill-router` (`ai-context-docs` package: `zoom-out` + `grill-with-docs`).
